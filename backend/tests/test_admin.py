"""Tests for admin endpoints and role-based access control."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_admin_dashboard_requires_admin(client: AsyncClient, auth_token: str):
    resp = await client.get(
        "/api/admin/dashboard",
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_admin_dashboard_accessible_by_admin(client: AsyncClient, admin_token: str):
    resp = await client.get(
        "/api/admin/dashboard",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "total_revenue_today" in data
    assert "active_bookings" in data
    assert "pending_payments" in data
    assert "total_users" in data
    assert "bookings_by_club" in data
    assert "revenue_by_day" in data
    assert len(data["revenue_by_day"]) == 30


@pytest.mark.asyncio
async def test_admin_users_list(client: AsyncClient, admin_token: str):
    resp = await client.get(
        "/api/admin/users",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] > 0


@pytest.mark.asyncio
async def test_admin_payments_list(client: AsyncClient, admin_token: str):
    resp = await client.get(
        "/api/admin/payments",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    assert "items" in resp.json()


@pytest.mark.asyncio
async def test_admin_validate_cash_payment(
    client: AsyncClient, auth_token: str, admin_token: str, club_id: int
):
    from datetime import datetime, timedelta, timezone
    start = (datetime.now(timezone.utc) + timedelta(hours=6)).replace(
        minute=0, second=0, microsecond=0
    ).isoformat()
    booking_resp = await client.post(
        "/api/bookings",
        json={"club_id": club_id, "start_time": start, "duration_hours": 1, "computers_booked": 1},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert booking_resp.status_code == 201
    booking_id = booking_resp.json()["id"]

    pay_resp = await client.post(
        "/api/payments/process",
        json={"booking_id": booking_id, "method": "CASH"},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert pay_resp.status_code == 200
    payment_id = pay_resp.json()["id"]
    assert pay_resp.json()["status"] == "PENDING"

    validate_resp = await client.post(
        f"/api/admin/payments/{payment_id}/validate",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert validate_resp.status_code == 200
    assert validate_resp.json()["status"] == "COMPLETED"
    assert validate_resp.json()["validated_by"] is not None


@pytest.mark.asyncio
async def test_admin_club_live(client: AsyncClient, admin_token: str, club_id: int):
    resp = await client.get(
        f"/api/admin/clubs/{club_id}/live",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "available_computers" in data
    assert "occupancy_percent" in data
    assert data["club_id"] == club_id


@pytest.mark.asyncio
async def test_regular_user_cannot_access_admin(client: AsyncClient, auth_token: str):
    endpoints = [
        "/api/admin/dashboard",
        "/api/admin/users",
        "/api/admin/payments",
        "/api/admin/bookings",
    ]
    for ep in endpoints:
        resp = await client.get(ep, headers={"Authorization": f"Bearer {auth_token}"})
        assert resp.status_code == 403, f"{ep} should return 403 for regular user"
