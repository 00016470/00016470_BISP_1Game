from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.club import Club


@pytest.fixture(autouse=True)
async def seed_club(db_session: AsyncSession):
    club = Club(
        name="Booking Club",
        location="Booking district, Tashkent",
        total_computers=10,
        rating=4.5,
        price_per_hour=10000,
        opening_hour=0,
        closing_hour=24,
    )
    db_session.add(club)
    await db_session.commit()
    await db_session.refresh(club)
    return club


async def _register_and_login(client: AsyncClient, suffix: str = "") -> dict:
    await client.post(
        "/api/auth/register",
        json={
            "username": f"bookinguser{suffix}",
            "email": f"booking{suffix}@example.com",
            "password": "securepassword123",
        },
    )
    resp = await client.post(
        "/api/auth/login",
        json={"username": f"bookinguser{suffix}", "password": "securepassword123"},
    )
    return resp.json()


@pytest.mark.asyncio
async def test_create_booking_unauthorized(client: AsyncClient):
    response = await client.post(
        "/api/bookings",
        json={"club_id": 1, "start_time": "2099-01-01T10:00:00Z", "duration_hours": 2, "computers_booked": 1},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_create_and_list_bookings(client: AsyncClient):
    tokens = await _register_and_login(client, "1")
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    clubs = (await client.get("/api/clubs")).json()
    club_id = clubs[0]["id"]

    future_time = (datetime.now(timezone.utc) + timedelta(days=1)).replace(
        hour=10, minute=0, second=0, microsecond=0
    )
    response = await client.post(
        "/api/bookings",
        json={
            "club_id": club_id,
            "start_time": future_time.isoformat(),
            "duration_hours": 2,
            "computers_booked": 2,
        },
        headers=headers,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["club_id"] == club_id
    assert data["status"] == "ACTIVE"
    assert data["club_name"] is not None

    # List
    list_resp = await client.get("/api/bookings", headers=headers)
    assert list_resp.status_code == 200
    bookings = list_resp.json()
    assert len(bookings) >= 1


@pytest.mark.asyncio
async def test_cancel_booking(client: AsyncClient):
    tokens = await _register_and_login(client, "2")
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    clubs = (await client.get("/api/clubs")).json()
    club_id = clubs[0]["id"]

    future_time = (datetime.now(timezone.utc) + timedelta(days=2)).replace(
        hour=14, minute=0, second=0, microsecond=0
    )
    create_resp = await client.post(
        "/api/bookings",
        json={
            "club_id": club_id,
            "start_time": future_time.isoformat(),
            "duration_hours": 1,
            "computers_booked": 1,
        },
        headers=headers,
    )
    assert create_resp.status_code == 201
    booking_id = create_resp.json()["id"]

    cancel_resp = await client.delete(f"/api/bookings/{booking_id}", headers=headers)
    assert cancel_resp.status_code == 200
    assert cancel_resp.json()["status"] == "CANCELLED"


@pytest.mark.asyncio
async def test_get_booking_not_found(client: AsyncClient):
    tokens = await _register_and_login(client, "3")
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    response = await client.get("/api/bookings/99999", headers=headers)
    assert response.status_code == 404
    assert "error" in response.json()


@pytest.mark.asyncio
async def test_booking_past_start_time(client: AsyncClient):
    tokens = await _register_and_login(client, "4")
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    clubs = (await client.get("/api/clubs")).json()
    club_id = clubs[0]["id"]

    past_time = (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat()
    response = await client.post(
        "/api/bookings",
        json={
            "club_id": club_id,
            "start_time": past_time,
            "duration_hours": 1,
            "computers_booked": 1,
        },
        headers=headers,
    )
    assert response.status_code in (400, 422)
