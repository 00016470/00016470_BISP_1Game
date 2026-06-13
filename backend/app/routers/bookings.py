"""
Bookings router for the gaming club application.

This module defines FastAPI routes for managing gaming session bookings,
including creating, listing, retrieving, and canceling bookings.
"""

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.booking import (
    BookingCreate,
    BookingResponse,
    MultiSlotBookingCreate,
    MultiSlotBookingResponse,
)
from app.services.booking_service import (
    cancel_booking,
    create_booking,
    create_multi_slot_booking,
    get_booking,
    list_user_bookings,
)

router = APIRouter(prefix="/api/bookings", tags=["bookings"])


@router.post("/multi-slot", response_model=MultiSlotBookingResponse, status_code=status.HTTP_201_CREATED)
async def create_multi_slot_booking_endpoint(
    data: MultiSlotBookingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Create a multi-slot booking for gaming sessions.

    This endpoint allows users to book multiple time slots at once.

    Args:
        data: Booking data including club, slots, and other details.
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        MultiSlotBookingResponse: Created booking information.
    """
    return await create_multi_slot_booking(db, current_user, data)


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking_endpoint(
    data: BookingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Create a single booking for a gaming session.

    This endpoint allows users to book a single time slot.

    Args:
        data: Booking data including club, slot, and other details.
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        BookingResponse: Created booking information.
    """
    return await create_booking(db, current_user, data)


@router.get("", response_model=list[BookingResponse])
async def list_bookings_endpoint(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieve a list of bookings for the current user.

    This endpoint returns all bookings associated with the authenticated user.

    Args:
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        List[BookingResponse]: List of user's bookings.
    """
    return await list_user_bookings(db, current_user)


@router.get("/{booking_id}", response_model=BookingResponse)
async def get_booking_endpoint(
    booking_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieve details of a specific booking.

    This endpoint returns detailed information about a particular booking.

    Args:
        booking_id: The ID of the booking to retrieve.
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        BookingResponse: Booking details.
    """
    return await get_booking(db, current_user, booking_id)


@router.delete("/{booking_id}", response_model=BookingResponse)
async def cancel_booking_delete(
    booking_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Cancel a booking using DELETE method.

    This endpoint cancels an existing booking for the user.

    Args:
        booking_id: The ID of the booking to cancel.
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        BookingResponse: Updated booking information after cancellation.
    """
    return await cancel_booking(db, current_user, booking_id)


@router.post("/{booking_id}/cancel", response_model=BookingResponse)
async def cancel_booking_post(
    booking_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Cancel a booking using POST method.

    This endpoint provides an alternative way to cancel a booking.

    Args:
        booking_id: The ID of the booking to cancel.
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        BookingResponse: Updated booking information after cancellation.
    """
    return await cancel_booking(db, current_user, booking_id)
