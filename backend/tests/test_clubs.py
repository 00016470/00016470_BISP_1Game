import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.club import Club


@pytest.fixture(autouse=True)
async def seed_clubs(db_session: AsyncSession):
    clubs = [
        Club(
            name="Test Arena",
            location="Test district, Tashkent",
            total_computers=10,
            rating=4.5,
            price_per_hour=10000,
            opening_hour=9,
            closing_hour=22,
        ),
        Club(
            name="Another Club",
            location="Another district, Tashkent",
            total_computers=5,
            rating=4.0,
            price_per_hour=8000,
            opening_hour=10,
            closing_hour=21,
        ),
    ]
    for c in clubs:
        db_session.add(c)
    await db_session.commit()


@pytest.mark.asyncio
async def test_list_clubs(client: AsyncClient):
    response = await client.get("/api/clubs")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2


@pytest.mark.asyncio
async def test_list_clubs_search(client: AsyncClient):
    response = await client.get("/api/clubs?search=Test")
    assert response.status_code == 200
    data = response.json()
    names = [c["name"] for c in data]
    assert any("Test" in n for n in names)


@pytest.mark.asyncio
async def test_list_clubs_sort_by_rating(client: AsyncClient):
    response = await client.get("/api/clubs?sortBy=rating")
    assert response.status_code == 200
    data = response.json()
    ratings = [c["rating"] for c in data]
    assert ratings == sorted(ratings, reverse=True)


@pytest.mark.asyncio
async def test_list_clubs_sort_by_price(client: AsyncClient):
    response = await client.get("/api/clubs?sortBy=price")
    assert response.status_code == 200
    data = response.json()
    prices = [c["price_per_hour"] for c in data]
    assert prices == sorted(prices)


@pytest.mark.asyncio
async def test_get_club(client: AsyncClient):
    # Get first club
    clubs = (await client.get("/api/clubs")).json()
    club_id = clubs[0]["id"]
    response = await client.get(f"/api/clubs/{club_id}")
    assert response.status_code == 200
    assert response.json()["id"] == club_id


@pytest.mark.asyncio
async def test_get_club_not_found(client: AsyncClient):
    response = await client.get("/api/clubs/99999")
    assert response.status_code == 404
    assert "error" in response.json()


@pytest.mark.asyncio
async def test_get_slots(client: AsyncClient):
    clubs = (await client.get("/api/clubs")).json()
    club_id = clubs[0]["id"]
    response = await client.get(f"/api/clubs/{club_id}/slots?date=2025-06-15")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
    assert "time" in data[0]
    assert "availableComputers" in data[0]


@pytest.mark.asyncio
async def test_clubs_no_auth_required(client: AsyncClient):
    # Public endpoint - no token needed
    response = await client.get("/api/clubs")
    assert response.status_code == 200
