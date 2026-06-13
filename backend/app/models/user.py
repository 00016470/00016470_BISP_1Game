"""
User model for the gaming club application.

This module defines the User data model, representing registered users in the system.
"""

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    """
    SQLAlchemy model representing a user in the gaming club system.

    This model stores user authentication details, contact information,
    and approval status. It also establishes relationships with bookings,
    refresh tokens, and wallet.
    """
    __tablename__ = "users"

    # Primary key for the user record
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Unique username for the user
    username: Mapped[str] = mapped_column(String(100), nullable=False, unique=True, index=True)

    # Unique email address for the user
    email: Mapped[str] = mapped_column(String(255), nullable=False, unique=True, index=True)

    # Hashed password for authentication
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)

    # Optional phone number
    phone: Mapped[str | None] = mapped_column(String(30), nullable=True)

    # Flag indicating if the user account is approved
    is_approved: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="true"
    )

    # Timestamp when the user account was created
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationship to the user's bookings
    bookings: Mapped[list["Booking"]] = relationship("Booking", back_populates="user")  # noqa: F821

    # Relationship to the user's refresh tokens
    refresh_tokens: Mapped[list["RefreshToken"]] = relationship("RefreshToken", back_populates="user")  # noqa: F821

    # Relationship to the user's wallet (one-to-one)
    wallet: Mapped["Wallet | None"] = relationship("Wallet", back_populates="user", uselist=False)  # noqa: F821
