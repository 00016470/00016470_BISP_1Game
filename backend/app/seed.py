import logging
from datetime import datetime, timezone, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.club import Club
from app.models.user import User
from app.models.booking import Booking, BookingStatus
from app.models.refresh_token import RefreshToken  # noqa: F401 – required to resolve ORM relationships

logger = logging.getLogger("app.seed")

SEED_CLUBS = [
    {
        "name": "Cyber Arena",
        "location": "Chilanzar district, Tashkent",
        "total_computers": 20,
        "image_url": None,
        "rating": 4.8,
        "price_per_hour": 15000,
        "opening_hour": 9,
        "closing_hour": 23,
    },
    {
        "name": "FragZone",
        "location": "Yunusabad district, Tashkent",
        "total_computers": 15,
        "image_url": None,
        "rating": 4.6,
        "price_per_hour": 12000,
        "opening_hour": 10,
        "closing_hour": 24,
    },
    {
        "name": "NeoPlay Hub",
        "location": "Mirzo Ulugbek district, Tashkent",
        "total_computers": 25,
        "image_url": None,
        "rating": 4.9,
        "price_per_hour": 18000,
        "opening_hour": 8,
        "closing_hour": 23,
    },
    {
        "name": "Pixel Vault",
        "location": "Shaykhantahur district, Tashkent",
        "total_computers": 12,
        "image_url": None,
        "rating": 4.5,
        "price_per_hour": 10000,
        "opening_hour": 10,
        "closing_hour": 22,
    },
    {
        "name": "LAN Lords",
        "location": "Yashnabad district, Tashkent",
        "total_computers": 30,
        "image_url": None,
        "rating": 4.7,
        "price_per_hour": 14000,
        "opening_hour": 9,
        "closing_hour": 24,
    },
    {
        "name": "GamersPit",
        "location": "Bektemir district, Tashkent",
        "total_computers": 18,
        "image_url": None,
        "rating": 4.4,
        "price_per_hour": 11000,
        "opening_hour": 11,
        "closing_hour": 23,
    },
]

DEMO_USERS = [
    {
        "username": "demo_user",
        "email": "demo@gaming.uz",
        "password": "demo123",
        "phone": "+998901234567",
    },
    {
        "username": "gamer_pro",
        "email": "gamer@gaming.uz",
        "password": "gamer123",
        "phone": "+998907654321",
    },
]


def _dt(days_offset: int, hour: int) -> datetime:
    """Return a UTC datetime offset from 2026-04-07."""
    base = datetime(2026, 4, 7, tzinfo=timezone.utc)
    return base + timedelta(days=days_offset, hours=hour)


# (user_index, club_name, days_offset_from_2026-04-07, hour, duration_hours, computers, status)
DEMO_BOOKINGS = [
    # --- Upcoming (ACTIVE) bookings ---
    (0, "LAN Lords",    2,  14, 2, 2, BookingStatus.ACTIVE),
    (0, "Cyber Arena",  4,  11, 3, 1, BookingStatus.ACTIVE),
    (0, "NeoPlay Hub",  6,  16, 2, 3, BookingStatus.ACTIVE),
    (1, "FragZone",     3,  13, 2, 2, BookingStatus.ACTIVE),
    (1, "GamersPit",    5,  15, 3, 2, BookingStatus.ACTIVE),
    # --- Past (COMPLETED) bookings ---
    (0, "Pixel Vault",  -6, 10, 2, 1, BookingStatus.COMPLETED),
    (0, "LAN Lords",    -4, 14, 3, 2, BookingStatus.COMPLETED),
    (0, "FragZone",     -2, 12, 2, 2, BookingStatus.COMPLETED),
    (1, "Cyber Arena",  -7, 11, 2, 1, BookingStatus.COMPLETED),
    (1, "NeoPlay Hub",  -3, 15, 2, 3, BookingStatus.COMPLETED),
    (1, "LAN Lords",    -1, 18, 2, 2, BookingStatus.COMPLETED),
]


async def run_seed(db: AsyncSession | None = None) -> None:
    own_session = db is None
    if own_session:
        db = AsyncSessionLocal()

    try:
        # --- Seed clubs ---
        for club_data in SEED_CLUBS:
            existing = await db.execute(select(Club).where(Club.name == club_data["name"]))
            if existing.scalar_one_or_none() is None:
                db.add(Club(**club_data))
                logger.info("Seeded club: %s", club_data["name"])
        await db.flush()

        # --- Seed demo users ---
        from app.services.auth_service import hash_password

        seeded_users: list[User] = []
        for user_data in DEMO_USERS:
            existing = await db.execute(select(User).where(User.username == user_data["username"]))
            user = existing.scalar_one_or_none()
            if user is None:
                user = User(
                    username=user_data["username"],
                    email=user_data["email"],
                    password_hash=hash_password(user_data["password"]),
                    phone=user_data.get("phone"),
                )
                db.add(user)
                logger.info("Seeded user: %s", user_data["username"])
            seeded_users.append(user)
        await db.flush()

        # --- Seed demo bookings ---
        for user_idx, club_name, day_off, hour, duration, computers, status in DEMO_BOOKINGS:
            user = seeded_users[user_idx]
            if user.id is None:
                continue  # user not yet persisted; skip

            club_result = await db.execute(select(Club).where(Club.name == club_name))
            club = club_result.scalar_one_or_none()
            if club is None:
                continue

            start = _dt(day_off, hour)
            existing_booking = await db.execute(
                select(Booking).where(
                    Booking.user_id == user.id,
                    Booking.club_id == club.id,
                    Booking.start_time == start,
                )
            )
            if existing_booking.scalar_one_or_none() is None:
                booking = Booking(
                    user_id=user.id,
                    club_id=club.id,
                    start_time=start,
                    duration_hours=duration,
                    computers_booked=computers,
                    status=status,
                )
                db.add(booking)
                logger.info(
                    "Seeded booking: %s @ %s on %s [%s]",
                    user.username, club_name, start.date(), status.value,
                )

        await db.commit()
        logger.info("Seed completed")
    except Exception:
        await db.rollback()
        raise
    finally:
        if own_session:
            await db.close()


if __name__ == "__main__":
    import asyncio
    logging.basicConfig(level=logging.INFO)
    asyncio.run(run_seed())
