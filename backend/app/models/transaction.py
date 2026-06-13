"""
Transaction model for the gaming club application.

This module defines the Transaction data model and related enums for tracking
financial transactions in the system.
"""

import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class TransactionType(str, enum.Enum):
    """
    Enumeration of possible transaction types.

    This enum defines the categories of transactions:
    - TOP_UP: Adding funds to the wallet.
    - BOOKING_PAYMENT: Payment for a booking.
    - REFUND: Refund of a payment.
    - ADMIN_ADJUSTMENT: Manual adjustment by an admin.
    """
    TOP_UP = "TOP_UP"
    BOOKING_PAYMENT = "BOOKING_PAYMENT"
    REFUND = "REFUND"
    ADMIN_ADJUSTMENT = "ADMIN_ADJUSTMENT"


class TransactionStatus(str, enum.Enum):
    """
    Enumeration of possible transaction statuses.

    This enum defines the lifecycle states of a transaction:
    - PENDING: Transaction is initiated but not yet completed.
    - COMPLETED: Transaction has been successfully processed.
    - FAILED: Transaction attempt failed.
    - REVERSED: Transaction has been reversed.
    """
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    REVERSED = "REVERSED"


class Transaction(Base):
    """
    SQLAlchemy model representing a financial transaction.

    This model records all wallet transactions, including balance changes,
    transaction types, and status. It establishes relationships with
    wallets, users, and bookings.
    """
    __tablename__ = "transactions"

    # Primary key for the transaction record
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Foreign key to the wallet involved in the transaction
    wallet_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("wallets.id"), nullable=False, index=True
    )

    # Foreign key to the user who initiated the transaction
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )

    # Optional foreign key to the booking related to the transaction
    booking_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("bookings.id"), nullable=True
    )

    # Type of the transaction
    type: Mapped[TransactionType] = mapped_column(
        Enum(TransactionType, name="transactiontype"), nullable=False
    )

    # Amount involved in the transaction
    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)

    # Wallet balance before the transaction
    balance_before: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)

    # Wallet balance after the transaction
    balance_after: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)

    # Current status of the transaction
    status: Mapped[TransactionStatus] = mapped_column(
        Enum(TransactionStatus, name="transactionstatus"),
        nullable=False,
        default=TransactionStatus.COMPLETED,
    )

    # Description of the transaction
    description: Mapped[str] = mapped_column(Text, nullable=False)

    # Unique reference code for the transaction
    reference_code: Mapped[str] = mapped_column(
        String(32), nullable=False, unique=True, index=True
    )

    # Timestamp when the transaction was created
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationship to the wallet involved
    wallet: Mapped["Wallet"] = relationship("Wallet", back_populates="transactions")  # noqa: F821

    # Relationship to the user who initiated the transaction
    user: Mapped["User"] = relationship("User")  # noqa: F821

    # Optional relationship to the related booking
    booking: Mapped["Booking | None"] = relationship("Booking")  # noqa: F821
