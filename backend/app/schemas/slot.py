from pydantic import BaseModel


class SlotResponse(BaseModel):
    id: int
    start_time: str   # "HH:MM"
    end_time: str     # "HH:MM"
    total_computers: int
    available_computers: int
    is_available: bool
