from pydantic import BaseModel, Field


class SlotResponse(BaseModel):
    time: str
    available_computers: int = Field(alias="availableComputers")

    model_config = {"populate_by_name": True}
