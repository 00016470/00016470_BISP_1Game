"""
Booking model for the gaming club application.

This module defines the Booking data model and related enums for managing
computer bookings at gaming clubs.
"""

import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, JSON, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class BookingStatus(str, enum.Enum):
    """
    Enumeration of possible booking statuses.

    This enum defines the lifecycle states of a booking:
    - ACTIVE: The booking is currently active and in use.
    - CANCELLED: The booking has been cancelled by the user or admin.
    - COMPLETED: The booking has been completed successfully.
    - EXPIRED: The booking time has expired without completion.
    """
    ACTIVE = "ACTIVE"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"
    EXPIRED = "EXPIRED"


class Booking(Base):
    """
    SQLAlchemy model representing a booking for computers at a gaming club.

    This model stores details about user bookings, including timing, duration,
    number of computers, status, and payment information. It establishes
    relationships with users, clubs, and payments.
    """
    __tablename__ = "bookings"

    # Primary key for the booking record
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Foreign key to the user who made the booking
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )

    # Foreign key to the club where the booking is made
    club_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("clubs.id"), nullable=False, index=True
    )

    # Start time of the booking
    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    # Duration of the booking in hours
    duration_hours: Mapped[float] = mapped_column(Float, nullable=False)

    # Number of computers booked
    computers_booked: Mapped[int] = mapped_column(Integer, nullable=False)

    # Current status of the booking
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, name="bookingstatus"),
        nullable=False,
        default=BookingStatus.ACTIVE,
    )

    # Foreign key to the payment record (Phase 2: payment & pricing)
    payment_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("payments.id", use_alter=True, name="fk_bookings_payment_id"),
        nullable=True,
    )

    # Total price for the booking
    total_price: Mapped[float | None] = mapped_column(Numeric(12, 2), nullable=True)

    # JSON details about the booked slots
    slot_details: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    # Timestamp when the booking was created
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationship to the user who made the booking
    user: Mapped["User"] = relationship("User", back_populates="bookings")  # noqa: F821

    # Relationship to the club where the booking is made
    club: Mapped["Club"] = relationship("Club", back_populates="bookings")  # noqa: F821

    # View-only relationship to the payment (canonical side is Payment.booking)
    payment: Mapped["Payment | None"] = relationship(  # noqa: F821
        "Payment",
        foreign_keys=[payment_id],
        primaryjoin="Booking.payment_id == Payment.id",
        viewonly=True,
    )
