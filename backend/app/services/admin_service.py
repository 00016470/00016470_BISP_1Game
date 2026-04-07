from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.admin import AdminUser
from app.models.booking import Booking, BookingStatus
from app.models.club import Club
from app.models.payment import Payment, PaymentStatus
from app.models.transaction import Transaction, TransactionType
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.admin import (
    AdminBookingResponse,
    AdminPaymentResponse,
    AdminUserDetailResponse,
    AdminUserResponse,
    BookingsByClub,
    ClubLiveResponse,
    ClubRevenueResponse,
    ClubSessionItem,
    ClubSessionsResponse,
    DashboardResponse,
    RevenueByDay,
)
from app.schemas.booking import BookingResponse
from app.schemas.transaction import TransactionResponse


async def get_admin_record(db: AsyncSession, user: User) -> AdminUser | None:
    result = await db.execute(
        select(AdminUser).where(AdminUser.user_id == user.id)
    )
    return result.scalar_one_or_none()


def _safe_tz(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


async def get_dashboard(db: AsyncSession) -> DashboardResponse:
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)

    rev_result = await db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0)).where(
            and_(
                Payment.status == PaymentStatus.COMPLETED,
                Payment.created_at >= today_start,
                Payment.created_at < today_end,
            )
        )
    )
    total_revenue_today = float(rev_result.scalar_one() or 0)

    active_result = await db.execute(
        select(func.count()).where(Booking.status == BookingStatus.ACTIVE)
    )
    active_bookings = active_result.scalar_one()

    pending_result = await db.execute(
        select(func.count()).where(Payment.status == PaymentStatus.PENDING)
    )
    pending_payments = pending_result.scalar_one()

    users_result = await db.execute(select(func.count()).select_from(User))
    total_users = users_result.scalar_one()

    pending_users_result = await db.execute(
        select(func.count()).where(User.is_approved == False)
    )
    pending_users = pending_users_result.scalar_one()

    clubs_result = await db.execute(
        select(Club.id, Club.name, func.count(Booking.id), func.coalesce(func.sum(Booking.total_price), 0))
        .outerjoin(Booking, and_(Club.id == Booking.club_id, Booking.status != BookingStatus.CANCELLED))
        .group_by(Club.id, Club.name)
        .order_by(func.count(Booking.id).desc())
    )
    bookings_by_club = [
        BookingsByClub(club_id=row[0], club_name=row[1], booking_count=row[2], revenue=float(row[3]))
        for row in clubs_result.all()
    ]

    revenue_by_day: list[RevenueByDay] = []
    for i in range(29, -1, -1):
        day_start = today_start - timedelta(days=i)
        day_end = day_start + timedelta(days=1)
        day_rev = await db.execute(
            select(func.coalesce(func.sum(Payment.amount), 0), func.count(Payment.id)).where(
                and_(
                    Payment.status == PaymentStatus.COMPLETED,
                    Payment.created_at >= day_start,
                    Payment.created_at < day_end,
                )
            )
        )
        row = day_rev.one()
        revenue_by_day.append(
            RevenueByDay(date=day_start.strftime("%Y-%m-%d"), revenue=float(row[0] or 0), booking_count=row[1] or 0)
        )

    return DashboardResponse(
        total_revenue_today=total_revenue_today,
        active_bookings=active_bookings,
        pending_payments=pending_payments,
        total_users=total_users,
        pending_users=pending_users,
        bookings_by_club=bookings_by_club,
        revenue_by_day=revenue_by_day,
    )


