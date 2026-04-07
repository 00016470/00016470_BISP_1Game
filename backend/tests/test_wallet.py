"""Tests for wallet top-up and balance accuracy."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_wallet_unauthenticated(client: AsyncClient):
    resp = await client.get("/api/wallet")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_wallet_created_on_register(client: AsyncClient):
    resp = await client.post("/api/auth/register", json={
        "username": "walletuser1",
        "email": "wallet1@test.com",
        "password": "Test1234!",
    })
    assert resp.status_code == 201
    token = resp.json()["access_token"]

    resp = await client.get("/api/wallet", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["balance"] == 0.0
    assert data["currency"] == "UZS"


@pytest.mark.asyncio
async def test_top_up_wallet(client: AsyncClient, auth_token: str):
    resp = await client.post(
        "/api/wallet/top-up",
        json={"amount": 50000},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["wallet"]["balance"] == 50000.0
    assert "reference_code" in data
    assert data["reference_code"].startswith("TXN-")


@pytest.mark.asyncio
async def test_top_up_multiple_times(client: AsyncClient, auth_token: str):
    for amount in [10000, 20000, 30000]:
        resp = await client.post(
            "/api/wallet/top-up",
            json={"amount": amount},
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        assert resp.status_code == 200

    resp = await client.get("/api/wallet", headers={"Authorization": f"Bearer {auth_token}"})
    assert resp.status_code == 200
    assert resp.json()["balance"] == 60000.0


@pytest.mark.asyncio
async def test_top_up_invalid_amount(client: AsyncClient, auth_token: str):
    resp = await client.post(
        "/api/wallet/top-up",
        json={"amount": -1000},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_top_up_zero_amount(client: AsyncClient, auth_token: str):
    resp = await client.post(
        "/api/wallet/top-up",
        json={"amount": 0},
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert resp.status_code == 422
