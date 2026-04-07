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
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(subject: int, role: str = "user") -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": str(subject), "exp": expire, "type": "access", "role": role}
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


async def _get_user_role(db: AsyncSession, user_id: int) -> str:
    result = await db.execute(select(AdminUser).where(AdminUser.user_id == user_id))
    admin = result.scalar_one_or_none()
    if admin:
        return admin.role.value
    return "user"


async def register_user(db: AsyncSession, data: RegisterRequest, auto_approve: bool = True) -> TokenResponse:
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