async def list_admin_bookings(
    db: AsyncSession,
    club_id: Optional[int] = None,
    status: Optional[str] = None,
    date: Optional[str] = None,
    page: int = 1,
    per_page: int = 20,
) -> dict:
    q = (
        select(Booking, User, Club, Payment)
        .join(User, Booking.user_id == User.id)
        .join(Club, Booking.club_id == Club.id)
        .outerjoin(Payment, Booking.payment_id == Payment.id)
    )
    if club_id:
        q = q.where(Booking.club_id == club_id)
    if status:
        q = q.where(Booking.status == status)
    if date:
        try:
            d = datetime.strptime(date, "%Y-%m-%d").replace(tzinfo=timezone.utc)
            q = q.where(and_(Booking.start_time >= d, Booking.start_time < d + timedelta(days=1)))
        except ValueError:
            pass

    count_q = select(func.count()).select_from(q.subquery())
    total = (await db.execute(count_q)).scalar_one()

    q = q.order_by(Booking.created_at.desc()).offset((page - 1) * per_page).limit(per_page)
    rows = (await db.execute(q)).all()

    items = [
        AdminBookingResponse(
            id=b.id, user_id=b.user_id, username=u.username,
            club_id=b.club_id, club_name=c.name,
            start_time=b.start_time, duration_hours=b.duration_hours,
            computers_booked=b.computers_booked,
            total_price=float(b.total_price) if b.total_price else None,
            status=b.status.value,
            payment_status=p.status.value if p else None,
            payment_method=p.method.value if p else None,
            created_at=b.created_at,
        )
        for b, u, c, p in rows
    ]
    return {"items": items, "total": total, "page": page, "per_page": per_page}


async def list_admin_payments(
    db: AsyncSession,
    status: Optional[str] = None,
    method: Optional[str] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    page: int = 1,
    per_page: int = 20,
) -> dict:
    q = (
        select(Payment, User, Club)
        .join(User, Payment.user_id == User.id)
        .join(Booking, Payment.booking_id == Booking.id)
        .join(Club, Booking.club_id == Club.id)
    )
    if status:
        q = q.where(Payment.status == status)
    if method:
        q = q.where(Payment.method == method)
    if from_date:
        q = q.where(Payment.created_at >= from_date)
    if to_date:
        q = q.where(Payment.created_at <= to_date)

    count_q = select(func.count()).select_from(q.subquery())
    total = (await db.execute(count_q)).scalar_one()

    q = q.order_by(Payment.created_at.desc()).offset((page - 1) * per_page).limit(per_page)
    rows = (await db.execute(q)).all()

    items = [
        AdminPaymentResponse(
            id=p.id, user_id=p.user_id, username=u.username,
            booking_id=p.booking_id, club_name=c.name,
            amount=float(p.amount), method=p.method.value,
            status=p.status.value, validated_by=p.validated_by,
            validated_at=p.validated_at, created_at=p.created_at,
        )
        for p, u, c in rows
    ]
    return {"items": items, "total": total, "page": page, "per_page": per_page}


async def list_admin_users(
    db: AsyncSession, page: int = 1, per_page: int = 20, pending_only: bool = False
) -> dict:
    base = select(User)
    if pending_only:
        base = base.where(User.is_approved == False)
    users_result = await db.execute(
        base.order_by(User.created_at.desc()).offset((page - 1) * per_page).limit(per_page)
    )
    users = users_result.scalars().all()

    count_base = select(func.count()).select_from(User)
    if pending_only:
        count_base = count_base.where(User.is_approved == False)
    total_result = await db.execute(count_base)
    total = total_result.scalar_one()

    items = []
    for u in users:
        bookings_r = await db.execute(select(func.count()).where(Booking.user_id == u.id))
        booking_count = bookings_r.scalar_one()
        spent_r = await db.execute(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                and_(Payment.user_id == u.id, Payment.status == PaymentStatus.COMPLETED)
            )
        )
        total_spent = float(spent_r.scalar_one() or 0)
        wallet_r = await db.execute(select(Wallet).where(Wallet.user_id == u.id))
        wallet = wallet_r.scalar_one_or_none()
        wallet_balance = float(wallet.balance) if wallet else 0.0
        joined_at = u.created_at.strftime("%b %d, %Y") if u.created_at else ""
        items.append(
            AdminUserResponse(
                id=u.id, username=u.username, email=u.email, phone=u.phone,
                is_approved=u.is_approved, booking_count=booking_count,
                total_spent=total_spent, wallet_balance=wallet_balance, joined_at=joined_at,
            )
        )

    return {"items": items, "total": total, "page": page, "per_page": per_page}


