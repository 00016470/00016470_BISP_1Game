"""
Wallet model for the gaming club application.

This module defines the Wallet data model for managing user balances and transactions.
"""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Wallet(Base):
    """
    SQLAlchemy model representing a user's wallet for storing balance and currency.

    This model manages user funds, including balance tracking and currency information.
    It establishes relationships with users and their transactions.
    """
    __tablename__ = "wallets"

    # Primary key for the wallet record
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Foreign key to the user who owns the wallet (one-to-one relationship)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True
    )

    # Current balance in the wallet
    balance: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False, default=0.00)

    # Currency code for the wallet (e.g., UZS for Uzbek Som)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="UZS")

    # Timestamp when the wallet was created
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Timestamp when the wallet was last updated
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    # Relationship to the user who owns the wallet
    user: Mapped["User"] = relationship("User", back_populates="wallet")  # noqa: F821

    # Relationship to transactions associated with this wallet
    transactions: Mapped[list["Transaction"]] = relationship(  # noqa: F821
        "Transaction", back_populates="wallet"
    )
