from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class PaymentProcessRequest(BaseModel):
    booking_id: int = Field(gt=0)
    method: str = Field(pattern="^(WALLET|CARD|CASH)$")


class PaymentResponse(BaseModel):
    id: int
    user_id: int
    booking_id: int
    transaction_id: Optional[int]
    amount: float
    method: str
    status: str
    validated_by: Optional[int]
    validated_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}


class PaymentValidateResponse(BaseModel):
    id: int
    status: str
    validated_by: int
    validated_at: datetime
    message: str = "Payment validated successfully"
