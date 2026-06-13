"""
Authentication router for the gaming club application.

This module defines FastAPI routes for user authentication, including
registration, login, token refresh, user profile, and logout functionality.
"""

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user
from app.database import get_db
from app.models.booking import Booking
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.schemas.auth import LoginRequest, RefreshRequest, RegisterRequest, TokenResponse, UserResponse
from app.services.auth_service import login_user, refresh_access_token, register_user, _get_user_role

router = APIRouter(prefix="/api/auth", tags=["auth"])

_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    Register a new user account.

    This endpoint creates a new user account with the provided registration data
    and returns authentication tokens upon successful registration.

    Args:
        data: Registration data including username, email, and password.
        db: Database session dependency.

    Returns:
        TokenResponse: Authentication tokens for the newly registered user.
    """
    return await register_user(db, data)


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Authenticate a user and provide access tokens.

    This endpoint verifies user credentials and returns authentication tokens
    if the login is successful.

    Args:
        data: Login data including username/email and password.
        db: Database session dependency.

    Returns:
        TokenResponse: Authentication tokens for the logged-in user.
    """
    return await login_user(db, data)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, db: AsyncSession = Depends(get_db)):
    """
    Refresh access token using a refresh token.

    This endpoint validates a refresh token and issues a new access token
    if the refresh token is valid and not expired.

    Args:
        data: Refresh request containing the refresh token.
        db: Database session dependency.

    Returns:
        TokenResponse: New authentication tokens.
    """
    return await refresh_access_token(db, data.token)


@router.get("/me", response_model=UserResponse)
async def me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get current user profile information.

    This endpoint returns detailed information about the authenticated user,
    including booking count, join date, and role.

    Args:
        current_user: Currently authenticated user from dependency.
        db: Database session dependency.

    Returns:
        UserResponse: User profile data with additional computed fields.
    """
    result = await db.execute(
        select(func.count(Booking.id)).where(Booking.user_id == current_user.id)
    )
    total_bookings = result.scalar() or 0

    joined_at = None
    if current_user.created_at:
        joined_at = f"{_MONTHS[current_user.created_at.month - 1]} {current_user.created_at.year}"

    role = await _get_user_role(db, current_user.id)

    return UserResponse(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        phone=current_user.phone,
        is_approved=current_user.is_approved,
        total_bookings=total_bookings,
        joined_at=joined_at,
        role=role,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Logout the current user by invalidating refresh tokens.

    This endpoint removes all refresh tokens associated with the current user,
    effectively logging them out from all sessions.

    Args:
        current_user: Currently authenticated user from dependency.
        db: Database session dependency.

    Returns:
        Response: No content response indicating successful logout.
    """
    await db.execute(delete(RefreshToken).where(RefreshToken.user_id == current_user.id))
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
