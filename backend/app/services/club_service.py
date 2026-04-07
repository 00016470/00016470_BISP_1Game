from typing import Literal

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import NotFoundError
from app.models.club import Club
from app.schemas.club import ClubCreateRequest, ClubResponse, ClubUpdateRequest


async def list_clubs(
    db: AsyncSession,
    search: str | None = None,
    sort_by: Literal["rating", "price"] | None = None,
) -> list[ClubResponse]:
    stmt = select(Club)

    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(or_(Club.name.ilike(pattern), Club.location.ilike(pattern)))

    if sort_by == "rating":
        stmt = stmt.order_by(Club.rating.desc())
    elif sort_by == "price":
        stmt = stmt.order_by(Club.price_per_hour.asc())
    else:
        stmt = stmt.order_by(Club.id.asc())

    result = await db.execute(stmt)
    clubs = result.scalars().all()
    return [ClubResponse.model_validate(c) for c in clubs]


async def get_club(db: AsyncSession, club_id: int) -> ClubResponse:
    result = await db.execute(select(Club).where(Club.id == club_id))
    club = result.scalar_one_or_none()
    if not club:
        raise NotFoundError("Club")
    return ClubResponse.model_validate(club)


async def get_club_or_404(db: AsyncSession, club_id: int) -> Club:
    result = await db.execute(select(Club).where(Club.id == club_id))
    club = result.scalar_one_or_none()
    if not club:
        raise NotFoundError("Club")
    return club


async def create_club(db: AsyncSession, data: ClubCreateRequest) -> ClubResponse:
    club = Club(
        name=data.name,
        location=data.location,
        description=data.description,
        price_per_hour=data.price_per_hour,
        total_computers=data.total_computers,
        opening_hour=data.opening_hour,
        closing_hour=data.closing_hour,
        image_url=data.image_url,
        latitude=data.latitude,
        longitude=data.longitude,
        address=data.address,
    )
    db.add(club)
    await db.flush()
    await db.refresh(club)
    return ClubResponse.model_validate(club)


async def update_club(db: AsyncSession, club_id: int, data: ClubUpdateRequest) -> ClubResponse:
    club = await get_club_or_404(db, club_id)
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(club, field, value)
    await db.flush()
    await db.refresh(club)
    return ClubResponse.model_validate(club)
