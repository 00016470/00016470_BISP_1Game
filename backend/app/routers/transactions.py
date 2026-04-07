from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.transaction import TransactionListResponse, TransactionResponse, TransactionSummary
from app.services.transaction_service import (
    get_transaction,
    get_transaction_summary,
    list_transactions,
)

router = APIRouter(prefix="/api/transactions", tags=["transactions"])


@router.get("/summary", response_model=TransactionSummary)
async def transaction_summary(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await get_transaction_summary(db, current_user)


@router.get("", response_model=TransactionListResponse)
async def list_my_transactions(
    type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    from_date: Optional[datetime] = Query(None),
    to_date: Optional[datetime] = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await list_transactions(
        db, current_user,
        type_filter=type,
        status_filter=status,
        from_date=from_date,
        to_date=to_date,
        page=page,
        per_page=per_page,
    )


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction_endpoint(
    transaction_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await get_transaction(db, current_user, transaction_id)
