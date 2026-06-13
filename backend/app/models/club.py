"""
Club model for the gaming club application.

This module defines the Club data model, representing gaming clubs in the system.
"""

from datetime import datetime

from sqlalchemy import DateTime, Float, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Club(Base):
    """
    SQLAlchemy model representing a gaming club.

    This model stores information about gaming clubs, including their location,
    facilities, pricing, and operational hours. It also relates to bookings made at the club.
    """
    __tablename__ = "clubs"

    # Primary key for the club record
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Name of the gaming club
    name: Mapped[str] = mapped_column(String(200), nullable=False)

    # General location description
    location: Mapped[str] = mapped_column(String(500), nullable=False)

    # Optional detailed description of the club
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Total number of computers available in the club
    total_computers: Mapped[int] = mapped_column(Integer, nullable=False)

    # Optional URL to an image of the club
    image_url: Mapped[str | None] = mapped_column(String(1000), nullable=True)

    # Average rating of the club
    rating: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    # Price per hour for using computers
    price_per_hour: Mapped[int] = mapped_column(Integer, nullable=False)

    # Opening hour (24-hour format)
    opening_hour: Mapped[int] = mapped_column(Integer, nullable=False)

    # Closing hour (24-hour format)
    closing_hour: Mapped[int] = mapped_column(Integer, nullable=False)

    # Latitude coordinate for mapping
    latitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)

    # Longitude coordinate for mapping
    longitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)

    # Detailed address of the club
    address: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Timestamp when the club was added to the system
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationship to bookings made at this club
    bookings: Mapped[list["Booking"]] = relationship("Booking", back_populates="club")  # noqa: F821
