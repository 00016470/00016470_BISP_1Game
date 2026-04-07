from datetime import date, datetime, timezone
from typing import Literal, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.booking import Booking, BookingStatus
from app.models.club import Club
from app.dependencies import get_current_admin
from app.models.user import User
from app.schemas.club import ClubCreateRequest, ClubMapResponse, ClubResponse, ClubUpdateRequest
from app.schemas.slot import SlotResponse
from app.services.club_service import create_club, get_club, list_clubs, update_club
from app.services.slot_service import get_slots

router = APIRouter(prefix="/api/clubs", tags=["clubs"])


@router.get("/map", response_model=list[ClubMapResponse])
async def clubs_map_endpoint(
    available_now: bool = Query(False),
    search: Optional[str] = Query(None, max_length=200),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Club))
    clubs = result.scalars().all()

    now = datetime.now(timezone.utc)
    output = []
    for club in clubs:
        if search and search.lower() not in club.name.lower():
            continue

        # Count booked computers right now
        active_result = await db.execute(
            select(Booking).where(
                and_(
                    Booking.club_id == club.id,
                    Booking.status == BookingStatus.ACTIVE,
                    Booking.start_time <= now,
                )
            )
        )
        active_bookings = active_result.scalars().all()
        from datetime import timedelta
        booked = sum(
            b.computers_booked for b in active_bookings
            if (b.start_time.replace(tzinfo=timezone.utc) + timedelta(hours=b.duration_hours)) > now
        )
        available = max(0, club.total_computers - booked)

        if available_now and available == 0:
            continue

        output.append(
            ClubMapResponse(
                id=club.id,
                name=club.name,
                location=club.location,
                address=club.address,
                latitude=float(club.latitude) if club.latitude else None,
                longitude=float(club.longitude) if club.longitude else None,
                rating=club.rating,
                price_per_hour=club.price_per_hour,
                total_computers=club.total_computers,
                available_computers=available,
                opening_hour=club.opening_hour,
                closing_hour=club.closing_hour,
                image_url=club.image_url,
            )
        )
    return output


@router.get("", response_model=list[ClubResponse])
async def list_clubs_endpoint(
    search: str | None = Query(default=None, max_length=200),
    sortBy: Literal["rating", "price"] | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    return await list_clubs(db, search=search, sort_by=sortBy)


@router.get("/{club_id}", response_model=ClubResponse)
async def get_club_endpoint(club_id: int, db: AsyncSession = Depends(get_db)):
    return await get_club(db, club_id)


@router.post("", response_model=ClubResponse, status_code=201)
async def create_club_endpoint(
    data: ClubCreateRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await create_club(db, data)


@router.put("/{club_id}", response_model=ClubResponse)
async def update_club_endpoint(
    club_id: int,
    data: ClubUpdateRequest,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(get_current_admin),
):
    return await update_club(db, club_id, data)


@router.get("/{club_id}/slots", response_model=list[SlotResponse])
async def get_slots_endpoint(
    club_id: int,
    date: date = Query(..., description="Date in YYYY-MM-DD format"),
    db: AsyncSession = Depends(get_db),
):
    return await get_slots(db, club_id, date)
