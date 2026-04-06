from datetime import datetime, timedelta, timezone

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import ConflictError, ForbiddenError, NotFoundError, ValidationError
from app.models.booking import Booking, BookingStatus
from app.models.club import Club
from app.models.user import User
from app.schemas.booking import BookingCreate, BookingResponse
from app.services.club_service import get_club_or_404

_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def _booking_end_time(booking: Booking) -> datetime:
    """Return tz-aware end time for a booking."""
    st = booking.start_time
    if st.tzinfo is None:
        st = st.replace(tzinfo=timezone.utc)
    return st + timedelta(hours=booking.duration_hours)


def _to_response(booking: Booking, club: Club) -> BookingResponse:
    st = booking.start_time
    if st.tzinfo is None:
        st = st.replace(tzinfo=timezone.utc)
    end_time = st + timedelta(hours=booking.duration_hours)
    total_price = float(club.price_per_hour * booking.computers_booked * booking.duration_hours)
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
        status=booking.status.value,
        created_at=booking.created_at,
    )


async def create_booking(db: AsyncSession, user: User, data: BookingCreate) -> BookingResponse:
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

    result = await db.execute(
        select(Booking)
        .where(
            and_(
                Booking.club_id == data.club_id,
                Booking.status == BookingStatus.ACTIVE,
                Booking.start_time < end,
                Booking.start_time >= start - timedelta(hours=24),
            )
        )
        .with_for_update(skip_locked=True)
    )
    candidates = result.scalars().all()

    booked = sum(
        b.computers_booked
        for b in candidates
        if _booking_end_time(b) > start
    )
    if booked + data.computers_booked > club.total_computers:
        raise ConflictError(
            f"Only {club.total_computers - booked} computers available for the requested time slot"
        )

    booking = Booking(
        user_id=user.id,
        club_id=data.club_id,
        start_time=start,
        duration_hours=data.duration_hours,
        computers_booked=data.computers_booked,
        status=BookingStatus.ACTIVE,
    )
    db.add(booking)
    await db.flush()

    return _to_response(booking, club)


async def list_user_bookings(db: AsyncSession, user: User) -> list[BookingResponse]:
    result = await db.execute(
        select(Booking, Club)
        .join(Club, Booking.club_id == Club.id)
        .where(Booking.user_id == user.id)
        .order_by(Booking.start_time.desc())
    )
    rows = result.all()
    return [_to_response(b, c) for b, c in rows]


async def get_booking(db: AsyncSession, user: User, booking_id: int) -> BookingResponse:
    result = await db.execute(
        select(Booking, Club)
        .join(Club, Booking.club_id == Club.id)
        .where(and_(Booking.id == booking_id, Booking.user_id == user.id))
    )
    row = result.one_or_none()
    if not row:
        raise NotFoundError("Booking")
    return _to_response(row[0], row[1])


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
    return _to_response(booking, club)
