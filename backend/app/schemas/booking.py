from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class SlotItem(BaseModel):
    start_time: datetime
    duration_hours: float = Field(gt=0, le=12)


class BookingCreate(BaseModel):
    club_id: int = Field(gt=0)
    start_time: datetime
    duration_hours: float = Field(gt=0, le=12)
    computers_booked: int = Field(gt=0, le=100)
    payment_method: str = Field(default="WALLET", pattern="^(WALLET|CARD|CASH)$")


class MultiSlotBookingCreate(BaseModel):
    club_id: int = Field(gt=0)
    slots: list[SlotItem] = Field(min_length=1, max_length=10)
    computers_booked: int = Field(gt=0, le=100)
    payment_method: str = Field(default="WALLET", pattern="^(WALLET|CARD|CASH)$")


class BookingResponse(BaseModel):
    id: int
    user_id: int
    club_id: int
    club_name: Optional[str] = None
    club_location: Optional[str] = None
    start_time: datetime
    end_time: Optional[datetime] = None
    date: Optional[str] = None
    duration_hours: float
    computers_booked: int
    computers_count: Optional[int] = None
    total_price: Optional[float] = None
    payment_id: Optional[int] = None
    payment_status: Optional[str] = None
    payment_method: Optional[str] = None
    slot_details: Optional[dict] = None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class MultiSlotBookingResponse(BaseModel):
    booking: BookingResponse
    payment_id: Optional[int]
    payment_status: str
    payment_method: str
    transaction_id: Optional[int]
    reference_code: Optional[str]
    total_price: float
    message: str = "Booking created successfully"
