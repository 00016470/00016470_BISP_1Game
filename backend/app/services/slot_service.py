from datetime import date, datetime, timedelta, timezone

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.booking import Booking, BookingStatus
from app.schemas.slot import SlotResponse
from app.services.club_service import get_club_or_404


# Tashkent is UTC+5
_TASHKENT_TZ = timezone(timedelta(hours=5))


async def get_slots(db: AsyncSession, club_id: int, slot_date: date) -> list[SlotResponse]:
    club = await get_club_or_404(db, club_id)

    # Club hours are in local Tashkent time, so compare against local now
    now_local = datetime.now(_TASHKENT_TZ).replace(tzinfo=None)
    slots: list[SlotResponse] = []

    for hour in range(club.opening_hour, club.closing_hour):
        slot_start = datetime(
            slot_date.year, slot_date.month, slot_date.day, hour, 0, 0, tzinfo=timezone.utc
        )
        slot_end = slot_start + timedelta(hours=1)

        # Skip slots whose local time is in the past
        slot_local = datetime(slot_date.year, slot_date.month, slot_date.day, hour, 0, 0)
        if slot_local <= now_local:
            slots.append(
                SlotResponse(
                    id=hour,
                    start_time=slot_start.strftime("%H:%M"),
                    end_time=slot_end.strftime("%H:%M"),
                    total_computers=club.total_computers,
                    available_computers=0,
                    is_available=False,
                )
            )
            continue

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
            if b_start < slot_end and b_end > slot_start:
                booked += b.computers_booked

        available = max(0, club.total_computers - booked)
        slots.append(
            SlotResponse(
                id=hour,
                start_time=slot_start.strftime("%H:%M"),
                end_time=slot_end.strftime("%H:%M"),
                total_computers=club.total_computers,
                available_computers=available,
                is_available=available > 0,
            )
        )

    return slots
