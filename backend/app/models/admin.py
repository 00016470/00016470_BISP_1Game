import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class AdminRole(str, enum.Enum):
    SUPER_ADMIN = "SUPER_ADMIN"
    CLUB_ADMIN = "CLUB_ADMIN"
    MODERATOR = "MODERATOR"


class AdminUser(Base):
    __tablename__ = "admin_users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False, unique=True, index=True
    )
    role: Mapped[AdminRole] = mapped_column(
        Enum(AdminRole, name="adminrole"), nullable=False
    )
    club_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("clubs.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship("User")  # noqa: F821
    club: Mapped["Club | None"] = relationship("Club")  # noqa: F821
