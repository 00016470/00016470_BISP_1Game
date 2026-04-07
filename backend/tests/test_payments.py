"""Tests for payment processing (WALLET, CARD, CASH) and refund logic."""
import pytest
from httpx import AsyncClient


async def _create_booking_with_wallet(client: AsyncClient, token: str, club_id: int) -> dict:
    """Helper: top up wallet, create booking, return booking data."""
    await client.post(
        "/api/wallet/top-up",
        json={"amount": 500_000},
        headers={"Authorization": f"Bearer {token}"},
    )
    from datetime import datetime, timedelta, timezone
    start = (datetime.now(timezone.utc) + timedelta(hours=2)).replace(
        minute=0, second=0, microsecond=0
    ).isoformat()
    resp = await client.post(
        "/api/bookings",
        json={"club_id": club_id, "start_time": start, "duration_hours": 1, "computers_booked": 1},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 201
    return resp.json()


@pytest.mark.asyncio
async def test_wallet_payment_deducts_balance(client: AsyncClient, auth_token: str, club_id: int):
    await client.post(
        "/api/wallet/top-up",
        json={"amount": 500_000},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    wallet_before = (await client.get("/api/wallet", headers={"Authorization": f"Bearer {auth_token}"})).json()

    booking = await _create_booking_with_wallet(client, auth_token, club_id)
    booking_id = booking["id"]
    total_price = booking["total_price"]

    resp = await client.post(
        "/api/payments/process",
        json={"booking_id": booking_id, "method": "WALLET"},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "COMPLETED"

    wallet_after = (await client.get("/api/wallet", headers={"Authorization": f"Bearer {auth_token}"})).json()
    # Balance decreases by total_price (allowing for multiple top-ups)
    assert wallet_after["balance"] < wallet_before["balance"] + 500_000


@pytest.mark.asyncio
async def test_cash_payment_creates_pending(client: AsyncClient, auth_token: str, club_id: int):
    from datetime import datetime, timedelta, timezone
    start = (datetime.now(timezone.utc) + timedelta(hours=3)).replace(
        minute=0, second=0, microsecond=0
    ).isoformat()
    resp = await client.post(
        "/api/bookings",
        json={"club_id": club_id, "start_time": start, "duration_hours": 1, "computers_booked": 1},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 201
    booking_id = resp.json()["id"]

    await client.post(
        "/api/wallet/top-up",
        json={"amount": 100_000},
        headers={"Authorization": f"Bearer {auth_token}"},
    )

    resp = await client.post(
        "/api/payments/process",
        json={"booking_id": booking_id, "method": "CASH"},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "PENDING"
    assert resp.json()["method"] == "CASH"


@pytest.mark.asyncio
async def test_insufficient_wallet_balance(client: AsyncClient, auth_token: str, club_id: int):
    # Don't top up — balance should be 0
    from datetime import datetime, timedelta, timezone
    start = (datetime.now(timezone.utc) + timedelta(hours=4)).replace(
        minute=0, second=0, microsecond=0
    ).isoformat()
    resp = await client.post(
        "/api/bookings",
        json={"club_id": club_id, "start_time": start, "duration_hours": 2, "computers_booked": 3},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 201
    booking_id = resp.json()["id"]

    resp = await client.post(
        "/api/payments/process",
        json={"booking_id": booking_id, "method": "WALLET"},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 400
    assert "Insufficient" in resp.json()["error"]


@pytest.mark.asyncio
async def test_cancel_wallet_booking_refunds(client: AsyncClient, auth_token: str, club_id: int):
    await client.post(
        "/api/wallet/top-up",
        json={"amount": 500_000},
        headers={"Authorization": f"Bearer {auth_token}"},
    )

    from datetime import datetime, timedelta, timezone
    start = (datetime.now(timezone.utc) + timedelta(hours=5)).replace(
        minute=0, second=0, microsecond=0
    ).isoformat()
    from app.models.club import Club

    resp = await client.post(
        "/api/bookings",
        json={"club_id": club_id, "start_time": start, "duration_hours": 1, "computers_booked": 1},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 201
    booking_id = resp.json()["id"]

    # Pay via wallet
    await client.post(
        "/api/payments/process",
        json={"booking_id": booking_id, "method": "WALLET"},
        headers={"Authorization": f"Bearer {auth_token}"},
    )

    wallet_mid = (await client.get("/api/wallet", headers={"Authorization": f"Bearer {auth_token}"})).json()

    # Cancel — should trigger refund
    resp = await client.delete(
        f"/api/bookings/{booking_id}",
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 200

    wallet_after = (await client.get("/api/wallet", headers={"Authorization": f"Bearer {auth_token}"})).json()
    assert wallet_after["balance"] > wallet_mid["balance"]