async def approve_user(db: AsyncSession, user_id: int) -> AdminUserResponse:
    from app.exceptions import NotFoundError
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User")
    user.is_approved = True
    await db.flush()
    await db.commit()

    bookings_r = await db.execute(select(func.count()).where(Booking.user_id == user.id))
    booking_count = bookings_r.scalar_one()
    spent_r = await db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0)).where(
            and_(Payment.user_id == user.id, Payment.status == PaymentStatus.COMPLETED)
        )
    )
    total_spent = float(spent_r.scalar_one() or 0)
    wallet_r = await db.execute(select(Wallet).where(Wallet.user_id == user.id))
    wallet = wallet_r.scalar_one_or_none()

    return AdminUserResponse(
        id=user.id, username=user.username, email=user.email, phone=user.phone,
        is_approved=True, booking_count=booking_count,
        total_spent=total_spent,
        wallet_balance=float(wallet.balance) if wallet else 0.0,
        joined_at=user.created_at.strftime("%b %d, %Y") if user.created_at else "",
    )


async def reject_user(db: AsyncSession, user_id: int) -> dict:
    from app.exceptions import NotFoundError
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User")
    user.is_approved = False
    await db.flush()
    await db.commit()
    return {"id": user.id, "username": user.username, "is_approved": False}


async def delete_user(db: AsyncSession, user_id: int) -> dict:
    from app.exceptions import NotFoundError
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User")

    # Delete related records in order (payments, transactions, bookings, wallet, admin role)
    await db.execute(
        Payment.__table__.delete().where(Payment.user_id == user_id)
    )
    await db.execute(
        Transaction.__table__.delete().where(Transaction.user_id == user_id)
    )
    await db.execute(
        Booking.__table__.delete().where(Booking.user_id == user_id)
    )
    await db.execute(
        Wallet.__table__.delete().where(Wallet.user_id == user_id)
    )
    await db.execute(
        AdminUser.__table__.delete().where(AdminUser.user_id == user_id)
    )
    await db.delete(user)
    await db.flush()
    await db.commit()
    return {"id": user_id, "deleted": True}


async def get_admin_user_detail(db: AsyncSession, user_id: int) -> AdminUserDetailResponse:
    from app.exceptions import NotFoundError
    u_result = await db.execute(select(User).where(User.id == user_id))
    u = u_result.scalar_one_or_none()
    if not u:
        raise NotFoundError("User")

    wallet_r = await db.execute(select(Wallet).where(Wallet.user_id == user_id))
    wallet = wallet_r.scalar_one_or_none()

    bookings_r = await db.execute(
        select(Booking, Club)
        .join(Club, Booking.club_id == Club.id)
        .where(Booking.user_id == user_id)
        .order_by(Booking.created_at.desc())
        .limit(20)
    )
    bookings_data = [
        {"id": b.id, "club": c.name, "club_id": c.id, "status": b.status.value,
         "start_time": b.start_time.isoformat(), "duration_hours": b.duration_hours,
         "computers_booked": b.computers_booked,
         "total_price": float(b.total_price) if b.total_price else 0}
        for b, c in bookings_r.all()
    ]

    payments_r = await db.execute(
        select(Payment, Booking, Club)
        .join(Booking, Payment.booking_id == Booking.id)
        .join(Club, Booking.club_id == Club.id)
        .where(Payment.user_id == user_id)
        .order_by(Payment.created_at.desc())
        .limit(20)
    )
    payments_data = [
        {"id": p.id, "amount": float(p.amount), "method": p.method.value,
         "status": p.status.value, "club_name": c.name,
         "created_at": p.created_at.isoformat()}
        for p, _b, c in payments_r.all()
    ]

    txns_r = await db.execute(
        select(Transaction)
        .where(Transaction.user_id == user_id)
        .order_by(Transaction.created_at.desc())
        .limit(10)
    )
    txns_data = [
        {"id": t.id, "type": t.type.value, "amount": float(t.amount),
         "reference_code": t.reference_code, "created_at": t.created_at.isoformat()}
        for t in txns_r.scalars().all()
    ]

    spent_r = await db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0)).where(
            and_(Payment.user_id == user_id, Payment.status == PaymentStatus.COMPLETED)
        )
    )
    total_spent = float(spent_r.scalar_one() or 0)

    bc_r = await db.execute(select(func.count()).where(Booking.user_id == user_id))
    booking_count = bc_r.scalar_one()

    return AdminUserDetailResponse(
        id=u.id, username=u.username, email=u.email, phone=u.phone,
        is_approved=u.is_approved,
        joined_at=u.created_at.strftime("%b %d, %Y") if u.created_at else "",
        wallet_balance=float(wallet.balance) if wallet else 0.0,
        currency=wallet.currency if wallet else "UZS",
        total_spent=total_spent, booking_count=booking_count,
        bookings=bookings_data, payments=payments_data, transactions=txns_data,
    )


