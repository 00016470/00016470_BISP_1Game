from datetime import datetime

from pydantic import BaseModel, Field


class WalletResponse(BaseModel):
    id: int
    user_id: int
    balance: float
    currency: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class TopUpRequest(BaseModel):
    amount: float = Field(gt=0, le=10_000_000, description="Amount to top up in UZS")


class TopUpResponse(BaseModel):
    wallet: WalletResponse
    transaction_id: int
    reference_code: str
    message: str = "Wallet topped up successfully"
