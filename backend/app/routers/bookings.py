from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.booking import BookingCreate, BookingResponse
from app.services.booking_service import (
    cancel_booking,
    create_booking,
    get_booking,
    list_user_bookings,
)

router = APIRouter(prefix="/api/bookings", tags=["bookings"])


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking_endpoint(
    data: BookingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await create_booking(db, current_user, data)


@router.get("", response_model=list[BookingResponse])
async def list_bookings_endpoint(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await list_user_bookings(db, current_user)


@router.get("/{booking_id}", response_model=BookingResponse)
async def get_booking_endpoint(
    booking_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await get_booking(db, current_user, booking_id)


@router.delete("/{booking_id}", response_model=BookingResponse)
async def cancel_booking_delete(
    booking_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await cancel_booking(db, current_user, booking_id)


@router.post("/{booking_id}/cancel", response_model=BookingResponse)
async def cancel_booking_post(
    booking_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Alias for DELETE /{booking_id} — supports clients that prefer POST."""
    return await cancel_booking(db, current_user, booking_id)
