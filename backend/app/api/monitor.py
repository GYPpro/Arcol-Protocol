from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional
from datetime import datetime, timedelta

from app.database import get_db
from app.core.security import get_current_active_user
from app.models.user import User, ServerMetrics, MonitorThreshold, AlertHistory
from app.schemas.common import (
    ServerMetricsResponse,
    MonitorThresholdCreate,
    MonitorThresholdUpdate,
    MonitorThresholdResponse,
    AlertHistoryResponse
)
import psutil

router = APIRouter(prefix="/monitor", tags=["monitor"])


@router.get("/metrics", response_model=ServerMetricsResponse)
async def get_current_metrics():
    cpu = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    net_io = psutil.net_io_counters()
    
    return ServerMetricsResponse(
        id=0,
        cpu_percent=cpu,
        memory_percent=memory.percent,
        memory_used_mb=memory.used / 1024 / 1024,
        memory_total_mb=memory.total / 1024 / 1024,
        disk_percent=disk.percent,
        disk_used_gb=disk.used / 1024 / 1024 / 1024,
        disk_total_gb=disk.total / 1024 / 1024,
        network_sent_mb=net_io.bytes_sent / 1024 / 1024,
        network_recv_mb=net_io.bytes_recv / 1024 / 1024,
        timestamp=datetime.utcnow()
    )


@router.get("/metrics/history", response_model=List[ServerMetricsResponse])
async def get_metrics_history(
    hours: int = 24,
    db: AsyncSession = Depends(get_db)
):
    start_time = datetime.utcnow() - timedelta(hours=hours)
    
    result = await db.execute(
        select(ServerMetrics)
        .where(ServerMetrics.timestamp >= start_time)
        .order_by(ServerMetrics.timestamp.asc())
    )
    return result.scalars().all()


@router.post("/metrics")
async def save_metrics(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    cpu = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    net_io = psutil.net_io_counters()
    
    metrics = ServerMetrics(
        cpu_percent=cpu,
        memory_percent=memory.percent,
        memory_used_mb=memory.used / 1024 / 1024,
        memory_total_mb=memory.total / 1024 / 1024,
        disk_percent=disk.percent,
        disk_used_gb=disk.used / 1024 / 1024 / 1024,
        disk_total_gb=disk.total / 1024 / 1024,
        network_sent_mb=net_io.bytes_sent / 1024 / 1024,
        network_recv_mb=net_io.bytes_recv / 1024 / 1024,
        timestamp=datetime.utcnow()
    )
    db.add(metrics)
    await db.commit()
    
    await check_thresholds(db, current_user.id, cpu, memory.percent, disk.percent)
    
    return {"success": True}


async def check_thresholds(db: AsyncSession, user_id: int, cpu: float, memory: float, disk: float):
    result = await db.execute(
        select(MonitorThreshold).where(
            MonitorThreshold.user_id == user_id,
            MonitorThreshold.is_active == True
        )
    )
    thresholds = result.scalars().all()
    
    metrics_map = {
        "cpu": cpu,
        "memory": memory,
        "disk": disk
    }
    
    for threshold in thresholds:
        value = metrics_map.get(threshold.metric_name)
        if value is None:
            continue
        
        is_triggered = False
        if threshold.comparison == "gt" and value > threshold.threshold_value:
            is_triggered = True
        elif threshold.comparison == "lt" and value < threshold.threshold_value:
            is_triggered = True
        elif threshold.comparison == "eq" and value == threshold.threshold_value:
            is_triggered = True
        
        if is_triggered:
            alert = AlertHistory(
                user_id=user_id,
                alert_type=f"threshold_{threshold.metric_name}",
                title=f"{threshold.metric_name.capitalize()} threshold exceeded",
                message=f"{threshold.metric_name} is {value:.1f}%, threshold is {threshold.threshold_value}%",
                severity="warning"
            )
            db.add(alert)
    
    await db.commit()


@router.post("/thresholds", response_model=MonitorThresholdResponse, status_code=status.HTTP_201_CREATED)
async def create_threshold(
    threshold: MonitorThresholdCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    db_threshold = MonitorThreshold(**threshold.model_dump(), user_id=current_user.id)
    db.add(db_threshold)
    await db.commit()
    await db.refresh(db_threshold)
    return db_threshold


@router.get("/thresholds", response_model=List[MonitorThresholdResponse])
async def list_thresholds(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(MonitorThreshold).where(MonitorThreshold.user_id == current_user.id)
    )
    return result.scalars().all()


@router.put("/thresholds/{threshold_id}", response_model=MonitorThresholdResponse)
async def update_threshold(
    threshold_id: int,
    threshold_update: MonitorThresholdUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(MonitorThreshold).where(
            MonitorThreshold.id == threshold_id,
            MonitorThreshold.user_id == current_user.id
        )
    )
    threshold = result.scalar_one_or_none()
    if not threshold:
        raise HTTPException(status_code=404, detail="Threshold not found")
    
    update_data = threshold_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(threshold, key, value)
    
    await db.commit()
    await db.refresh(threshold)
    return threshold


@router.delete("/thresholds/{threshold_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_threshold(
    threshold_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(MonitorThreshold).where(
            MonitorThreshold.id == threshold_id,
            MonitorThreshold.user_id == current_user.id
        )
    )
    threshold = result.scalar_one_or_none()
    if not threshold:
        raise HTTPException(status_code=404, detail="Threshold not found")
    
    await db.delete(threshold)
    await db.commit()
    return None


@router.get("/alerts", response_model=List[AlertHistoryResponse])
async def list_alerts(
    resolved: Optional[bool] = False,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(AlertHistory)
        .where(AlertHistory.user_id == current_user.id)
        .where(AlertHistory.is_resolved == resolved)
        .order_by(AlertHistory.created_at.desc())
        .limit(limit)
    )
    return result.scalars().all()


@router.post("/alerts/{alert_id}/resolve")
async def resolve_alert(
    alert_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(AlertHistory).where(
            AlertHistory.id == alert_id,
            AlertHistory.user_id == current_user.id
        )
    )
    alert = result.scalar_one_or_none()
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    alert.is_resolved = True
    alert.resolved_at = datetime.utcnow()
    await db.commit()
    
    return {"success": True}
