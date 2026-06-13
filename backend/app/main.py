"""
Main application module for the gaming club API.

This module sets up the FastAPI application with all necessary middleware,
routers, exception handlers, and background jobs. It configures CORS,
rate limiting, logging, and serves static files for uploads.
"""

import logging
import logging.config
from contextlib import asynccontextmanager
from pathlib import Path

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import get_settings
from app.database import engine
# Import all models first so SQLAlchemy mapper can resolve all relationships
import app.models.user  # noqa: F401
import app.models.club  # noqa: F401
import app.models.booking  # noqa: F401
import app.models.refresh_token  # noqa: F401
import app.models.wallet  # noqa: F401
import app.models.transaction  # noqa: F401
import app.models.payment  # noqa: F401
import app.models.admin  # noqa: F401
from app.exceptions import (
    AppException,
    app_exception_handler,
    generic_exception_handler,
    http_exception_handler,
    validation_exception_handler,
)
from app.jobs.booking_status_job import update_booking_statuses
from app.middleware.logging_middleware import LoggingMiddleware
from app.routers import auth, bookings, clubs, wallet, transactions, payments, admin
from app.routers import uploads as uploads_router
from app.seed import run_seed

settings = get_settings()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)

limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])
scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for the FastAPI application.

    This function handles startup and shutdown events for the application.
    On startup, it runs database seeding and starts the background scheduler
    for periodic tasks. On shutdown, it stops the scheduler and disposes
    of the database engine.

    Args:
        app: The FastAPI application instance.

    Yields:
        None
    """
    try:
        await run_seed()
    except Exception as exc:
        logging.getLogger("app").warning("Seed failed (DB may not be ready): %s", exc)

    scheduler.add_job(
        update_booking_statuses,
        trigger="interval",
        minutes=2,
        id="booking_status_job",
        replace_existing=True,
    )
    scheduler.start()

    yield

    scheduler.shutdown(wait=False)
    await engine.dispose()


def create_app() -> FastAPI:
    """
    Create and configure the FastAPI application.

    This function sets up the FastAPI app with all necessary components:
    - Rate limiting
    - CORS middleware
    - Custom logging middleware
    - Exception handlers
    - API routers for different endpoints
    - Static file serving for uploads
    - Health check and root endpoints

    Returns:
        FastAPI: The configured FastAPI application instance.
    """
    app = FastAPI(
        title="1Game Booking API",
        version="2.0.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
    )

    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    cors_kwargs = dict(
        allow_origins=settings.origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    if not settings.is_production:
        cors_kwargs["allow_origin_regex"] = r"http://localhost(:\d+)?"
    app.add_middleware(CORSMiddleware, **cors_kwargs)

    app.add_middleware(LoggingMiddleware)

    app.add_exception_handler(AppException, app_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(Exception, generic_exception_handler)

    # Phase 1 routers
    app.include_router(auth.router)
    app.include_router(clubs.router)
    app.include_router(bookings.router)
    # Phase 2 routers
    app.include_router(wallet.router)
    app.include_router(transactions.router)
    app.include_router(payments.router)
    app.include_router(admin.router)
    app.include_router(uploads_router.router)

    # Serve uploaded images
    _uploads = Path(__file__).parent.parent / "uploads"
    _uploads.mkdir(parents=True, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=str(_uploads)), name="uploads")

    @app.get("/", tags=["system"])
    async def root():
        """
        Root endpoint providing API information.

        Returns basic information about the API including version and links
        to documentation and health check.

        Returns:
            dict: API information with links.
        """
        return {
            "message": "1Game Booking API v2",
            "health": "/health",
            "docs": "/docs",
        }

    @app.get("/health", tags=["health"])
    async def health_check():
        """
        Health check endpoint.

        Returns the current status and version of the API to indicate
        that the service is running properly.

        Returns:
            dict: Health status information.
        """
        return {"status": "ok", "version": "2.0.0"}

    return app


app = create_app()
