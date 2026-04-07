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
    return await list_admin_payments(db, status=status, method=method,
                                     from_date=from_date, to_date=to_date,
                                     page=page, per_page=per_page)


@router.post("/payments/{payment_id}/validate", response_model=PaymentValidateResponse)
async def validate_payment(
    payment_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await validate_cash_payment(db, admin_user, payment_id)


@router.get("/users")
async def admin_users(
    pending_only: bool = Query(False),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await list_admin_users(db, page=page, per_page=per_page, pending_only=pending_only)


@router.post("/users", status_code=201)
async def admin_create_user(
    data: RegisterRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    """Admin creates a gamer account directly (auto-approved)."""
    result = await register_user(db, data, auto_approve=True)
    return {"id": result["user"]["id"], "username": result["user"]["username"],
            "email": result["user"]["email"], "message": "User created successfully"}


@router.post("/users/{user_id}/approve", response_model=AdminUserResponse)
async def approve_user_endpoint(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await approve_user(db, user_id)


@router.post("/users/{user_id}/reject")
async def reject_user_endpoint(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await reject_user(db, user_id)


@router.delete("/users/{user_id}")
async def delete_user_endpoint(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await delete_user(db, user_id)


@router.get("/users/{user_id}", response_model=AdminUserDetailResponse)
async def admin_user_detail(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await get_admin_user_detail(db, user_id)


@router.get("/clubs/{club_id}/live", response_model=ClubLiveResponse)
async def club_live(
    club_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await get_club_live(db, club_id)


@router.get("/clubs/{club_id}/sessions", response_model=ClubSessionsResponse)
async def club_sessions(
    club_id: int,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await get_club_sessions(db, club_id)


@router.get("/clubs/{club_id}/revenue", response_model=ClubRevenueResponse)
async def club_revenue(
    club_id: int,
    from_date: Optional[datetime] = Query(None),
    to_date: Optional[datetime] = Query(None),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await get_club_revenue(db, club_id, from_date=from_date, to_date=to_date)
