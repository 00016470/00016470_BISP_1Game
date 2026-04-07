import asyncio
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.database import Base, get_db
from app.main import app

TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"

test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestingSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def setup_db():
    try:
        async with test_engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        yield
        async with test_engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
    except Exception:
        yield


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with TestingSessionLocal() as session:
        yield session


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def auth_token(client: AsyncClient) -> str:
    """Register a fresh test user and return their access token."""
    import random
    suffix = random.randint(10000, 99999)
    resp = await client.post("/api/auth/register", json={
        "username": f"testuser{suffix}",
        "email": f"testuser{suffix}@test.com",
        "password": "Test1234!",
        "phone": "+998901111111",
    })
    assert resp.status_code == 201
    return resp.json()["access_token"]


@pytest_asyncio.fixture
async def admin_token(client: AsyncClient, db_session: AsyncSession) -> str:
    """Register a user and promote them to admin, return their access token."""
    import random
    from sqlalchemy import select
    from app.models.admin import AdminUser, AdminRole
    from app.models.user import User

    suffix = random.randint(10000, 99999)
    resp = await client.post("/api/auth/register", json={
        "username": f"adminuser{suffix}",
        "email": f"adminuser{suffix}@test.com",
        "password": "Admin1234!",
    })
    assert resp.status_code == 201
    user_data = resp.json()["user"]

    # Promote to admin
    admin_rec = AdminUser(
        user_id=user_data["id"],
        role=AdminRole.SUPER_ADMIN,
        club_id=None,
    )
    db_session.add(admin_rec)
    await db_session.commit()

    # Re-login to get token with role
    login_resp = await client.post("/api/auth/login", json={
        "email": f"adminuser{suffix}@test.com",
        "password": "Admin1234!",
    })
    assert login_resp.status_code == 200
    return login_resp.json()["access_token"]


@pytest_asyncio.fixture
async def club_id(client: AsyncClient, db_session: AsyncSession) -> int:
    """Return the ID of the first seeded club, or create one."""
    from sqlalchemy import select
    from app.models.club import Club

    result = await db_session.execute(select(Club).limit(1))
    club = result.scalar_one_or_none()
    if club:
        return club.id

    new_club = Club(
        name="Test Club",
        location="Test Location",
        total_computers=10,
        rating=4.0,
        price_per_hour=10000,
        opening_hour=9,
        closing_hour=23,
    )
    db_session.add(new_club)
    await db_session.commit()
    return new_club.id
