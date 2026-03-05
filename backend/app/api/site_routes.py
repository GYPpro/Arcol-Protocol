from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional

from app.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User, SiteRoute, ProcessStatus
from app.schemas.common import (
    SiteRouteCreate,
    SiteRouteUpdate,
    SiteRouteResponse,
    SiteRouteWithStatus,
    ProcessStatusResponse
)
import psutil
import subprocess

router = APIRouter(prefix="/site-routes", tags=["site-routes"])


@router.post("/", response_model=SiteRouteResponse, status_code=status.HTTP_201_CREATED)
async def create_site_route(
    route: SiteRouteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    db_route = SiteRoute(**route.model_dump(), user_id=current_user.id)
    db.add(db_route)
    await db.commit()
    await db.refresh(db_route)
    return db_route


@router.get("/", response_model=List[SiteRouteWithStatus])
async def list_routes(
    group: Optional[str] = None,
    tag: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    query = select(SiteRoute).where(SiteRoute.user_id == current_user.id)
    
    if group:
        query = query.where(SiteRoute.group_name == group)
    if tag:
        query = query.where(SiteRoute.tag == tag)
    
    query = query.order_by(SiteRoute.sort_order.asc())
    
    result = await db.execute(query)
    routes = result.scalars().all()
    
    response = []
    for route in routes:
        status_result = await db.execute(
            select(ProcessStatus)
            .where(ProcessStatus.site_route_id == route.id)
            .order_by(ProcessStatus.last_check.desc())
        )
        process_status = status_result.scalars().first()
        
        if process_status and process_status.last_check:
            import datetime as dt
            if (dt.datetime.utcnow() - process_status.last_check).seconds > 60:
                process_status = await check_process_status(route, db)
        
        response.append(SiteRouteWithStatus(
            **SiteRouteResponse.model_validate(route).model_dump(),
            process_status=ProcessStatusResponse.model_validate(process_status) if process_status else None
        ))
    
    return response


async def check_process_status(route: SiteRoute, db: AsyncSession):
    is_running = False
    cpu_percent = 0
    memory_percent = 0
    memory_mb = 0
    error_message = None
    proc_status = "stopped"
    
    try:
        if route.docker_container_id:
            result = subprocess.run(
                ["docker", "inspect", "-f", "{{.State.Running}}", route.docker_container_id],
                capture_output=True, text=True
            )
            is_running = result.returncode == 0 and "true" in result.stdout.lower()
            if is_running:
                result = subprocess.run(
                    ["docker", "stats", "--no-stream", "--format", "{{.CPUPerc}}|{{.MemPerc}}|{{.MemUsage}}", route.docker_container_id],
                    capture_output=True, text=True
                )
                if result.returncode == 0 and result.stdout:
                    parts = result.stdout.strip().split("|")
                    if len(parts) == 3:
                        cpu_percent = float(parts[0].replace("%", ""))
                        memory_percent = float(parts[1].replace("%", ""))
                        mem_parts = parts[2].split("/")
                        if mem_parts:
                            memory_mb = convert_to_mb(mem_parts[0].strip())
                proc_status = "running"
        elif route.process_name:
            for proc in psutil.process_iter(['name', 'cpu_percent', 'memory_percent', 'memory_info']):
                try:
                    if route.process_name in proc.info['name']:
                        is_running = True
                        cpu_percent += proc.info['cpu_percent'] or 0
                        memory_percent += proc.info['memory_percent'] or 0
                        memory_mb += proc.info['memory_info'].rss / 1024 / 1024
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
            proc_status = "running" if is_running else "stopped"
    except Exception as e:
        error_message = str(e)
        proc_status = "error"
    
    from datetime import datetime
    db_status = ProcessStatus(
        site_route_id=route.id,
        is_running=is_running,
        cpu_percent=cpu_percent,
        memory_percent=memory_percent,
        memory_mb=memory_mb,
        status=proc_status,
        last_check=datetime.utcnow(),
        error_message=error_message
    )
    db.add(db_status)
    await db.commit()
    await db.refresh(db_status)
    return db_status


def convert_to_mb(mem_str: str) -> float:
    mem_str = mem_str.strip().upper()
    if "GiB" in mem_str or "GB" in mem_str:
        return float(mem_str.replace("GiB", "").replace("GB", "").strip()) * 1024
    elif "MiB" in mem_str or "MB" in mem_str:
        return float(mem_str.replace("MiB", "").replace("MB", "").strip())
    elif "KiB" in mem_str or "KB" in mem_str:
        return float(mem_str.replace("KiB", "").replace("KB", "").strip()) / 1024
    return 0


@router.get("/{route_id}", response_model=SiteRouteWithStatus)
async def get_route(
    route_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(SiteRoute).where(
            SiteRoute.id == route_id,
            SiteRoute.user_id == current_user.id
        )
    )
    route = result.scalar_one_or_none()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    
    status_result = await db.execute(
        select(ProcessStatus)
        .where(ProcessStatus.site_route_id == route.id)
        .order_by(ProcessStatus.last_check.desc())
    )
    process_status = status_result.scalars().first()
    
    return SiteRouteWithStatus(
        **SiteRouteResponse.model_validate(route).model_dump(),
        process_status=ProcessStatusResponse.model_validate(process_status) if process_status else None
    )


@router.put("/{route_id}", response_model=SiteRouteResponse)
async def update_route(
    route_id: int,
    route_update: SiteRouteUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(SiteRoute).where(
            SiteRoute.id == route_id,
            SiteRoute.user_id == current_user.id
        )
    )
    route = result.scalar_one_or_none()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    
    update_data = route_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(route, key, value)
    
    await db.commit()
    await db.refresh(route)
    return route


@router.delete("/{route_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_route(
    route_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(SiteRoute).where(
            SiteRoute.id == route_id,
            SiteRoute.user_id == current_user.id
        )
    )
    route = result.scalar_one_or_none()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    
    await db.delete(route)
    await db.commit()
    return None


@router.post("/{route_id}/refresh-status", response_model=ProcessStatusResponse)
async def refresh_status(
    route_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(SiteRoute).where(
            SiteRoute.id == route_id,
            SiteRoute.user_id == current_user.id
        )
    )
    route = result.scalar_one_or_none()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    
    status = await check_process_status(route, db)
    return status
