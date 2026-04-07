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
    return await process_payment(db, current_user, data.booking_id, data.method)


@router.get("/{payment_id}", response_model=PaymentResponse)
async def get_payment_endpoint(
    payment_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await get_payment(db, current_user, payment_id)
