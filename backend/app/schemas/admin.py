from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class RevenueByDay(BaseModel):
    date: str
    revenue: float
    booking_count: int


class BookingsByClub(BaseModel):
    club_id: int
    club_name: str
    booking_count: int
    revenue: float


class DashboardResponse(BaseModel):
    total_revenue_today: float
    active_bookings: int
    pending_payments: int
    total_users: int
    pending_users: int
    bookings_by_club: list[BookingsByClub]
    revenue_by_day: list[RevenueByDay]


class AdminBookingResponse(BaseModel):
    id: int
    user_id: int
    username: str
    club_id: int
    club_name: str
    start_time: datetime
    duration_hours: float
    computers_booked: int
    total_price: Optional[float]
    status: str
    payment_status: Optional[str]
    payment_method: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class AdminPaymentResponse(BaseModel):
    id: int
    user_id: int
    username: str
    booking_id: int
    club_name: str
    amount: float
    method: str
    status: str
    validated_by: Optional[int]
    validated_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}


class AdminUserResponse(BaseModel):
    id: int
    username: str
    email: str
    phone: Optional[str]
    is_approved: bool
    booking_count: int
    total_spent: float
    wallet_balance: float
    joined_at: str

    model_config = {"from_attributes": True}


class AdminUserDetailResponse(BaseModel):
    id: int
    username: str
    email: str
    phone: Optional[str]
    is_approved: bool
    joined_at: str
    wallet_balance: float
    currency: str
    total_spent: float
    booking_count: int
    bookings: list
    payments: list
    transactions: list


class ClubLiveResponse(BaseModel):
    club_id: int
    club_name: str
    total_computers: int
    active_sessions: int
    available_computers: int
    occupancy_percent: float
    upcoming_bookings_today: int


class ClubSessionItem(BaseModel):
    booking_id: int
    user_id: int
    username: str
    computers_booked: int
    start_time: datetime
    end_time: datetime
    remaining_minutes: float
    total_price: Optional[float]
    status: str


class ClubSessionsResponse(BaseModel):
    club_id: int
    club_name: str
    total_computers: int
    active_sessions: list[ClubSessionItem]
    upcoming_sessions: list[ClubSessionItem]
    available_computers: int


class ClubRevenueResponse(BaseModel):
    club_id: int
    club_name: str
    total_revenue: float
    total_sessions: int
    active_sessions: int
    revenue_by_day: list[RevenueByDay]
    recent_sessions: list[ClubSessionItem]

