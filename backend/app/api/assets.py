from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from datetime import datetime

from app.database import get_db
from app.core.security import get_current_active_user
from app.models.user import User, Asset, AssetPriceHistory
from app.schemas.common import (
    AssetCreate,
    AssetUpdate,
    AssetResponse,
    AssetWithValue,
    AssetPriceHistoryResponse
)

router = APIRouter(prefix="/assets", tags=["assets"])


@router.post("/", response_model=AssetResponse, status_code=status.HTTP_201_CREATED)
async def create_asset(
    asset: AssetCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    db_asset = Asset(**asset.model_dump(), user_id=current_user.id)
    db.add(db_asset)
    await db.commit()
    await db.refresh(db_asset)
    return db_asset


@router.get("/", response_model=List[AssetWithValue])
async def list_assets(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(Asset).where(Asset.user_id == current_user.id)
    )
    assets = result.scalars().all()
    
    response = []
    for asset in assets:
        total_value = asset.quantity * (asset.current_price or 0)
        cost_basis = asset.quantity * asset.avg_cost
        profit_loss = total_value - cost_basis
        profit_loss_percent = (profit_loss / cost_basis * 100) if cost_basis > 0 else 0
        
        response.append(AssetWithValue(
            **AssetResponse.model_validate(asset).model_dump(),
            total_value=total_value,
            profit_loss=profit_loss,
            profit_loss_percent=profit_loss_percent
        ))
    return response


@router.get("/{asset_id}", response_model=AssetResponse)
async def get_asset(
    asset_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(Asset).where(
            Asset.id == asset_id,
            Asset.user_id == current_user.id
        )
    )
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return asset


@router.put("/{asset_id}", response_model=AssetResponse)
async def update_asset(
    asset_id: int,
    asset_update: AssetUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(Asset).where(
            Asset.id == asset_id,
            Asset.user_id == current_user.id
        )
    )
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    
    update_data = asset_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(asset, key, value)
    
    await db.commit()
    await db.refresh(asset)
    return asset


@router.delete("/{asset_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_asset(
    asset_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(Asset).where(
            Asset.id == asset_id,
            Asset.user_id == current_user.id
        )
    )
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    
    await db.delete(asset)
    await db.commit()
    return None


@router.get("/{asset_id}/history", response_model=List[AssetPriceHistoryResponse])
async def get_asset_history(
    asset_id: int,
    days: int = 30,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(Asset).where(
            Asset.id == asset_id,
            Asset.user_id == current_user.id
        )
    )
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    
    from datetime import timedelta
    start_date = datetime.utcnow() - timedelta(days=days)
    
    history_result = await db.execute(
        select(AssetPriceHistory)
        .where(AssetPriceHistory.asset_id == asset_id)
        .where(AssetPriceHistory.timestamp >= start_date)
        .order_by(AssetPriceHistory.timestamp.asc())
    )
    return history_result.scalars().all()
