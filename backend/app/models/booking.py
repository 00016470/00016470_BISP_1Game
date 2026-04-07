import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, JSON, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class BookingStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"
    EXPIRED = "EXPIRED"


class Booking(Base):
    __tablename__ = "bookings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )
    club_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("clubs.id"), nullable=False, index=True
    )
    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    duration_hours: Mapped[float] = mapped_column(Float, nullable=False)
    computers_booked: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, name="bookingstatus"),
        nullable=False,
        default=BookingStatus.ACTIVE,
    )
    # Phase 2: payment & pricing
    payment_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("payments.id", use_alter=True, name="fk_bookings_payment_id"),
        nullable=True,
    )
    total_price: Mapped[float | None] = mapped_column(Numeric(12, 2), nullable=True)
    slot_details: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship("User", back_populates="bookings")  # noqa: F821
    club: Mapped["Club"] = relationship("Club", back_populates="bookings")  # noqa: F821
    # viewonly: the canonical side is Payment.booking (booking_id FK on Payment)
    payment: Mapped["Payment | None"] = relationship(  # noqa: F821
        "Payment",
        foreign_keys=[payment_id],
        primaryjoin="Booking.payment_id == Payment.id",
        viewonly=True,
    )
