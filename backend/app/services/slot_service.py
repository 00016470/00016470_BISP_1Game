from datetime import date, datetime, timedelta, timezone

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.booking import Booking, BookingStatus
from app.models.club import Club
from app.schemas.slot import SlotResponse
from app.services.club_service import get_club_or_404


async def get_slots(db: AsyncSession, club_id: int, slot_date: date) -> list[SlotResponse]:
    club = await get_club_or_404(db, club_id)

    slots: list[SlotResponse] = []

    for hour in range(club.opening_hour, club.closing_hour):
        slot_start = datetime(
            slot_date.year, slot_date.month, slot_date.day, hour, 0, 0, tzinfo=timezone.utc
        )
        slot_end = slot_start + timedelta(hours=1)

        # Fetch ACTIVE bookings whose start_time falls within a broad window.
        # Broad filter: start_time < slot_end AND start_time >= slot_start - 24h (max session)
        # Then filter precisely in Python: booking_end > slot_start AND booking.start_time < slot_end
        result = await db.execute(
            select(Booking).where(
                and_(
                    Booking.club_id == club_id,
                    Booking.status == BookingStatus.ACTIVE,
                    Booking.start_time < slot_end,
                    Booking.start_time >= slot_start - timedelta(hours=24),
                )
            )
        )
        candidates = result.scalars().all()

        booked = 0
        for b in candidates:
            b_start = b.start_time
            if b_start.tzinfo is None:
                b_start = b_start.replace(tzinfo=timezone.utc)
            b_end = b_start + timedelta(hours=b.duration_hours)
            # Overlap: b_start < slot_end AND b_end > slot_start
            if b_start < slot_end and b_end > slot_start:
                booked += b.computers_booked

        available = max(0, club.total_computers - booked)
        slots.append(
            SlotResponse(
                **{
                    "time": slot_start.strftime("%H:%M"),
                    "availableComputers": available,
                }
            )
        )

    return slots
