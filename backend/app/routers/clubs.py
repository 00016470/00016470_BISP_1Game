from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.club import ClubResponse
from app.schemas.slot import SlotResponse
from app.services.club_service import get_club, list_clubs
from app.services.slot_service import get_slots

router = APIRouter(prefix="/api/clubs", tags=["clubs"])


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


@router.get("/{club_id}/slots", response_model=list[SlotResponse])
async def get_slots_endpoint(
    club_id: int,
    date: date = Query(..., description="Date in YYYY-MM-DD format"),
    db: AsyncSession = Depends(get_db),
):
    return await get_slots(db, club_id, date)
