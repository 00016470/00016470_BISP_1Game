"""
Refresh token model for the gaming club application.

This module defines the RefreshToken data model for managing JWT refresh tokens.
"""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class RefreshToken(Base):
    """
    SQLAlchemy model representing a refresh token for JWT authentication.

    This model stores refresh tokens used to obtain new access tokens,
    with expiration tracking. It establishes a relationship with users.
    """
    __tablename__ = "refresh_tokens"

    # Primary key for the refresh token record
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Foreign key to the user who owns the refresh token
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    # The refresh token string
    token: Mapped[str] = mapped_column(String(512), nullable=False, unique=True, index=True)

    # Expiration timestamp of the refresh token
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    # Relationship to the user who owns the refresh token
    user: Mapped["User"] = relationship("User", back_populates="refresh_tokens")  # noqa: F821
