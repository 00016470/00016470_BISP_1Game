"""
Payment model for the gaming club application.

This module defines the Payment data model and related enums for handling
payments in the system.
"""

import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class PaymentMethod(str, enum.Enum):
    """
    Enumeration of possible payment methods.

    This enum defines the ways users can make payments:
    - WALLET: Payment using the user's wallet balance.
    - CARD: Payment using a credit/debit card.
    - CASH: Cash payment (typically validated by staff).
    """
    WALLET = "WALLET"
    CARD = "CARD"
    CASH = "CASH"


class PaymentStatus(str, enum.Enum):
    """
    Enumeration of possible payment statuses.

    This enum defines the lifecycle states of a payment:
    - PENDING: Payment is initiated but not yet completed.
    - COMPLETED: Payment has been successfully processed.
    - FAILED: Payment attempt failed.
    - REFUNDED: Payment has been refunded.
    """
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    REFUNDED = "REFUNDED"


class Payment(Base):
    """
    SQLAlchemy model representing a payment transaction.

    This model stores details about payments made for bookings, including
    amount, method, status, and validation information. It establishes
    relationships with users, bookings, transactions, and validators.
    """
    __tablename__ = "payments"

    # Primary key for the payment record
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Foreign key to the user making the payment
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )

    # Foreign key to the booking being paid for
    booking_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("bookings.id"), nullable=False, index=True
    )

    # Optional foreign key to the transaction record
    transaction_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("transactions.id"), nullable=True
    )

    # Amount of the payment
    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)

    # Payment method used
    method: Mapped[PaymentMethod] = mapped_column(
        Enum(PaymentMethod, name="paymentmethod"), nullable=False
    )

    # Current status of the payment
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="paymentstatus"),
        nullable=False,
        default=PaymentStatus.PENDING,
    )

    # Optional foreign key to the user who validated the payment
    validated_by: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=True
    )

    # Optional timestamp when the payment was validated
    validated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Timestamp when the payment was created
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationship to the user making the payment
    user: Mapped["User"] = relationship("User", foreign_keys=[user_id])  # noqa: F821

    # Relationship to the booking being paid for
    booking: Mapped["Booking"] = relationship(  # noqa: F821
        "Booking", foreign_keys=[booking_id]
    )

    # Optional relationship to the transaction record
    transaction: Mapped["Transaction | None"] = relationship("Transaction")  # noqa: F821

    # Optional relationship to the user who validated the payment
    validator: Mapped["User | None"] = relationship(  # noqa: F821
        "User", foreign_keys=[validated_by]
    )
