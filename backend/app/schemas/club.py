from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ClubCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    location: str = Field(..., min_length=2, max_length=200)
    description: str = Field("", max_length=1000)
    price_per_hour: int = Field(..., ge=1000, le=10_000_000)
    total_computers: int = Field(..., ge=1, le=500)
    opening_hour: int = Field(0, ge=0, le=23)
    closing_hour: int = Field(24, ge=1, le=24)
    image_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None


class ClubUpdateRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    location: Optional[str] = Field(None, min_length=2, max_length=200)
    description: Optional[str] = None
    price_per_hour: Optional[int] = Field(None, ge=1000, le=10_000_000)
    total_computers: Optional[int] = Field(None, ge=1, le=500)
    opening_hour: Optional[int] = Field(None, ge=0, le=23)
    closing_hour: Optional[int] = Field(None, ge=1, le=24)
    image_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    is_active: Optional[bool] = None


class ClubResponse(BaseModel):
    id: int
    name: str
    location: str
    total_computers: int
    image_url: Optional[str]
    rating: float
    price_per_hour: int
    opening_hour: int
    closing_hour: int
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    address: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ClubMapResponse(BaseModel):
    id: int
    name: str
    location: str
    address: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    rating: float
    price_per_hour: int
    total_computers: int
    available_computers: int
    opening_hour: int
    closing_hour: int
    image_url: Optional[str]

    model_config = {"from_attributes": True}
