"""
Authentication Service Module

This module handles user authentication, registration, login, and token management.
It provides functions for password hashing, JWT token creation and validation,
user registration with wallet creation, login, and token refresh.
All functions are asynchronous where database interaction is required.
"""

import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.exceptions import UnauthorizedError, ConflictError
from app.models.admin import AdminUser
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, UserResponse

settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    """
    Hash a plain text password using bcrypt.

    Parameters:
    - password (str): The plain text password to hash.

    Returns:
    - str: The hashed password string.
    """
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    """
    Verify a plain text password against a hashed password.

    Parameters:
    - plain (str): The plain text password.
    - hashed (str): The hashed password to compare against.

    Returns:
    - bool: True if the password matches, False otherwise.
    """
    return pwd_context.verify(plain, hashed)


def create_access_token(subject: int, role: str = "user") -> str:
    """
    Create a JWT access token for a user.

    Parameters:
    - subject (int): The user ID to encode in the token.
    - role (str): The user's role (default "user").

    Returns:
    - str: The encoded JWT access token.
    """
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": str(subject), "exp": expire, "type": "access", "role": role}
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def create_refresh_token_str(subject: int) -> str:
    """
    Create a JWT refresh token string for a user.

    Parameters:
    - subject (int): The user ID to encode in the token.

    Returns:
    - str: The encoded JWT refresh token.
    """
    expire = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    payload = {"sub": str(subject), "exp": expire, "type": "refresh", "jti": str(uuid.uuid4())}
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    """
    Decode and validate a JWT token.

    Parameters:
    - token (str): The JWT token to decode.

    Returns:
    - dict: The decoded payload.

    Raises:
    - UnauthorizedError: If the token is invalid or expired.
    """
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
        return payload
    except JWTError as exc:
        raise UnauthorizedError("Invalid or expired token") from exc


async def _get_user_role(db: AsyncSession, user_id: int) -> str:
    """
    Get the role of a user (admin or user).

    Parameters:
    - db (AsyncSession): The asynchronous database session.
    - user_id (int): The ID of the user.

    Returns:
    - str: The user's role ("admin" or "user").
    """
    result = await db.execute(select(AdminUser).where(AdminUser.user_id == user_id))
    admin = result.scalar_one_or_none()
    if admin:
        return admin.role.value
    return "user"


async def register_user(db: AsyncSession, data: RegisterRequest, auto_approve: bool = True) -> TokenResponse:
    """
    Register a new user and create their wallet.

    Creates a new user account, hashes the password, and automatically creates a wallet.
    Issues authentication tokens upon successful registration.

    Parameters:
    - db (AsyncSession): The asynchronous database session.
    - data (RegisterRequest): The registration data including username, email, password, phone.
    - auto_approve (bool): Whether to auto-approve the user. Default True.

    Returns:
    - TokenResponse: Authentication tokens and user information.

    Raises:
    - ConflictError: If username or email is already registered.
    """
    existing = await db.execute(
        select(User).where((User.username == data.username) | (User.email == data.email))
    )
    if existing.scalar_one_or_none():
        raise ConflictError("Username or email already registered")

    user = User(
        username=data.username,
        email=data.email,
        password_hash=hash_password(data.password),
        phone=data.phone,
        is_approved=auto_approve,
    )
    db.add(user)
    await db.flush()

    # Auto-create wallet on registration
    wallet = Wallet(user_id=user.id, balance=0.00, currency="UZS")
    db.add(wallet)
    await db.flush()

    return await _issue_tokens(db, user, role="user")


async def login_user(db: AsyncSession, data: LoginRequest) -> TokenResponse:
    """
    Authenticate a user and issue tokens.

    Verifies the user's credentials and issues access and refresh tokens.

    Parameters:
    - db (AsyncSession): The asynchronous database session.
    - data (LoginRequest): The login data including username/email and password.

    Returns:
    - TokenResponse: Authentication tokens and user information.

    Raises:
    - UnauthorizedError: If credentials are invalid.
    """
    identifier = data.username or data.email
    if data.email:
        result = await db.execute(select(User).where(User.email == data.email))
    else:
        result = await db.execute(select(User).where(User.username == identifier))
    user = result.scalar_one_or_none()
    if not user or not verify_password(data.password, user.password_hash):
        raise UnauthorizedError("Invalid email/username or password")

    role = await _get_user_role(db, user.id)
    return await _issue_tokens(db, user, role=role)


async def refresh_access_token(db: AsyncSession, refresh_token: str) -> TokenResponse:
    """
    Refresh access token using a valid refresh token.

    Validates the refresh token, checks its existence and expiration,
    then issues new access and refresh tokens.

    Parameters:
    - db (AsyncSession): The asynchronous database session.
    - refresh_token (str): The refresh token string.

    Returns:
    - TokenResponse: New authentication tokens and user information.

    Raises:
    - UnauthorizedError: If the refresh token is invalid, expired, or not found.
    """
    payload = decode_token(refresh_token)
    if payload.get("type") != "refresh":
        raise UnauthorizedError("Invalid token type")

    result = await db.execute(
        select(RefreshToken).where(RefreshToken.token == refresh_token)
    )
    stored = result.scalar_one_or_none()
    if not stored:
        raise UnauthorizedError("Refresh token not found or already revoked")

    now = datetime.now(timezone.utc)
    expires = stored.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < now:
        await db.delete(stored)
        raise UnauthorizedError("Refresh token expired")

    user_id = int(payload["sub"])
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise UnauthorizedError("User not found")

    role = await _get_user_role(db, user.id)
    await db.delete(stored)
    return await _issue_tokens(db, user, role=role)


async def _issue_tokens(db: AsyncSession, user: User, role: str = "user") -> TokenResponse:
    """
    Issue new access and refresh tokens for a user.

    Creates and stores a new refresh token in the database,
    then returns both access and refresh tokens along with user info.

    Parameters:
    - db (AsyncSession): The asynchronous database session.
    - user (User): The user object.
    - role (str): The user's role. Default "user".

    Returns:
    - TokenResponse: The token response with access, refresh tokens, and user data.
    """
    access = create_access_token(user.id, role=role)
    refresh_str = create_refresh_token_str(user.id)

    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    rt = RefreshToken(user_id=user.id, token=refresh_str, expires_at=expires_at)
    db.add(rt)
    await db.flush()

    user_resp = UserResponse.model_validate(user)
    user_resp = user_resp.model_copy(update={"role": role})

    return TokenResponse(
        access_token=access,
        refresh_token=refresh_str,
        access=access,
        refresh=refresh_str,
        user=user_resp,
        role=role,
    )
