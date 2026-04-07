from datetime import datetime, timedelta, timezone
import logging

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import ConflictError, ForbiddenError, NotFoundError, ValidationError
from app.models.booking import Booking, BookingStatus
from app.models.club import Club
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from app.models.transaction import Transaction, TransactionStatus, TransactionType
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.booking import (
    BookingCreate,
    BookingResponse,
    MultiSlotBookingCreate,
    MultiSlotBookingResponse,
)
from app.services.club_service import get_club_or_404
from app.services.wallet_service import deduct_wallet, get_or_create_wallet

logger = logging.getLogger("app.booking")

_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def _booking_end_time(booking: Booking) -> datetime:
    st = booking.start_time
    if st.tzinfo is None:
        st = st.replace(tzinfo=timezone.utc)
    return st + timedelta(hours=booking.duration_hours)


def _to_response(booking: Booking, club: Club, payment: Payment | None = None) -> BookingResponse:
    st = booking.start_time
    if st.tzinfo is None:
        st = st.replace(tzinfo=timezone.utc)
    end_time = st + timedelta(hours=booking.duration_hours)
    total_price = float(booking.total_price) if booking.total_price else float(
        club.price_per_hour * booking.computers_booked * booking.duration_hours
    )
    date_str = f"{_MONTHS[st.month - 1]} {st.day:02d}, {st.year}"
    return BookingResponse(
        id=booking.id,
        user_id=booking.user_id,
        club_id=booking.club_id,
        club_name=club.name,
        club_location=club.location,
        start_time=booking.start_time,
        end_time=end_time,
        date=date_str,
        duration_hours=booking.duration_hours,
        computers_booked=booking.computers_booked,
        computers_count=booking.computers_booked,
        total_price=total_price,
        payment_id=booking.payment_id,
        payment_status=payment.status.value if payment else None,
        payment_method=payment.method.value if payment else None,
        slot_details=booking.slot_details,
        status=booking.status.value,
        created_at=booking.created_at,
    )


async def _check_slot_availability(
    db: AsyncSession,
    club: Club,
    start: datetime,
    end: datetime,
    computers_needed: int,
) -> None:
    """Raises ConflictError if not enough computers available for the time window."""
    result = await db.execute(
        select(Booking)
        .where(
            and_(
                Booking.club_id == club.id,
                Booking.status == BookingStatus.ACTIVE,
                Booking.start_time < end,
                Booking.start_time >= start - timedelta(hours=24),
            )
        )
        .with_for_update(skip_locked=True)
    )
    candidates = result.scalars().all()
    booked = sum(b.computers_booked for b in candidates if _booking_end_time(b) > start)
    if booked + computers_needed > club.total_computers:
        raise ConflictError(
            f"Only {club.total_computers - booked} computers available for "
            f"{start.strftime('%H:%M')}-{end.strftime('%H:%M')}"
        )


