from datetime import datetime

from pydantic import BaseModel, Field


class ClubResponse(BaseModel):
    id: int
    name: str
    location: str
    total_computers: int
    image_url: str | None
    rating: float
    price_per_hour: int
    opening_hour: int
    closing_hour: int
    created_at: datetime

    model_config = {"from_attributes": True}
