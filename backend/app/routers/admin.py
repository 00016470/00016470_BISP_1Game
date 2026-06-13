"""
Admin router for the gaming club application.

This module defines FastAPI routes for administrative operations, including
dashboard, user management, booking management, payment validation, and club analytics.
"""

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_admin
from app.models.user import User
from app.schemas.admin import (
    AdminUserDetailResponse,
    AdminUserResponse,
    ClubLiveResponse,
    ClubRevenueResponse,
    ClubSessionsResponse,
    DashboardResponse,
)
from app.schemas.payment import PaymentValidateResponse
from app.services.admin_service import (
    approve_user,
    delete_user,
    get_admin_user_detail,
    get_club_live,
    get_club_revenue,
    get_club_sessions,
    get_dashboard,
    list_admin_bookings,
    list_admin_payments,
    list_admin_users,
    reject_user,
)
from app.services.auth_service import register_user
from app.schemas.auth import RegisterRequest, TokenResponse
from app.services.payment_service import validate_cash_payment

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.get("/dashboard", response_model=DashboardResponse)
async def admin_dashboard(
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Retrieve the admin dashboard data.

    This endpoint provides an overview of key metrics and statistics for the admin.

    Args:
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        DashboardResponse: Dashboard data including metrics and statistics.
    """
    return await get_dashboard(db)


@router.get("/bookings")
async def admin_bookings(
    club_id: Optional[int] = Query(None),
    status: Optional[str] = Query(None),
    date: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Retrieve a paginated list of bookings for admin review.

    This endpoint allows admins to filter and view bookings across clubs.

    Args:
        club_id: Optional club ID to filter bookings.
        status: Optional booking status to filter.
        date: Optional date to filter bookings.
        page: Page number for pagination (default 1).
        per_page: Number of items per page (default 20, max 100).
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        Paginated list of bookings.
    """
    return await list_admin_bookings(db, club_id=club_id, status=status, date=date,
                                     page=page, per_page=per_page)


@router.get("/payments")
async def admin_payments(
    status: Optional[str] = Query(None),
    method: Optional[str] = Query(None),
    from_date: Optional[datetime] = Query(None),
    to_date: Optional[datetime] = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Retrieve a paginated list of payments for admin review.

    This endpoint allows admins to filter payments by status, method, and date range.

    Args:
        status: Optional payment status to filter.
        method: Optional payment method to filter.
        from_date: Optional start date for filtering.
        to_date: Optional end date for filtering.
        page: Page number for pagination (default 1).
        per_page: Number of items per page (default 20, max 100).
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        Paginated list of payments.
    """
    return await list_admin_payments(db, status=status, method=method,
                                     from_date=from_date, to_date=to_date,
                                     page=page, per_page=per_page)


@router.post("/payments/{payment_id}/validate", response_model=PaymentValidateResponse)
async def validate_payment(
    payment_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Validate a cash payment.

    This endpoint allows admins to validate cash payments that were recorded.

    Args:
        payment_id: The ID of the payment to validate.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        PaymentValidateResponse: Validation result.
    """
    return await validate_cash_payment(db, admin_user, payment_id)


@router.get("/users")
async def admin_users(
    pending_only: bool = Query(False),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Retrieve a paginated list of users for admin management.

    This endpoint allows admins to view and manage user accounts.

    Args:
        pending_only: If True, show only pending approval users.
        page: Page number for pagination (default 1).
        per_page: Number of items per page (default 20, max 100).
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        Paginated list of users.
    """
    return await list_admin_users(db, page=page, per_page=per_page, pending_only=pending_only)


@router.post("/users", status_code=201)
async def admin_create_user(
    data: RegisterRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Create a new user account directly as an admin.

    This endpoint allows admins to create user accounts that are automatically approved.

    Args:
        data: Registration data including username, email, and password.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        Dict containing user ID, username, email, and success message.
    """
    result = await register_user(db, data, auto_approve=True)
    return {"id": result["user"]["id"], "username": result["user"]["username"],
            "email": result["user"]["email"], "message": "User created successfully"}


@router.post("/users/{user_id}/approve", response_model=AdminUserResponse)
async def approve_user_endpoint(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Approve a pending user account.

    This endpoint allows admins to approve user registrations.

    Args:
        user_id: The ID of the user to approve.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        AdminUserResponse: Updated user information.
    """
    return await approve_user(db, user_id)


@router.post("/users/{user_id}/reject")
async def reject_user_endpoint(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Reject a pending user account.

    This endpoint allows admins to reject user registrations.

    Args:
        user_id: The ID of the user to reject.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        Rejection confirmation.
    """
    return await reject_user(db, user_id)


@router.delete("/users/{user_id}")
async def delete_user_endpoint(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Delete a user account.

    This endpoint allows admins to permanently delete user accounts.

    Args:
        user_id: The ID of the user to delete.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        Deletion confirmation.
    """
    return await delete_user(db, user_id)


@router.get("/users/{user_id}", response_model=AdminUserDetailResponse)
async def admin_user_detail(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Retrieve detailed information about a specific user.

    This endpoint provides comprehensive user details for admin review.

    Args:
        user_id: The ID of the user to retrieve details for.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        AdminUserDetailResponse: Detailed user information.
    """
    return await get_admin_user_detail(db, user_id)


@router.get("/clubs/{club_id}/live", response_model=ClubLiveResponse)
async def club_live(
    club_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Retrieve live status and current activity for a club.

    This endpoint provides real-time information about club operations.

    Args:
        club_id: The ID of the club to check.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        ClubLiveResponse: Live club status and activity data.
    """
    return await get_club_live(db, club_id)


@router.get("/clubs/{club_id}/sessions", response_model=ClubSessionsResponse)
async def club_sessions(
    club_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Retrieve session data for a club.

    This endpoint provides information about gaming sessions at the club.

    Args:
        club_id: The ID of the club to retrieve sessions for.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        ClubSessionsResponse: Club session data.
    """
    return await get_club_sessions(db, club_id)


@router.get("/clubs/{club_id}/revenue", response_model=ClubRevenueResponse)
async def club_revenue(
    club_id: int,
    from_date: Optional[datetime] = Query(None),
    to_date: Optional[datetime] = Query(None),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """
    Retrieve revenue data for a club.

    This endpoint provides financial metrics for the specified club within a date range.

    Args:
        club_id: The ID of the club to retrieve revenue for.
        from_date: Optional start date for the revenue period.
        to_date: Optional end date for the revenue period.
        db: Database session dependency.
        admin_user: Current authenticated admin user.

    Returns:
        ClubRevenueResponse: Club revenue data.
    """
    return await get_club_revenue(db, club_id, from_date=from_date, to_date=to_date)
