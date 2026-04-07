import logging
import random
import string
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.admin import AdminRole, AdminUser
from app.models.booking import Booking, BookingStatus
from app.models.club import Club
from app.models.payment import Payment, PaymentMethod, PaymentStatus
from app.models.refresh_token import RefreshToken  # noqa: F401
from app.models.transaction import Transaction, TransactionStatus, TransactionType
from app.models.user import User
from app.models.wallet import Wallet

logger = logging.getLogger("app.seed")

SEED_CLUBS = [
    {
        "name": "Space Gaming",
        "location": "Amir Temur Ave, Tashkent",
        "total_computers": 30,
        "image_url": "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&h=400&fit=crop",
        "rating": 4.8,
        "price_per_hour": 15000,
        "opening_hour": 9,
        "closing_hour": 24,
        "latitude": 41.305845,
        "longitude": 69.280123,
        "address": "Amir Temur Ave, Tashkent",
    },
    {
        "name": "Yota Premium",
        "location": "Shota Rustaveli St, Tashkent",
        "total_computers": 25,
        "image_url": "https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=800&h=400&fit=crop",
        "rating": 4.7,
        "price_per_hour": 18000,
        "opening_hour": 10,
        "closing_hour": 24,
        "latitude": 41.303117,
        "longitude": 69.289016,
        "address": "Shota Rustaveli St, Tashkent",
    },
    {
        "name": "COLIZEUM",
        "location": "Bobur St, Tashkent",
        "total_computers": 40,
        "image_url": "https://images.unsplash.com/photo-1612287230202-1ff1d85d1bdf?w=800&h=400&fit=crop",
        "rating": 4.9,
        "price_per_hour": 20000,
        "opening_hour": 0,
        "closing_hour": 24,
        "latitude": 41.321232,
        "longitude": 69.296300,
        "address": "Bobur St, Tashkent",
    },
    {
        "name": "M.V.P Badamzar",
        "location": "Badamzar, Tashkent",
        "total_computers": 20,
        "image_url": "https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=800&h=400&fit=crop",
        "rating": 4.6,
        "price_per_hour": 15000,
        "opening_hour": 10,
        "closing_hour": 23,
        "latitude": 41.336069,
        "longitude": 69.293086,
        "address": "Badamzar, Tashkent",
    },
    {
        "name": "Aventus",
        "location": "Navoi St, Tashkent",
        "total_computers": 22,
        "image_url": "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800&h=400&fit=crop",
        "rating": 4.5,
        "price_per_hour": 14000,
        "opening_hour": 9,
        "closing_hour": 23,
        "latitude": 41.312969,
        "longitude": 69.289272,
        "address": "Navoi St, Tashkent",
    },
    {
        "name": "Bezone Gaming",
        "location": "Mirabad, Tashkent",
        "total_computers": 18,
        "image_url": "https://images.unsplash.com/photo-1548686304-89d188a80029?w=800&h=400&fit=crop",
        "rating": 4.4,
        "price_per_hour": 12000,
        "opening_hour": 10,
        "closing_hour": 24,
        "latitude": 41.313432,
        "longitude": 69.287224,
        "address": "Mirabad, Tashkent",
    },
    {
        "name": "Centrum Gaming",
        "location": "Amir Temur Ave, Tashkent",
        "total_computers": 28,
        "image_url": "https://images.unsplash.com/photo-1552820728-8b83bb6b2b28?w=800&h=400&fit=crop",
        "rating": 4.6,
        "price_per_hour": 16000,
        "opening_hour": 9,
        "closing_hour": 24,
        "latitude": 41.309779,
        "longitude": 69.287185,
        "address": "Amir Temur Ave, Tashkent",
    },
    {
        "name": "Tokyo. PC",
        "location": "Buyuk Turon St, Tashkent",
        "total_computers": 24,
        "image_url": "https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=800&h=400&fit=crop",
        "rating": 4.7,
        "price_per_hour": 17000,
        "opening_hour": 10,
        "closing_hour": 24,
        "latitude": 41.318252,
        "longitude": 69.286720,
        "address": "Buyuk Turon St, Tashkent",
    },
    {
        "name": "Meta Gaming",
        "location": "Chilanzar, Tashkent",
        "total_computers": 20,
        "image_url": "https://images.unsplash.com/photo-1598550476439-6847785fcea6?w=800&h=400&fit=crop",
        "rating": 4.5,
        "price_per_hour": 13000,
        "opening_hour": 10,
        "closing_hour": 23,
        "latitude": 41.311184,
        "longitude": 69.276173,
        "address": "Chilanzar, Tashkent",
    },
    {
        "name": "Silence Game",
        "location": "Oybek St, Tashkent",
        "total_computers": 15,
        "image_url": "https://images.unsplash.com/photo-1542751110-97427bbecf20?w=800&h=400&fit=crop",
        "rating": 4.3,
        "price_per_hour": 11000,
        "opening_hour": 10,
        "closing_hour": 22,
        "latitude": 41.307842,
        "longitude": 69.282677,
        "address": "Oybek St, Tashkent",
    },
    {
        "name": "Optimus",
        "location": "Chilanzar 9, Tashkent",
        "total_computers": 20,
        "image_url": "https://images.unsplash.com/photo-1600861194942-f883de0dfe97?w=800&h=400&fit=crop",
        "rating": 4.4,
        "price_per_hour": 10000,
        "opening_hour": 9,
        "closing_hour": 23,
        "latitude": 41.288816,
        "longitude": 69.203146,
        "address": "Chilanzar 9, Tashkent",
    },
    {
        "name": "Red Panda Gaming",
        "location": "Sergeli, Tashkent",
        "total_computers": 16,
        "image_url": "https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=800&h=400&fit=crop",
        "rating": 4.3,
        "price_per_hour": 10000,
        "opening_hour": 10,
        "closing_hour": 23,
        "latitude": 41.294149,
        "longitude": 69.213652,
        "address": "Sergeli, Tashkent",
    },
    {
        "name": "Inside Cybersport",
        "location": "Yashnabad, Tashkent",
        "total_computers": 35,
        "image_url": "https://images.unsplash.com/photo-1558742619-fd82741daa55?w=800&h=400&fit=crop",
        "rating": 4.6,
        "price_per_hour": 15000,
        "opening_hour": 0,
        "closing_hour": 24,
        "latitude": 41.265225,
        "longitude": 69.239743,
        "address": "Yashnabad, Tashkent",
    },
    {
        "name": "Game X Esports",
        "location": "Yakkasaray, Tashkent",
        "total_computers": 30,
        "image_url": "https://images.unsplash.com/photo-1534423861386-85a16f5d13fd?w=800&h=400&fit=crop",
        "rating": 4.5,
        "price_per_hour": 14000,
        "opening_hour": 9,
        "closing_hour": 24,
        "latitude": 41.275218,
        "longitude": 69.224463,
        "address": "Yakkasaray, Tashkent",
    },
    {
        "name": "Line Game",
        "location": "Bektemir, Tashkent",
        "total_computers": 18,
        "image_url": "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&h=400&fit=crop",
        "rating": 4.2,
        "price_per_hour": 10000,
        "opening_hour": 10,
        "closing_hour": 22,
        "latitude": 41.352988,
        "longitude": 69.355103,
        "address": "Bektemir, Tashkent",
    },
    {
        "name": "Sodda Gaming",
        "location": "Shayhantahur, Tashkent",
        "total_computers": 22,
        "image_url": "https://images.unsplash.com/photo-1586182987320-4f376d39d787?w=800&h=400&fit=crop",
        "rating": 4.4,
        "price_per_hour": 12000,
        "opening_hour": 10,
        "closing_hour": 23,
        "latitude": 41.368146,
        "longitude": 69.313338,
        "address": "Shayhantahur, Tashkent",
    },
    {
        "name": "Game Baza",
        "location": "Uchtepa, Tashkent",
        "total_computers": 20,
        "image_url": "https://images.unsplash.com/photo-1547394765-185e1e68f34e?w=800&h=400&fit=crop",
        "rating": 4.3,
        "price_per_hour": 11000,
        "opening_hour": 10,
        "closing_hour": 23,
        "latitude": 41.334231,
        "longitude": 69.368069,
        "address": "Uchtepa, Tashkent",
    },
    {
        "name": "Darkzone",
        "location": "Olmazar, Tashkent",
        "total_computers": 25,
        "image_url": "https://images.unsplash.com/photo-1605379399642-870262d3d051?w=800&h=400&fit=crop",
        "rating": 4.5,
        "price_per_hour": 14000,
        "opening_hour": 0,
        "closing_hour": 24,
        "latitude": 41.369909,
        "longitude": 69.310534,
        "address": "Olmazar, Tashkent",
    },
    {
        "name": "M.V.P Kadysheva",
        "location": "Kadysheva, Tashkent",
        "total_computers": 20,
        "image_url": "https://images.unsplash.com/photo-1580327344181-c131331bab66?w=800&h=400&fit=crop",
        "rating": 4.6,
        "price_per_hour": 15000,
        "opening_hour": 10,
        "closing_hour": 23,
        "latitude": 41.284653,
        "longitude": 69.342361,
        "address": "Kadysheva, Tashkent",
    },
    {
        "name": "Saturn Cyber Planet",
        "location": "Yunusabad, Tashkent",
        "total_computers": 28,
        "image_url": "https://images.unsplash.com/photo-1563207153-f403bf289096?w=800&h=400&fit=crop",
        "rating": 4.4,
        "price_per_hour": 13000,
        "opening_hour": 9,
        "closing_hour": 24,
        "latitude": 41.267339,
        "longitude": 69.351543,
        "address": "Yunusabad, Tashkent",
    },
]