async def create_booking(db: AsyncSession, user: User, data: BookingCreate) -> BookingResponse:
    logger.info("create_booking called: user=%s, club_id=%s, payment_method=%s, data=%s",
                user.id, data.club_id, data.payment_method, data.model_dump())
    club = await get_club_or_404(db, data.club_id)

    start = data.start_time
    if start.tzinfo is None:
        start = start.replace(tzinfo=timezone.utc)
    else:
        start = start.astimezone(timezone.utc)

    now = datetime.now(timezone.utc)
    if start <= now:
        raise ValidationError("Booking start time must be in the future")

    end = start + timedelta(hours=data.duration_hours)

    if start.hour < club.opening_hour or end.hour > club.closing_hour or (
        end.hour == club.closing_hour and end.minute > 0
    ):
        raise ValidationError("Booking is outside club operating hours")

    await _check_slot_availability(db, club, start, end, data.computers_booked)

    total_price = float(club.price_per_hour * data.computers_booked * data.duration_hours)
    booking = Booking(
        user_id=user.id,
        club_id=data.club_id,
        start_time=start,
        duration_hours=data.duration_hours,
        computers_booked=data.computers_booked,
        status=BookingStatus.ACTIVE,
        total_price=total_price,
    )
    db.add(booking)
    await db.flush()

    # ── Process payment ──
    pay_method = PaymentMethod(data.payment_method)
    txn_id: int | None = None
    logger.info("Processing payment: booking_id=%s, method=%s, total_price=%s",
                booking.id, pay_method, total_price)

    if pay_method == PaymentMethod.WALLET:
        wallet = await get_or_create_wallet(db, user)
        logger.info("Wallet balance BEFORE deduct: %s", float(wallet.balance))
        txn = await deduct_wallet(
            db, wallet, user, total_price, booking.id,
            f"Booking #{booking.id} at {club.name}"
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
        import random, string
        ref_code = "TXN-" + now.strftime("%Y%m%d") + "-" + "".join(
            random.choices(string.ascii_uppercase + string.digits, k=4)
        )
        wallet = await get_or_create_wallet(db, user)
        txn = Transaction(
            wallet_id=wallet.id,
            user_id=user.id,
            booking_id=booking.id,
            type=TransactionType.BOOKING_PAYMENT,
            amount=total_price,
            balance_before=float(wallet.balance),
            balance_after=float(wallet.balance),
            status=TransactionStatus.COMPLETED,
            description=f"Booking #{booking.id} at {club.name} via card",
            reference_code=ref_code,
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
    logger.info("Booking committed: id=%s, payment_id=%s, method=%s, status=%s",
                booking.id, payment.id, payment.method, payment.status)

    return _to_response(booking, club, payment)


async def create_multi_slot_booking(
    db: AsyncSession, user: User, data: MultiSlotBookingCreate
) -> MultiSlotBookingResponse:
    club = await get_club_or_404(db, data.club_id)
    now = datetime.now(timezone.utc)

    # Normalise & validate all slots
    slots_norm = []
    for slot in data.slots:
        start = slot.start_time
        if start.tzinfo is None:
            start = start.replace(tzinfo=timezone.utc)
        else:
            start = start.astimezone(timezone.utc)

        if start <= now:
            raise ValidationError("All slot start times must be in the future")

        end = start + timedelta(hours=slot.duration_hours)
        if start.hour < club.opening_hour or end.hour > club.closing_hour or (
            end.hour == club.closing_hour and end.minute > 0
        ):
            raise ValidationError(
                f"Slot {start.strftime('%H:%M')} is outside club operating hours"
            )
        slots_norm.append((start, end, slot.duration_hours))

    # Check all slots atomically
    for start, end, _ in slots_norm:
        await _check_slot_availability(db, club, start, end, data.computers_booked)

    # Use first slot as main booking record
    first_start, first_end, first_dur = slots_norm[0]
    total_duration = sum(d for _, _, d in slots_norm)
    total_price = float(club.price_per_hour * data.computers_booked * total_duration)

    slot_details = {
        "slots": [
            {"start_time": s.isoformat(), "end_time": e.isoformat(), "duration_hours": d}
            for s, e, d in slots_norm
        ]
    }

    booking = Booking(
        user_id=user.id,
        club_id=data.club_id,
        start_time=first_start,
        duration_hours=total_duration,
        computers_booked=data.computers_booked,
        status=BookingStatus.ACTIVE,
        total_price=total_price,
        slot_details=slot_details,
    )
    db.add(booking)
    await db.flush()

    # Process payment
    pay_method = PaymentMethod(data.payment_method)
    txn_id: int | None = None
    ref_code: str | None = None

    if pay_method == PaymentMethod.WALLET:
        wallet = await get_or_create_wallet(db, user)
        txn = await deduct_wallet(
            db, wallet, user, total_price, booking.id,
            f"Multi-slot booking #{booking.id} at {club.name}"
        )
        txn_id = txn.id
        ref_code = txn.reference_code
        payment = Payment(
            user_id=user.id,
            booking_id=booking.id,
            transaction_id=txn_id,
            amount=total_price,
            method=pay_method,
            status=PaymentStatus.COMPLETED,
        )
        payment_status = PaymentStatus.COMPLETED.value

    elif pay_method == PaymentMethod.CARD:
        import random, string
        ref_code = "TXN-" + now.strftime("%Y%m%d") + "-" + "".join(
            random.choices(string.ascii_uppercase + string.digits, k=4)
        )
        wallet_result = await db.execute(
            select(Wallet).where(Wallet.user_id == user.id)
        )
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
            description=f"Multi-slot booking #{booking.id} at {club.name} via card",
            reference_code=ref_code,
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
        payment_status = PaymentStatus.COMPLETED.value

    else:  # CASH
        payment = Payment(
            user_id=user.id,
            booking_id=booking.id,
            transaction_id=None,
            amount=total_price,
            method=pay_method,
            status=PaymentStatus.PENDING,
        )
        payment_status = PaymentStatus.PENDING.value

    db.add(payment)
    await db.flush()
    booking.payment_id = payment.id
    await db.flush()
    await db.commit()

    return MultiSlotBookingResponse(
        booking=_to_response(booking, club, payment),
        payment_id=payment.id,
        payment_status=payment_status,
        payment_method=pay_method.value,
        transaction_id=txn_id,
        reference_code=ref_code,
        total_price=total_price,
    )


async def list_user_bookings(db: AsyncSession, user: User) -> list[BookingResponse]:
    result = await db.execute(
        select(Booking, Club, Payment)
        .join(Club, Booking.club_id == Club.id)
        .outerjoin(Payment, Booking.payment_id == Payment.id)
        .where(Booking.user_id == user.id)
        .order_by(Booking.start_time.desc())
    )
    rows = result.all()
    return [_to_response(b, c, p) for b, c, p in rows]


async def get_booking(db: AsyncSession, user: User, booking_id: int) -> BookingResponse:
    result = await db.execute(
        select(Booking, Club, Payment)
        .join(Club, Booking.club_id == Club.id)
        .outerjoin(Payment, Booking.payment_id == Payment.id)
        .where(and_(Booking.id == booking_id, Booking.user_id == user.id))
    )
    row = result.one_or_none()
    if not row:
        raise NotFoundError("Booking")
    return _to_response(row[0], row[1], row[2])


async def cancel_booking(db: AsyncSession, user: User, booking_id: int) -> BookingResponse:
    result = await db.execute(
        select(Booking, Club)
        .join(Club, Booking.club_id == Club.id)
        .where(and_(Booking.id == booking_id, Booking.user_id == user.id))
        .with_for_update()
    )
    row = result.one_or_none()
    if not row:
        raise NotFoundError("Booking")

    booking, club = row[0], row[1]

    if booking.status != BookingStatus.ACTIVE:
        raise ValidationError(f"Cannot cancel a booking with status {booking.status.value}")

    now = datetime.now(timezone.utc)
    start = booking.start_time
    if start.tzinfo is None:
        start = start.replace(tzinfo=timezone.utc)
    else:
        start = start.astimezone(timezone.utc)

    if start <= now:
        raise ValidationError("Cannot cancel a booking that has already started or passed")

    booking.status = BookingStatus.CANCELLED

    # Load associated payment
    payment: Payment | None = None
    if booking.payment_id:
        pay_result = await db.execute(
            select(Payment).where(Payment.id == booking.payment_id).with_for_update()
        )
        payment = pay_result.scalar_one_or_none()

    # Refund logic
    if payment:
        if payment.method == PaymentMethod.WALLET and payment.status == PaymentStatus.COMPLETED:
            # Auto-refund to wallet
            from app.services.wallet_service import refund_wallet
            wallet_result = await db.execute(
                select(Wallet).where(Wallet.user_id == user.id).with_for_update()
            )
            wallet = wallet_result.scalar_one_or_none()
            if wallet:
                await refund_wallet(
                    db, wallet, user, float(payment.amount), booking.id,
                    f"Refund for cancelled booking #{booking.id} at {club.name}"
                )
                payment.status = PaymentStatus.REFUNDED

        elif payment.method == PaymentMethod.CARD and payment.status == PaymentStatus.COMPLETED:
            payment.status = PaymentStatus.REFUNDED

        elif payment.method == PaymentMethod.CASH and payment.status == PaymentStatus.PENDING:
            payment.status = PaymentStatus.FAILED

    await db.commit()
    return _to_response(booking, club, payment)
