import random
import string
import logging
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import NotFoundError, ValidationError
from app.models.transaction import Transaction, TransactionStatus, TransactionType
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.wallet import TopUpResponse, WalletResponse

logger = logging.getLogger("app.wallet")


def _generate_ref() -> str:
    now = datetime.now(timezone.utc)
    suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
    return f"TXN-{now.strftime('%Y%m%d')}-{suffix}"


async def get_or_create_wallet(db: AsyncSession, user: User) -> Wallet:
    result = await db.execute(select(Wallet).where(Wallet.user_id == user.id))
    wallet = result.scalar_one_or_none()
    if wallet is None:
        wallet = Wallet(user_id=user.id, balance=0.00, currency="UZS")
        db.add(wallet)
        await db.flush()
    return wallet


async def get_wallet(db: AsyncSession, user: User) -> WalletResponse:
    wallet = await get_or_create_wallet(db, user)
    await db.commit()
    logger.info("get_wallet: user=%s, balance=%s", user.id, float(wallet.balance))
    return WalletResponse.model_validate(wallet)


async def top_up_wallet(db: AsyncSession, user: User, amount: float) -> TopUpResponse:
    if amount <= 0:
        raise ValidationError("Top-up amount must be positive")

    wallet = await get_or_create_wallet(db, user)

    balance_before = float(wallet.balance)
    balance_after = balance_before + amount
    wallet.balance = balance_after
    wallet.updated_at = datetime.now(timezone.utc)
    await db.flush()

    ref = _generate_ref()
    txn = Transaction(
        wallet_id=wallet.id,
        user_id=user.id,
        booking_id=None,
        type=TransactionType.TOP_UP,
        amount=amount,
        balance_before=balance_before,
        balance_after=balance_after,
        status=TransactionStatus.COMPLETED,
        description=f"Wallet top-up of {amount:,.0f} UZS",
        reference_code=ref,
    )
    db.add(txn)
    await db.flush()
    await db.commit()

    return TopUpResponse(
        wallet=WalletResponse.model_validate(wallet),
        transaction_id=txn.id,
        reference_code=ref,
    )


async def deduct_wallet(
    db: AsyncSession,
    wallet: Wallet,
    user: User,
    amount: float,
    booking_id: int,
    description: str,
) -> Transaction:
    """Deduct from wallet atomically. Caller is responsible for committing the transaction."""
    balance_before = float(wallet.balance)
    if balance_before < amount:
        raise ValidationError(
            f"Insufficient wallet balance. Balance: {balance_before:,.0f} UZS, "
            f"Required: {amount:,.0f} UZS"
        )

    wallet.balance = balance_before - amount
    wallet.updated_at = datetime.now(timezone.utc)
    await db.flush()

    ref = _generate_ref()
    txn = Transaction(
        wallet_id=wallet.id,
        user_id=user.id,
        booking_id=booking_id,
        type=TransactionType.BOOKING_PAYMENT,
        amount=amount,
        balance_before=balance_before,
        balance_after=float(wallet.balance),
        status=TransactionStatus.COMPLETED,
        description=description,
        reference_code=ref,
    )
    db.add(txn)
    await db.flush()
    return txn


async def refund_wallet(
    db: AsyncSession,
    wallet: Wallet,
    user: User,
    amount: float,
    booking_id: int,
    description: str,
) -> Transaction:
    """Refund amount to wallet atomically."""
    balance_before = float(wallet.balance)
    wallet.balance = balance_before + amount
    wallet.updated_at = datetime.now(timezone.utc)
    await db.flush()

    ref = _generate_ref()
    txn = Transaction(
        wallet_id=wallet.id,
        user_id=user.id,
        booking_id=booking_id,
        type=TransactionType.REFUND,
        amount=amount,
        balance_before=balance_before,
        balance_after=float(wallet.balance),
        status=TransactionStatus.COMPLETED,
        description=description,
        reference_code=ref,
    )
    db.add(txn)
    await db.flush()
    return txn
