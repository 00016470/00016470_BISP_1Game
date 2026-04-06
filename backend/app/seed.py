import logging
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.club import Club

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


async def run_seed(db: AsyncSession | None = None) -> None:
    own_session = db is None
    if own_session:
        db = AsyncSessionLocal()

    try:
        for club_data in SEED_CLUBS:
            existing = await db.execute(select(Club).where(Club.name == club_data["name"]))
            if existing.scalar_one_or_none() is None:
                db.add(Club(**club_data))
                logger.info("Seeded club: %s", club_data["name"])
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
