import logging
import logging.config
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import get_settings
from app.database import engine
# Import all models first so SQLAlchemy mapper can resolve all relationships
import app.models.user  # noqa: F401
import app.models.booking  # noqa: F401
import app.models.club  # noqa: F401
import app.models.refresh_token  # noqa: F401
from app.exceptions import (
    AppException,
    app_exception_handler,
    generic_exception_handler,
    http_exception_handler,
    validation_exception_handler,
)
from app.jobs.booking_status_job import update_booking_statuses
from app.middleware.logging_middleware import LoggingMiddleware
from app.routers import auth, bookings, clubs
from app.seed import run_seed

settings = get_settings()

# ── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)

# ── Rate limiter ──────────────────────────────────────────────────────────────
limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])

# ── Scheduler ────────────────────────────────────────────────────────────────
scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Run seed on startup
    try:
        await run_seed()
    except Exception as exc:
        logging.getLogger("app").warning("Seed failed (DB may not be ready): %s", exc)

    # Start background scheduler
    scheduler.add_job(
        update_booking_statuses,
        trigger="interval",
        minutes=10,
        id="booking_status_job",
        replace_existing=True,
    )
    scheduler.start()

    yield

    scheduler.shutdown(wait=False)
    await engine.dispose()


# ── App factory ───────────────────────────────────────────────────────────────
def create_app() -> FastAPI:
    app = FastAPI(
        title="Gaming Club Booking API",
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
    )

    # Rate limiting
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.origins,
        allow_origin_regex=r"http://localhost(:\d+)?",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Request logging
    app.add_middleware(LoggingMiddleware)

    # Exception handlers
    app.add_exception_handler(AppException, app_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, generic_exception_handler)

    # Routers
    app.include_router(auth.router)
    app.include_router(clubs.router)
    app.include_router(bookings.router)

    @app.get("/", tags=["system"])
    async def root():
        return {
            "message": "Gaming Club Booking API",
            "health": "/health",
            "docs": "/docs",
            "redoc": "/redoc",
        }

    @app.get("/health", tags=["health"])
    async def health_check():
        return {"status": "ok"}

    return app


app = create_app()
