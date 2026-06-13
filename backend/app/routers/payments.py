"""
Payments router for the gaming club application.

This module defines FastAPI routes for handling payment processing
and retrieving payment information.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.payment import PaymentProcessRequest, PaymentResponse
from app.services.payment_service import get_payment, process_payment

router = APIRouter(prefix="/api/payments", tags=["payments"])


@router.post("/process", response_model=PaymentResponse)
async def process_payment_endpoint(
    data: PaymentProcessRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Process a payment for a booking.

    This endpoint handles payment processing for user bookings.

    Args:
        data: Payment processing data including booking ID and payment method.
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        PaymentResponse: Payment processing result.
    """
    return await process_payment(db, current_user, data.booking_id, data.method)


@router.get("/{payment_id}", response_model=PaymentResponse)
async def get_payment_endpoint(
    payment_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieve details of a specific payment.

    This endpoint returns information about a particular payment.

    Args:
        payment_id: The ID of the payment to retrieve.
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        PaymentResponse: Payment details.
    """
    return await get_payment(db, current_user, payment_id)