async def get_club_sessions(db: AsyncSession, club_id: int) -> ClubSessionsResponse:
    from app.exceptions import NotFoundError
    club_r = await db.execute(select(Club).where(Club.id == club_id))
    club = club_r.scalar_one_or_none()
    if not club:
        raise NotFoundError("Club")

    now = datetime.now(timezone.utc)
    today_end = now.replace(hour=23, minute=59, second=59)

    active_r = await db.execute(
        select(Booking, User).join(User, Booking.user_id == User.id)
        .where(and_(
            Booking.club_id == club_id,
            Booking.status == BookingStatus.ACTIVE,
            Booking.start_time <= now,
        ))
        .order_by(Booking.start_time.asc())
    )
    active_sessions = []
    active_computers = 0
    for b, u in active_r.all():
        st = _safe_tz(b.start_time)
        et = st + timedelta(hours=b.duration_hours)
        if et > now:
            remaining = (et - now).total_seconds() / 60.0
            active_sessions.append(ClubSessionItem(
                booking_id=b.id, user_id=u.id, username=u.username,
                computers_booked=b.computers_booked, start_time=b.start_time,
                end_time=et, remaining_minutes=round(remaining, 1),
                total_price=float(b.total_price) if b.total_price else None,
                status="ACTIVE",
            ))
            active_computers += b.computers_booked

    upcoming_r = await db.execute(
        select(Booking, User).join(User, Booking.user_id == User.id)
        .where(and_(
            Booking.club_id == club_id,
            Booking.status == BookingStatus.ACTIVE,
            Booking.start_time > now,
            Booking.start_time <= today_end,
        ))
        .order_by(Booking.start_time.asc())
    )
    upcoming_sessions = []
    for b, u in upcoming_r.all():
        st = _safe_tz(b.start_time)
        et = st + timedelta(hours=b.duration_hours)
        upcoming_sessions.append(ClubSessionItem(
            booking_id=b.id, user_id=u.id, username=u.username,
            computers_booked=b.computers_booked, start_time=b.start_time,
            end_time=et, remaining_minutes=b.duration_hours * 60,
            total_price=float(b.total_price) if b.total_price else None,
            status="UPCOMING",
        ))

    available = max(0, club.total_computers - active_computers)
    return ClubSessionsResponse(
        club_id=club.id, club_name=club.name,
        total_computers=club.total_computers,
        active_sessions=active_sessions,
        upcoming_sessions=upcoming_sessions,
        available_computers=available,
    )


