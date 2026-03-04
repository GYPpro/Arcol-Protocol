from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from datetime import datetime

from app.database import get_db
from app.core.security import get_current_active_user
from app.models.user import User, TimeSession
from app.schemas.common import (
    TimeSessionCreate,
    TimeSessionUpdate,
    TimeSessionResponse,
    TimeSessionActiveResponse
)

router = APIRouter(prefix="/time-tracking", tags=["time-tracking"])


@router.post("/sessions", response_model=TimeSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    session: TimeSessionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    active_result = await db.execute(
        select(TimeSession).where(
            TimeSession.user_id == current_user.id,
            TimeSession.end_time.is_(None)
        )
    )
    if active_result.scalar_one_or_none():
        raise HTTPException(
            status_code=400,
            detail="There is already an active session. End it first."
        )
    
    db_session = TimeSession(
        **session.model_dump(),
        user_id=current_user.id,
        start_time=datetime.utcnow()
    )
    db.add(db_session)
    await db.commit()
    await db.refresh(db_session)
    return db_session


@router.get("/sessions/active", response_model=TimeSessionActiveResponse)
async def get_active_session(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TimeSession).where(
            TimeSession.user_id == current_user.id,
            TimeSession.end_time.is_(None)
        ).order_by(TimeSession.start_time.desc())
    )
    session = result.scalar_one_or_none()
    if session:
        session.duration_seconds = int((datetime.utcnow() - session.start_time).total_seconds())
    return TimeSessionActiveResponse(is_active=session is not None, session=session)


@router.get("/sessions", response_model=List[TimeSessionResponse])
async def list_sessions(
    skip: int = 0,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TimeSession)
        .where(TimeSession.user_id == current_user.id)
        .order_by(TimeSession.start_time.desc())
        .offset(skip)
        .limit(limit)
    )
    sessions = result.scalars().all()
    now = datetime.utcnow()
    for session in sessions:
        if session.end_time is None:
            session.duration_seconds = int((now - session.start_time).total_seconds())
    return sessions


@router.get("/sessions/{session_id}", response_model=TimeSessionResponse)
async def get_session(
    session_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TimeSession).where(
            TimeSession.id == session_id,
            TimeSession.user_id == current_user.id
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session


@router.put("/sessions/{session_id}/stop", response_model=TimeSessionResponse)
async def stop_session(
    session_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TimeSession).where(
            TimeSession.id == session_id,
            TimeSession.user_id == current_user.id
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.end_time:
        raise HTTPException(status_code=400, detail="Session already ended")
    
    session.end_time = datetime.utcnow()
    session.duration_seconds = int((session.end_time - session.start_time).total_seconds())
    
    await db.commit()
    await db.refresh(session)
    return session


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(
    session_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TimeSession).where(
            TimeSession.id == session_id,
            TimeSession.user_id == current_user.id
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    await db.delete(session)
    await db.commit()
    return None


@router.get("/stats/today")
async def get_today_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    result = await db.execute(
        select(TimeSession).where(
            TimeSession.user_id == current_user.id,
            TimeSession.start_time >= today_start,
            TimeSession.end_time.isnot(None)
        )
    )
    sessions = result.scalars().all()
    
    total_seconds = sum(s.duration_seconds for s in sessions)
    session_count = len(sessions)
    
    return {
        "total_seconds": total_seconds,
        "total_minutes": total_seconds // 60,
        "total_hours": total_seconds / 3600,
        "session_count": session_count
    }
