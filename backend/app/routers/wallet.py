from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.wallet import TopUpRequest, TopUpResponse, WalletResponse
from app.services.wallet_service import get_wallet, top_up_wallet

router = APIRouter(prefix="/api/wallet", tags=["wallet"])


@router.get("", response_model=WalletResponse)
async def get_my_wallet(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await get_wallet(db, current_user)


@router.post("/top-up", response_model=TopUpResponse)
async def top_up(
    data: TopUpRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await top_up_wallet(db, current_user, data.amount)
