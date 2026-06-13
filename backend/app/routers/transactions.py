"""
Transactions router for the gaming club application.

This module defines FastAPI routes for managing user transactions,
including viewing transaction summaries, listing transactions,
and retrieving transaction details.
"""

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
    """
    Retrieve a summary of user transactions.

    This endpoint provides an overview of the user's transaction activity.

    Args:
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        TransactionSummary: Summary of user's transactions.
    """
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
    """
    Retrieve a paginated list of user transactions.

    This endpoint allows users to filter and view their transaction history.

    Args:
        type: Optional transaction type filter.
        status: Optional transaction status filter.
        from_date: Optional start date for filtering.
        to_date: Optional end date for filtering.
        page: Page number for pagination (default 1).
        per_page: Number of items per page (default 20, max 100).
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        TransactionListResponse: Paginated list of transactions.
    """
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
    """
    Retrieve details of a specific transaction.

    This endpoint returns detailed information about a particular transaction.

    Args:
        transaction_id: The ID of the transaction to retrieve.
        db: Database session dependency.
        current_user: Current authenticated user.

    Returns:
        TransactionResponse: Transaction details.
    """
    return await get_transaction(db, current_user, transaction_id)
