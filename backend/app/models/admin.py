"""
Admin models for the gaming club application.

This module defines the data models related to administrative users and their roles.
"""

import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class AdminRole(str, enum.Enum):
    """
    Enumeration of possible admin roles in the system.

    This enum defines the different levels of administrative privileges:
    - SUPER_ADMIN: Highest level admin with full system access.
    - CLUB_ADMIN: Admin specific to a particular club.
    - MODERATOR: Limited admin role for moderation tasks.
    """
    SUPER_ADMIN = "SUPER_ADMIN"
    CLUB_ADMIN = "CLUB_ADMIN"
    MODERATOR = "MODERATOR"


class AdminUser(Base):
    """
    SQLAlchemy model representing an administrative user in the system.

    This model links a regular user to an admin role, optionally associating
    them with a specific club. It tracks when the admin privileges were granted.
    """
    __tablename__ = "admin_users"

    # Primary key for the admin user record
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Foreign key to the users table, ensuring each user can have at most one admin role
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True
    )

    # The role assigned to this admin user
    role: Mapped[AdminRole] = mapped_column(
        Enum(AdminRole, name="adminrole"), nullable=False
    )

    # Optional foreign key to the clubs table, for club-specific admins
    club_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("clubs.id"), nullable=True
    )

    # Timestamp when this admin user was created
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationship to the User model
    user: Mapped["User"] = relationship("User")  # noqa: F821

    # Optional relationship to the Club model
    club: Mapped["Club | None"] = relationship("Club")  # noqa: F821
