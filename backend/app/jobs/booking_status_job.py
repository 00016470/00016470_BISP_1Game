import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.booking import Booking, BookingStatus

logger = logging.getLogger("app.jobs")


async def update_booking_statuses() -> None:
    """
    Mark bookings as:
    - COMPLETED  when end_time (start_time + duration) has passed
    - EXPIRED    when start_time passed by more than 30 min and booking is still ACTIVE
      but end_time has NOT yet passed (i.e., no check-in occurred)
    """
    now = datetime.now(timezone.utc)
    async with AsyncSessionLocal() as session:
        try:
            await _mark_completed(session, now)
            await _mark_expired(session, now)
            await session.commit()
            logger.info("Booking status job finished at %s", now.isoformat())
        except Exception as exc:
            await session.rollback()
            logger.exception("Booking status job failed: %s", exc)


async def _mark_completed(session: AsyncSession, now: datetime) -> None:
    # Load ACTIVE bookings whose potential end time could have passed
    # Broad filter: start_time <= now (end_time definitely <= now if duration is small)
    result = await session.execute(
        select(Booking).where(
            and_(
                Booking.status == BookingStatus.ACTIVE,
                Booking.start_time <= now,
            )
        )
    )
    bookings = result.scalars().all()
    completed = []
    for booking in bookings:
        st = booking.start_time
        if st.tzinfo is None:
            st = st.replace(tzinfo=timezone.utc)
        end_time = st + timedelta(hours=booking.duration_hours)
        if end_time <= now:
            booking.status = BookingStatus.COMPLETED
            completed.append(booking)
    if completed:
        logger.info("Marked %d bookings as COMPLETED", len(completed))


async def _mark_expired(session: AsyncSession, now: datetime) -> None:
    grace = timedelta(minutes=30)
    result = await session.execute(
        select(Booking).where(
            and_(
                Booking.status == BookingStatus.ACTIVE,
                Booking.start_time <= now - grace,
            )
        )
    )
    bookings = result.scalars().all()
    expired = []
    for booking in bookings:
        st = booking.start_time
        if st.tzinfo is None:
            st = st.replace(tzinfo=timezone.utc)
        end_time = st + timedelta(hours=booking.duration_hours)
        # Still ACTIVE past grace period but NOT yet past end_time → EXPIRED
        if end_time > now:
            booking.status = BookingStatus.EXPIRED
            expired.append(booking)
    if expired:
        logger.info("Marked %d bookings as EXPIRED", len(expired))
