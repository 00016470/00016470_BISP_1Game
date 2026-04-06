from datetime import datetime

from pydantic import BaseModel, Field


class BookingCreate(BaseModel):
    club_id: int = Field(gt=0)
    start_time: datetime
    duration_hours: float = Field(gt=0, le=12)
    computers_booked: int = Field(gt=0, le=100)


class BookingResponse(BaseModel):
    id: int
    user_id: int
    club_id: int
    club_name: str | None = None
    club_location: str | None = None
    start_time: datetime
    duration_hours: float
    computers_booked: int
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
