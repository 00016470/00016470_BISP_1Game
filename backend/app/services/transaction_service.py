import math
from datetime import datetime
from typing import Optional

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import NotFoundError
from app.models.transaction import Transaction, TransactionType
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.transaction import (
    TransactionListResponse,
    TransactionResponse,
    TransactionSummary,
)


async def list_transactions(
    db: AsyncSession,
    user: User,
    type_filter: Optional[str] = None,
    status_filter: Optional[str] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    page: int = 1,
    per_page: int = 20,
) -> TransactionListResponse:
    q = select(Transaction).where(Transaction.user_id == user.id)

    if type_filter:
        q = q.where(Transaction.type == type_filter)
    if status_filter:
        q = q.where(Transaction.status == status_filter)
    if from_date:
        q = q.where(Transaction.created_at >= from_date)
    if to_date:
        q = q.where(Transaction.created_at <= to_date)

    count_result = await db.execute(select(func.count()).select_from(q.subquery()))
    total = count_result.scalar_one()

    q = q.order_by(Transaction.created_at.desc())
    q = q.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(q)
    items = result.scalars().all()

    return TransactionListResponse(
        items=[TransactionResponse.model_validate(t) for t in items],
        total=total,
        page=page,
        per_page=per_page,
        pages=math.ceil(total / per_page) if total > 0 else 1,
    )


async def get_transaction(db: AsyncSession, user: User, txn_id: int) -> TransactionResponse:
    result = await db.execute(
        select(Transaction).where(
            and_(Transaction.id == txn_id, Transaction.user_id == user.id)
        )
    )
    txn = result.scalar_one_or_none()
    if not txn:
        raise NotFoundError("Transaction")
    return TransactionResponse.model_validate(txn)


async def get_transaction_summary(db: AsyncSession, user: User) -> TransactionSummary:
    result = await db.execute(
        select(Transaction).where(Transaction.user_id == user.id)
    )
    txns = result.scalars().all()

    total_spent = sum(
        float(t.amount)
        for t in txns
        if t.type == TransactionType.BOOKING_PAYMENT
    )
    total_top_ups = sum(
        float(t.amount)
        for t in txns
        if t.type == TransactionType.TOP_UP
    )
    total_refunds = sum(
        float(t.amount)
        for t in txns
        if t.type == TransactionType.REFUND
    )

    # Get current balance
    wallet_result = await db.execute(
        select(Wallet).where(Wallet.user_id == user.id)
    )
    wallet = wallet_result.scalar_one_or_none()
    current_balance = float(wallet.balance) if wallet else 0.0

    return TransactionSummary(
        total_spent=total_spent,
        total_top_ups=total_top_ups,
        total_refunds=total_refunds,
        current_balance=current_balance,
        transaction_count=len(txns),
    )