DEMO_USERS = [
    {
        "username": "gamer_pro",
        "email": "gamer@test.com",
        "password": "Test1234!",
        "phone": "+998901234567",
    },
    {
        "username": "cyber_ninja",
        "email": "ninja@test.com",
        "password": "Test1234!",
        "phone": "+998907654321",
    },
    {
        "username": "pixel_queen",
        "email": "queen@test.com",
        "password": "Test1234!",
        "phone": "+998903456789",
    },
    {
        "username": "admin_boss",
        "email": "admin@test.com",
        "password": "Admin1234!",
        "phone": None,
        "is_admin": True,
        "admin_role": AdminRole.SUPER_ADMIN,
        "club_name": None,
    },
    {
        "username": "fz_admin",
        "email": "fzadmin@test.com",
        "password": "Admin1234!",
        "phone": None,
        "is_admin": True,
        "admin_role": AdminRole.CLUB_ADMIN,
        "club_name": "COLIZEUM",
    },
]

WALLET_BALANCES = {
    "gamer_pro": 500_000,
    "cyber_ninja": 120_000,
    "pixel_queen": 1_200_000,
    "admin_boss": 0,
    "fz_admin": 0,
}


def _dt(days_offset: int, hour: int, minute: int = 0) -> datetime:
    base = datetime(2026, 4, 7, tzinfo=timezone.utc)
    return base + timedelta(days=days_offset, hours=hour, minutes=minute)


