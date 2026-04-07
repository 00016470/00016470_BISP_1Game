from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class TransactionResponse(BaseModel):
    id: int
    wallet_id: int
    user_id: int
    booking_id: Optional[int]
    type: str
    amount: float
    balance_before: float
    balance_after: float
    status: str
    description: str
    reference_code: str
    created_at: datetime

    model_config = {"from_attributes": True}


class TransactionSummary(BaseModel):
    total_spent: float
    total_top_ups: float
    total_refunds: float
    current_balance: float
    transaction_count: int


class TransactionListResponse(BaseModel):
    items: list[TransactionResponse]
    total: int
    page: int
    per_page: int
    pages: int
