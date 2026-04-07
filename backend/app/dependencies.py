from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.exceptions import ForbiddenError, UnauthorizedError
from app.models.admin import AdminUser, AdminRole
from app.models.user import User
from app.services.auth_service import decode_token

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    if not credentials:
        raise UnauthorizedError("Missing authentication token")

    payload = decode_token(credentials.credentials)
    if payload.get("type") != "access":
        raise UnauthorizedError("Invalid token type")

    user_id = int(payload["sub"])
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise UnauthorizedError("User not found")

    return user


async def get_current_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    user = await get_current_user(credentials, db)

    result = await db.execute(select(AdminUser).where(AdminUser.user_id == user.id))
    admin = result.scalar_one_or_none()
    if not admin:
        raise ForbiddenError("Admin access required")

    return user


async def get_club_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> tuple[User, AdminUser]:
    """Returns (user, admin_record) — enforces any admin role."""
    user = await get_current_user(credentials, db)
    result = await db.execute(select(AdminUser).where(AdminUser.user_id == user.id))
    admin = result.scalar_one_or_none()
    if not admin:
        raise ForbiddenError("Admin access required")
    return user, admin
