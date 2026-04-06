import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    response = await client.post(
        "/api/auth/register",
        json={
            "username": "testuser",
            "email": "test@example.com",
            "password": "securepassword123",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate(client: AsyncClient):
    payload = {
        "username": "dupuser",
        "email": "dup@example.com",
        "password": "securepassword123",
    }
    await client.post("/api/auth/register", json=payload)
    response = await client.post("/api/auth/register", json=payload)
    assert response.status_code == 409
    assert "error" in response.json()


@pytest.mark.asyncio
async def test_register_invalid_username(client: AsyncClient):
    response = await client.post(
        "/api/auth/register",
        json={
            "username": "bad user!",
            "email": "bad@example.com",
            "password": "securepassword123",
        },
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient):
    await client.post(
        "/api/auth/register",
        json={
            "username": "loginuser",
            "email": "login@example.com",
            "password": "securepassword123",
        },
    )
    response = await client.post(
        "/api/auth/login",
        json={"username": "loginuser", "password": "securepassword123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient):
    await client.post(
        "/api/auth/register",
        json={
            "username": "wrongpass",
            "email": "wrongpass@example.com",
            "password": "securepassword123",
        },
    )
    response = await client.post(
        "/api/auth/login",
        json={"username": "wrongpass", "password": "wrongpassword"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_token(client: AsyncClient):
    reg = await client.post(
        "/api/auth/register",
        json={
            "username": "refreshuser",
            "email": "refresh@example.com",
            "password": "securepassword123",
        },
    )
    refresh_token = reg.json()["refresh_token"]
    response = await client.post("/api/auth/refresh", json={"refresh_token": refresh_token})
    assert response.status_code == 200
    assert "access_token" in response.json()


@pytest.mark.asyncio
async def test_refresh_invalid_token(client: AsyncClient):
    response = await client.post(
        "/api/auth/refresh", json={"refresh_token": "this.is.invalid"}
    )
    assert response.status_code == 401