def _ref() -> str:
    now = datetime.now(timezone.utc)
    suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
    return f"TXN-{now.strftime('%Y%m%d')}-{suffix}"


async def run_seed(db: AsyncSession | None = None) -> None:
    own_session = db is None
    if own_session:
        db = AsyncSessionLocal()

    try:
        # ── Clubs ─────────────────────────────────────────────────────────────
        club_map: dict[str, Club] = {}
        for club_data in SEED_CLUBS:
            res = await db.execute(select(Club).where(Club.name == club_data["name"]))
            club = res.scalar_one_or_none()
            if club is None:
                club = Club(**club_data)
                db.add(club)
                logger.info("Seeded club: %s", club_data["name"])
            else:
                # Update lat/lng/address/image if missing
                if club.latitude is None and club_data.get("latitude"):
                    club.latitude = club_data["latitude"]
                    club.longitude = club_data["longitude"]
                    club.address = club_data["address"]
                if club.image_url is None and club_data.get("image_url"):
                    club.image_url = club_data["image_url"]
            club_map[club_data["name"]] = club
        await db.flush()

        # ── Users ─────────────────────────────────────────────────────────────
        from app.services.auth_service import hash_password

        user_map: dict[str, User] = {}
        for ud in DEMO_USERS:
            res = await db.execute(select(User).where(User.username == ud["username"]))
            user = res.scalar_one_or_none()
            if user is None:
                user = User(
                    username=ud["username"],
                    email=ud["email"],
                    password_hash=hash_password(ud["password"]),
                    phone=ud.get("phone"),
                )
                db.add(user)
                logger.info("Seeded user: %s", ud["username"])
            user_map[ud["username"]] = user
        await db.flush()

        # ── Admin records ─────────────────────────────────────────────────────
        for ud in DEMO_USERS:
            if not ud.get("is_admin"):
                continue
            user = user_map[ud["username"]]
            res = await db.execute(select(AdminUser).where(AdminUser.user_id == user.id))
            if res.scalar_one_or_none() is None:
                club_id = None
                if ud.get("club_name"):
                    c = club_map.get(ud["club_name"])
                    if c:
                        club_id = c.id
                admin_rec = AdminUser(
                    user_id=user.id,
                    role=ud["admin_role"],
                    club_id=club_id,
                )
                db.add(admin_rec)
                logger.info("Seeded admin: %s (%s)", ud["username"], ud["admin_role"].value)
        await db.flush()

        # ── Wallets ───────────────────────────────────────────────────────────
        wallet_map: dict[str, Wallet] = {}
        for username, balance in WALLET_BALANCES.items():
            user = user_map.get(username)
            if not user:
                continue
            res = await db.execute(select(Wallet).where(Wallet.user_id == user.id))
            wallet = res.scalar_one_or_none()
            if wallet is None:
                wallet = Wallet(user_id=user.id, balance=balance, currency="UZS")
                db.add(wallet)
                logger.info("Seeded wallet: %s = %s UZS", username, balance)
            wallet_map[username] = wallet
        await db.flush()

        # ── Transactions (15–20 entries) ──────────────────────────────────────
        # We'll only seed transactions if none exist yet for the user
        gp_user = user_map["gamer_pro"]
        cn_user = user_map["cyber_ninja"]
        pq_user = user_map["pixel_queen"]

        gp_wallet = wallet_map.get("gamer_pro")
        cn_wallet = wallet_map.get("cyber_ninja")
        pq_wallet = wallet_map.get("pixel_queen")

        # gamer_pro: 3 top-ups (100k, 200k, 200k)
        txn_seed = [
            # (user, wallet, type, amount, booking_id, desc, days_ago)
            (gp_user, gp_wallet, TransactionType.TOP_UP, 100_000, None, "Top-up via card", -28),
            (gp_user, gp_wallet, TransactionType.TOP_UP, 200_000, None, "Top-up via Payme", -15),
            (gp_user, gp_wallet, TransactionType.TOP_UP, 200_000, None, "Top-up via Click", -3),
            (cn_user, cn_wallet, TransactionType.TOP_UP, 100_000, None, "Top-up via card", -20),
            (cn_user, cn_wallet, TransactionType.TOP_UP, 50_000, None, "Top-up via Payme", -5),
            (pq_user, pq_wallet, TransactionType.TOP_UP, 500_000, None, "Top-up via card", -25),
            (pq_user, pq_wallet, TransactionType.TOP_UP, 800_000, None, "Top-up via Click", -10),
        ]

        for user, wallet, txn_type, amount, booking_id, desc, days_ago in txn_seed:
            if not wallet:
                continue
            ref = _ref()
            res = await db.execute(
                select(Transaction).where(Transaction.reference_code == ref)
            )
            if res.scalar_one_or_none() is None:
                created = _dt(days_ago, 12)
                bal_before = 0.0
                bal_after = amount if txn_type == TransactionType.TOP_UP else 0.0
                txn = Transaction(
                    wallet_id=wallet.id,
                    user_id=user.id,
                    booking_id=booking_id,
                    type=txn_type,
                    amount=amount,
                    balance_before=bal_before,
                    balance_after=bal_after,
                    status=TransactionStatus.COMPLETED,
                    description=desc,
                    reference_code=ref,
                    created_at=created,
                )
                db.add(txn)
        await db.flush()

        # ── Bookings ──────────────────────────────────────────────────────────
        # (user_key, club_name, day_off, hour, duration, computers, status, method)
        BOOKING_SEED = [
            # ACTIVE upcoming
            ("gamer_pro",  "COLIZEUM",         2,  14, 2, 2, BookingStatus.ACTIVE, PaymentMethod.WALLET),
            ("gamer_pro",  "Space Gaming",     4,  11, 3, 1, BookingStatus.ACTIVE, PaymentMethod.WALLET),
            ("gamer_pro",  "Tokyo. PC",        6,  16, 2, 3, BookingStatus.ACTIVE, PaymentMethod.CARD),
            ("cyber_ninja","Aventus",          3,  13, 2, 2, BookingStatus.ACTIVE, PaymentMethod.WALLET),
            ("cyber_ninja","Bezone Gaming",    5,  15, 3, 2, BookingStatus.ACTIVE, PaymentMethod.CASH),
            ("pixel_queen","Space Gaming",     1,  10, 2, 4, BookingStatus.ACTIVE, PaymentMethod.WALLET),
            # COMPLETED past
            ("gamer_pro",  "Optimus",         -6,  10, 2, 1, BookingStatus.COMPLETED, PaymentMethod.WALLET),
            ("gamer_pro",  "COLIZEUM",        -4,  14, 3, 2, BookingStatus.COMPLETED, PaymentMethod.WALLET),
            ("gamer_pro",  "Aventus",         -2,  12, 2, 2, BookingStatus.COMPLETED, PaymentMethod.CARD),
            ("cyber_ninja","Space Gaming",    -7,  11, 2, 1, BookingStatus.COMPLETED, PaymentMethod.WALLET),
            ("pixel_queen","Tokyo. PC",       -3,  15, 2, 3, BookingStatus.COMPLETED, PaymentMethod.WALLET),
            ("pixel_queen","COLIZEUM",        -1,  18, 2, 2, BookingStatus.COMPLETED, PaymentMethod.WALLET),
            # CANCELLED with refund
            ("gamer_pro",  "Bezone Gaming",   -10,  10, 2, 1, BookingStatus.CANCELLED, PaymentMethod.WALLET),
            ("pixel_queen","Aventus",         -8,  14, 1, 2, BookingStatus.CANCELLED, PaymentMethod.WALLET),
        ]

        for (ukey, club_name, day_off, hour, duration, computers, bstatus, pay_method) in BOOKING_SEED:
            user = user_map.get(ukey)
            club = club_map.get(club_name)
            if not user or not club:
                continue

            start = _dt(day_off, hour)
            res = await db.execute(
                select(Booking).where(
                    Booking.user_id == user.id,
                    Booking.club_id == club.id,
                    Booking.start_time == start,
                )
            )
            if res.scalar_one_or_none() is not None:
                continue

            total_price = float(club.price_per_hour * computers * duration)
            booking = Booking(
                user_id=user.id,
                club_id=club.id,
                start_time=start,
                duration_hours=duration,
                computers_booked=computers,
                status=bstatus,
                total_price=total_price,
            )
            db.add(booking)
            await db.flush()

            # Create payment
            wallet = wallet_map.get(ukey)
            if bstatus == BookingStatus.CANCELLED and pay_method == PaymentMethod.CASH:
                pay_status = PaymentStatus.FAILED
            elif bstatus == BookingStatus.CANCELLED:
                pay_status = PaymentStatus.REFUNDED
            elif pay_method == PaymentMethod.CASH:
                pay_status = PaymentStatus.PENDING
            else:
                pay_status = PaymentStatus.COMPLETED

            # Create transaction for wallet payments
            txn_id = None
            if pay_method in (PaymentMethod.WALLET, PaymentMethod.CARD) and wallet:
                ref = _ref()
                bal_before = float(wallet.balance)
                if pay_status == PaymentStatus.REFUNDED:
                    txn_type = TransactionType.REFUND
                    bal_after = bal_before + total_price
                else:
                    txn_type = TransactionType.BOOKING_PAYMENT
                    bal_after = max(0.0, bal_before - total_price)

                txn = Transaction(
                    wallet_id=wallet.id,
                    user_id=user.id,
                    booking_id=booking.id,
                    type=txn_type,
                    amount=total_price,
                    balance_before=bal_before,
                    balance_after=bal_after,
                    status=TransactionStatus.COMPLETED,
                    description=f"Booking #{booking.id} at {club.name}",
                    reference_code=ref,
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
                status=pay_status,
            )
            db.add(payment)
            await db.flush()

            booking.payment_id = payment.id
            await db.flush()

            logger.info(
                "Seeded booking: %s @ %s [%s] %s UZS",
                ukey, club_name, bstatus.value, total_price,
            )

        # ── Multi-slot demo booking ────────────────────────────────────────────
        ms_user = user_map.get("pixel_queen")
        ms_club = club_map.get("Tokyo. PC")
        ms_wallet = wallet_map.get("pixel_queen")
        if ms_user and ms_club and ms_wallet:
            ms_start = _dt(7, 14)  # future
            res = await db.execute(
                select(Booking).where(
                    Booking.user_id == ms_user.id,
                    Booking.club_id == ms_club.id,
                    Booking.start_time == ms_start,
                )
            )
            if res.scalar_one_or_none() is None:
                slot_details = {
                    "slots": [
                        {"start_time": _dt(7, 14).isoformat(), "end_time": _dt(7, 16).isoformat(), "duration_hours": 2},
                        {"start_time": _dt(7, 17).isoformat(), "end_time": _dt(7, 18).isoformat(), "duration_hours": 1},
                    ]
                }
                total_price = float(ms_club.price_per_hour * 2 * 3)  # 3h total, 2 computers
                ms_booking = Booking(
                    user_id=ms_user.id,
                    club_id=ms_club.id,
                    start_time=ms_start,
                    duration_hours=3,
                    computers_booked=2,
                    status=BookingStatus.ACTIVE,
                    total_price=total_price,
                    slot_details=slot_details,
                )
                db.add(ms_booking)
                await db.flush()

                ref = _ref()
                ms_txn = Transaction(
                    wallet_id=ms_wallet.id,
                    user_id=ms_user.id,
                    booking_id=ms_booking.id,
                    type=TransactionType.BOOKING_PAYMENT,
                    amount=total_price,
                    balance_before=float(ms_wallet.balance),
                    balance_after=max(0.0, float(ms_wallet.balance) - total_price),
                    status=TransactionStatus.COMPLETED,
                    description=f"Multi-slot booking #{ms_booking.id} at {ms_club.name}",
                    reference_code=ref,
                )
                db.add(ms_txn)
                await db.flush()

                ms_payment = Payment(
                    user_id=ms_user.id,
                    booking_id=ms_booking.id,
                    transaction_id=ms_txn.id,
                    amount=total_price,
                    method=PaymentMethod.WALLET,
                    status=PaymentStatus.COMPLETED,
                )
                db.add(ms_payment)
                await db.flush()
                ms_booking.payment_id = ms_payment.id
                await db.flush()
                logger.info("Seeded multi-slot booking for pixel_queen @ Tokyo. PC")

        await db.commit()
        logger.info("Seed completed successfully")

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