async def get_club_revenue(
    db: AsyncSession, club_id: int,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
) -> ClubRevenueResponse:
    from app.exceptions import NotFoundError
    club_r = await db.execute(select(Club).where(Club.id == club_id))
    club = club_r.scalar_one_or_none()
    if not club:
        raise NotFoundError("Club")

    now = datetime.now(timezone.utc)
    if not from_date:
        from_date = now - timedelta(days=30)
    if not to_date:
        to_date = now

    rev_r = await db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0))
        .join(Booking, Payment.booking_id == Booking.id)
        .where(and_(
            Booking.club_id == club_id,
            Payment.status == PaymentStatus.COMPLETED,
            Payment.created_at >= from_date,
            Payment.created_at <= to_date,
        ))
    )
    total_revenue = float(rev_r.scalar_one() or 0)

    sessions_r = await db.execute(
        select(func.count()).where(and_(
            Booking.club_id == club_id,
            Booking.status.in_([BookingStatus.COMPLETED, BookingStatus.ACTIVE]),
            Booking.created_at >= from_date,
            Booking.created_at <= to_date,
        ))
    )
    total_sessions = sessions_r.scalar_one()

    active_r = await db.execute(
        select(func.count()).where(and_(
            Booking.club_id == club_id,
            Booking.status == BookingStatus.ACTIVE,
        ))
    )
    active_sessions = active_r.scalar_one()

    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    revenue_by_day: list[RevenueByDay] = []
    for i in range(29, -1, -1):
        day_start = today_start - timedelta(days=i)
        day_end = day_start + timedelta(days=1)
        day_rev = await db.execute(
            select(func.coalesce(func.sum(Payment.amount), 0), func.count(Payment.id))
            .join(Booking, Payment.booking_id == Booking.id)
            .where(and_(
                Booking.club_id == club_id,
                Payment.status == PaymentStatus.COMPLETED,
                Payment.created_at >= day_start,
                Payment.created_at < day_end,
            ))
        )
        row = day_rev.one()
        revenue_by_day.append(RevenueByDay(
            date=day_start.strftime("%Y-%m-%d"),
            revenue=float(row[0] or 0),
            booking_count=row[1] or 0,
        ))

    recent_r = await db.execute(
        select(Booking, User).join(User, Booking.user_id == User.id)
        .where(and_(
            Booking.club_id == club_id,
            Booking.status.in_([BookingStatus.COMPLETED, BookingStatus.ACTIVE]),
        ))
        .order_by(Booking.created_at.desc())
        .limit(20)
    )
    recent_sessions = []
    for b, u in recent_r.all():
        st = _safe_tz(b.start_time)
        et = st + timedelta(hours=b.duration_hours)
        remaining = max(0, (et - now).total_seconds() / 60.0) if b.status == BookingStatus.ACTIVE else 0
        recent_sessions.append(ClubSessionItem(
            booking_id=b.id, user_id=u.id, username=u.username,
            computers_booked=b.computers_booked, start_time=b.start_time,
            end_time=et, remaining_minutes=round(remaining, 1),
            total_price=float(b.total_price) if b.total_price else None,
            status=b.status.value,
        ))

    return ClubRevenueResponse(
        club_id=club.id, club_name=club.name,
        total_revenue=total_revenue,
        total_sessions=total_sessions,
        active_sessions=active_sessions,
        revenue_by_day=revenue_by_day,
        recent_sessions=recent_sessions,
    )


async def get_club_live(db: AsyncSession, club_id: int) -> ClubLiveResponse:
    from app.exceptions import NotFoundError
    club_r = await db.execute(select(Club).where(Club.id == club_id))
    club = club_r.scalar_one_or_none()
    if not club:
        raise NotFoundError("Club")

    now = datetime.now(timezone.utc)
    today_end = now.replace(hour=23, minute=59, second=59)

    active_r = await db.execute(
        select(Booking).where(and_(
            Booking.club_id == club_id,
            Booking.status == BookingStatus.ACTIVE,
            Booking.start_time <= now,
        ))
    )
    active_bookings = active_r.scalars().all()
    active_computers = sum(
        b.computers_booked for b in active_bookings
        if (_safe_tz(b.start_time) + timedelta(hours=b.duration_hours)) > now
    )

    upcoming_r = await db.execute(
        select(func.count()).where(and_(
            Booking.club_id == club_id,
            Booking.status == BookingStatus.ACTIVE,
            Booking.start_time > now,
            Booking.start_time <= today_end,
        ))
    )
    upcoming = upcoming_r.scalar_one()

    available = max(0, club.total_computers - active_computers)
    occupancy = (active_computers / club.total_computers * 100) if club.total_computers > 0 else 0

    return ClubLiveResponse(
        club_id=club.id, club_name=club.name,
        total_computers=club.total_computers,
        active_sessions=len(active_bookings),
        available_computers=available,
        occupancy_percent=round(occupancy, 1),
        upcoming_bookings_today=upcoming,
    )
