import asyncio
import random
import string
from datetime import datetime, timezone

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import ForbiddenError, NotFoundError, ValidationError
from app.models.booking import Booking, BookingStatus
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from app.models.transaction import Transaction, TransactionStatus, TransactionType
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.payment import PaymentResponse, PaymentValidateResponse
from app.services.wallet_service import deduct_wallet, get_or_create_wallet, refund_wallet


def _generate_ref() -> str:
    now = datetime.now(timezone.utc)
    suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
    return f"TXN-{now.strftime('%Y%m%d')}-{suffix}"


async def process_payment(
    db: AsyncSession, user: User, booking_id: int, method: str
) -> PaymentResponse:
    # Load booking with lock
    result = await db.execute(
        select(Booking).where(
            and_(Booking.id == booking_id, Booking.user_id == user.id)
        ).with_for_update()
    )
    booking = result.scalar_one_or_none()
    if not booking:
        raise NotFoundError("Booking")

    if booking.status != BookingStatus.ACTIVE:
        raise ValidationError("Can only pay for ACTIVE bookings")

    # Check if already paid
    existing_result = await db.execute(
        select(Payment).where(
            and_(
                Payment.booking_id == booking_id,
                Payment.status.in_([PaymentStatus.COMPLETED, PaymentStatus.PENDING]),
            )
        )
    )
    if existing_result.scalar_one_or_none():
        raise ValidationError("Payment already exists for this booking")

    total_price = float(booking.total_price) if booking.total_price else 0.0

    pay_method = PaymentMethod(method)
    txn_id: int | None = None

    if pay_method == PaymentMethod.WALLET:
        wallet = await get_or_create_wallet(db, user)
        txn = await deduct_wallet(
            db, wallet, user, total_price, booking.id,
            f"Booking #{booking.id} payment via wallet"
        )
        txn_id = txn.id
        payment = Payment(
            user_id=user.id,
            booking_id=booking.id,
            transaction_id=txn_id,
            amount=total_price,
            method=pay_method,
            status=PaymentStatus.COMPLETED,
        )

    elif pay_method == PaymentMethod.CARD:
        # Simulate card processing
        ref = _generate_ref()
        wallet_result = await db.execute(select(Wallet).where(Wallet.user_id == user.id))
        wallet = wallet_result.scalar_one_or_none()
        if wallet is None:
            wallet = Wallet(user_id=user.id, balance=0.00, currency="UZS")
            db.add(wallet)
            await db.flush()

        txn = Transaction(
            wallet_id=wallet.id,
            user_id=user.id,
            booking_id=booking.id,
            type=TransactionType.BOOKING_PAYMENT,
            amount=total_price,
            balance_before=float(wallet.balance),
            balance_after=float(wallet.balance),
            status=TransactionStatus.COMPLETED,
            description=f"Booking #{booking.id} payment via card",
            reference_code=ref,
        )
        db.add(txn)
        await db.flush()
        txn_id = txn.id
        payment = Payment(
            user_id=user.id,
            booking_id=booking.id,
            transaction_id=txn_id,
            amount=total_price,
            method=pay_method,
            status=PaymentStatus.COMPLETED,
        )

    else:  # CASH
        payment = Payment(
            user_id=user.id,
            booking_id=booking.id,
            transaction_id=None,
            amount=total_price,
            method=pay_method,
            status=PaymentStatus.PENDING,
        )

    db.add(payment)
    await db.flush()

    booking.payment_id = payment.id
    await db.flush()
    await db.commit()

    return PaymentResponse.model_validate(payment)


async def get_payment(db: AsyncSession, user: User, payment_id: int) -> PaymentResponse:
    result = await db.execute(
        select(Payment).where(
            and_(Payment.id == payment_id, Payment.user_id == user.id)
        )
    )
    payment = result.scalar_one_or_none()
    if not payment:
        raise NotFoundError("Payment")
    return PaymentResponse.model_validate(payment)


async def validate_cash_payment(
    db: AsyncSession, admin_user: User, payment_id: int
) -> PaymentValidateResponse:
    result = await db.execute(
        select(Payment).where(Payment.id == payment_id).with_for_update()
    )
    payment = result.scalar_one_or_none()
    if not payment:
        raise NotFoundError("Payment")

    if payment.method != PaymentMethod.CASH:
        raise ValidationError("Can only validate CASH payments")

    if payment.status != PaymentStatus.PENDING:
        raise ValidationError(f"Payment is already {payment.status.value}")

    payment.status = PaymentStatus.COMPLETED
    payment.validated_by = admin_user.id
    payment.validated_at = datetime.now(timezone.utc)
    await db.commit()

    return PaymentValidateResponse(
        id=payment.id,
        status=payment.status.value,
        validated_by=admin_user.id,
        validated_at=payment.validated_at,
    )
