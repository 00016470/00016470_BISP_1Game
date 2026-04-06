import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.exceptions import UnauthorizedError, ConflictError
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, UserResponse

settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(subject: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": str(subject), "exp": expire, "type": "access"}
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def create_refresh_token_str(subject: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    payload = {"sub": str(subject), "exp": expire, "type": "refresh", "jti": str(uuid.uuid4())}
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
        return payload
    except JWTError as exc:
        raise UnauthorizedError("Invalid or expired token") from exc


async def register_user(db: AsyncSession, data: RegisterRequest) -> TokenResponse:
    # Check uniqueness
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
    )
    db.add(user)
    await db.flush()  # get user.id

    return await _issue_tokens(db, user)


async def login_user(db: AsyncSession, data: LoginRequest) -> TokenResponse:
    identifier = data.username or data.email
    if data.email:
        result = await db.execute(select(User).where(User.email == data.email))
    else:
        result = await db.execute(select(User).where(User.username == identifier))
    user = result.scalar_one_or_none()
    if not user or not verify_password(data.password, user.password_hash):
        raise UnauthorizedError("Invalid email/username or password")

    return await _issue_tokens(db, user)


async def refresh_access_token(db: AsyncSession, refresh_token: str) -> TokenResponse:
    payload = decode_token(refresh_token)
    if payload.get("type") != "refresh":
        raise UnauthorizedError("Invalid token type")

    # Validate stored token
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

    # Rotate: delete old, issue new
    await db.delete(stored)
    return await _issue_tokens(db, user)


async def _issue_tokens(db: AsyncSession, user: User) -> TokenResponse:
    access = create_access_token(user.id)
    refresh_str = create_refresh_token_str(user.id)

    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    rt = RefreshToken(user_id=user.id, token=refresh_str, expires_at=expires_at)
    db.add(rt)
    await db.flush()

    return TokenResponse(
        access_token=access,
        refresh_token=refresh_str,
        access=access,
        refresh=refresh_str,
        user=UserResponse.model_validate(user),
    )
