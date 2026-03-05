from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional
import redis
import secrets

from app.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User, ApiKey, QueueConfig, SystemSetting
from app.schemas.common import (
    ApiKeyCreate,
    ApiKeyResponse,
    QueueConfigBase,
    QueueConfigCreate,
    QueueConfigUpdate,
    QueueConfigResponse,
    QueueTestResult,
    SystemSettingBase,
    SystemSettingCreate,
    SystemSettingUpdate,
    SystemSettingResponse
)

router = APIRouter(prefix="/settings", tags=["settings"])


@router.post("/api-keys", response_model=ApiKeyResponse, status_code=status.HTTP_201_CREATED)
async def create_api_key(
    key: ApiKeyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    api_key = secrets.token_urlsafe(32)
    db_key = ApiKey(
        **key.model_dump(),
        user_id=current_user.id,
        key=api_key
    )
    db.add(db_key)
    await db.commit()
    await db.refresh(db_key)
    return db_key


@router.get("/api-keys", response_model=List[ApiKeyResponse])
async def list_api_keys(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(ApiKey).where(ApiKey.user_id == current_user.id)
    )
    return result.scalars().all()


@router.delete("/api-keys/{key_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_api_key(
    key_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(ApiKey).where(
            ApiKey.id == key_id,
            ApiKey.user_id == current_user.id
        )
    )
    key = result.scalar_one_or_none()
    if not key:
        raise HTTPException(status_code=404, detail="API key not found")
    
    await db.delete(key)
    await db.commit()
    return None


@router.post("/queue-configs", response_model=QueueConfigResponse, status_code=status.HTTP_201_CREATED)
async def create_queue_config(
    config: QueueConfigCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    db_config = QueueConfig(**config.model_dump(), user_id=current_user.id)
    db.add(db_config)
    await db.commit()
    await db.refresh(db_config)
    return db_config


@router.get("/queue-configs", response_model=List[QueueConfigResponse])
async def list_queue_configs(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(QueueConfig).where(QueueConfig.user_id == current_user.id)
    )
    return result.scalars().all()


@router.get("/queue-configs/{config_id}", response_model=QueueConfigResponse)
async def get_queue_config(
    config_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(QueueConfig).where(
            QueueConfig.id == config_id,
            QueueConfig.user_id == current_user.id
        )
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="Queue config not found")
    return config


@router.put("/queue-configs/{config_id}", response_model=QueueConfigResponse)
async def update_queue_config(
    config_id: int,
    config_update: QueueConfigUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(QueueConfig).where(
            QueueConfig.id == config_id,
            QueueConfig.user_id == current_user.id
        )
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="Queue config not found")
    
    update_data = config_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(config, key, value)
    
    await db.commit()
    await db.refresh(config)
    return config


@router.delete("/queue-configs/{config_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_queue_config(
    config_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(QueueConfig).where(
            QueueConfig.id == config_id,
            QueueConfig.user_id == current_user.id
        )
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="Queue config not found")
    
    await db.delete(config)
    await db.commit()
    return None


@router.post("/queue-configs/{config_id}/test", response_model=QueueTestResult)
async def test_queue_connection(
    config_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(QueueConfig).where(
            QueueConfig.id == config_id,
            QueueConfig.user_id == current_user.id
        )
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="Queue config not found")
    
    try:
        r = redis.Redis(
            host=config.redis_host,
            port=config.redis_port,
            db=config.redis_db,
            password=config.redis_password,
            socket_connect_timeout=5
        )
        r.ping()
        return QueueTestResult(success=True, message="Connection successful")
    except Exception as e:
        return QueueTestResult(success=False, message=str(e))


@router.post("/settings", response_model=SystemSettingResponse, status_code=status.HTTP_201_CREATED)
async def create_setting(
    setting: SystemSettingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    db_setting = SystemSetting(**setting.model_dump(), user_id=current_user.id)
    db.add(db_setting)
    await db.commit()
    await db.refresh(db_setting)
    return db_setting


@router.get("/settings", response_model=List[SystemSettingResponse])
async def list_settings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(SystemSetting).where(SystemSetting.user_id == current_user.id)
    )
    return result.scalars().all()


@router.put("/settings/{setting_id}", response_model=SystemSettingResponse)
async def update_setting(
    setting_id: int,
    setting_update: SystemSettingUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(SystemSetting).where(
            SystemSetting.id == setting_id,
            SystemSetting.user_id == current_user.id
        )
    )
    setting = result.scalar_one_or_none()
    if not setting:
        raise HTTPException(status_code=404, detail="Setting not found")
    
    if setting_update.value is not None:
        setting.value = setting_update.value
    
    await db.commit()
    await db.refresh(setting)
    return setting


@router.get("/settings/{key}", response_model=SystemSettingResponse)
async def get_setting_by_key(
    key: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(SystemSetting).where(
            SystemSetting.key == key,
            SystemSetting.user_id == current_user.id
        )
    )
    setting = result.scalar_one_or_none()
    if not setting:
        raise HTTPException(status_code=404, detail="Setting not found")
    return setting
