"""Tests for multi-slot booking: success case and conflict rejection."""
import pytest
from datetime import datetime, timedelta, timezone
from httpx import AsyncClient


def _future(hours: int) -> str:
    return (
        datetime.now(timezone.utc)
        .replace(minute=0, second=0, microsecond=0)
        + timedelta(hours=hours)
    ).isoformat()


@pytest.mark.asyncio
async def test_multi_slot_booking_success(client: AsyncClient, auth_token: str, club_id: int):
    # Top up wallet first
    await client.post(
        "/api/wallet/top-up",
        json={"amount": 1_000_000},
        headers={"Authorization": f"Bearer {auth_token}"},
    )

    resp = await client.post(
        "/api/bookings/multi-slot",
        json={
            "club_id": club_id,
            "slots": [
                {"start_time": _future(10), "duration_hours": 1},
                {"start_time": _future(12), "duration_hours": 2},
            ],
            "computers_booked": 2,
            "payment_method": "WALLET",
        },
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["payment_status"] == "COMPLETED"
    assert data["total_price"] > 0
    assert data["reference_code"].startswith("TXN-")
    assert data["booking"]["slot_details"] is not None


@pytest.mark.asyncio
async def test_multi_slot_booking_cash(client: AsyncClient, auth_token: str, club_id: int):
    resp = await client.post(
        "/api/bookings/multi-slot",
        json={
            "club_id": club_id,
            "slots": [
                {"start_time": _future(20), "duration_hours": 1},
            ],
            "computers_booked": 1,
            "payment_method": "CASH",
        },
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 201
    assert resp.json()["payment_status"] == "PENDING"
    assert resp.json()["payment_method"] == "CASH"


@pytest.mark.asyncio
async def test_multi_slot_past_time_rejected(client: AsyncClient, auth_token: str, club_id: int):
    past = (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat()
    resp = await client.post(
        "/api/bookings/multi-slot",
        json={
            "club_id": club_id,
            "slots": [{"start_time": past, "duration_hours": 1}],
            "computers_booked": 1,
            "payment_method": "CASH",
        },
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_multi_slot_conflict_rejects_all(client: AsyncClient, auth_token: str, club_id: int):
    """If one slot conflicts the entire booking should be rejected (409)."""
    hour = _future(30)

    # Book all computers in that slot
    clubs_resp = await client.get(f"/api/clubs/{club_id}")
    total_computers = clubs_resp.json()["total_computers"]

    await client.post(
        "/api/bookings",
        json={
            "club_id": club_id,
            "start_time": hour,
            "duration_hours": 1,
            "computers_booked": total_computers,
        },
        headers={"Authorization": f"Bearer {auth_token}"},
    )

    # Now try a multi-slot that includes that fully-booked slot
    resp = await client.post(
        "/api/bookings/multi-slot",
        json={
            "club_id": club_id,
            "slots": [
                {"start_time": _future(29), "duration_hours": 1},  # ok
                {"start_time": hour, "duration_hours": 1},          # conflict
            ],
            "computers_booked": 1,
            "payment_method": "CASH",
        },
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_transaction_log_integrity(client: AsyncClient, auth_token: str):
    """balance_before + amount = balance_after for TOP_UP transactions."""
    await client.post(
        "/api/wallet/top-up",
        json={"amount": 75_000},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    txns_resp = await client.get(
        "/api/transactions",
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert txns_resp.status_code == 200
    items = txns_resp.json()["items"]
    for t in items:
        if t["type"] == "TOP_UP":
            assert abs((t["balance_before"] + t["amount"]) - t["balance_after"]) < 0.01
