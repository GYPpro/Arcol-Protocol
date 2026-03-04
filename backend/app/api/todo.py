from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from datetime import datetime

from app.database import get_db
from app.core.security import get_current_active_user
from app.models.user import User, TodoItem
from app.schemas.common import TodoItemCreate, TodoItemUpdate, TodoItemResponse

router = APIRouter(prefix="/todos", tags=["todos"])


def get_current_active_user():
    from app.api.deps import get_current_user
    return get_current_user


@router.post("/", response_model=TodoItemResponse, status_code=status.HTTP_201_CREATED)
async def create_todo(
    item: TodoItemCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    db_item = TodoItem(**item.model_dump(), user_id=current_user.id)
    db.add(db_item)
    await db.commit()
    await db.refresh(db_item)
    return db_item


@router.get("/", response_model=List[TodoItemResponse])
async def list_todos(
    completed: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TodoItem)
        .where(TodoItem.user_id == current_user.id)
        .where(TodoItem.completed == completed)
        .order_by(TodoItem.priority.asc(), TodoItem.due_date.asc())
    )
    return result.scalars().all()


@router.get("/{item_id}", response_model=TodoItemResponse)
async def get_todo(
    item_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TodoItem).where(
            TodoItem.id == item_id,
            TodoItem.user_id == current_user.id
        )
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Todo item not found")
    return item


@router.put("/{item_id}", response_model=TodoItemResponse)
async def update_todo(
    item_id: int,
    item_update: TodoItemUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TodoItem).where(
            TodoItem.id == item_id,
            TodoItem.user_id == current_user.id
        )
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Todo item not found")
    
    update_data = item_update.model_dump(exclude_unset=True)
    if "completed" in update_data and update_data["completed"]:
        update_data["completed_at"] = datetime.utcnow()
    elif "completed" in update_data and not update_data["completed"]:
        update_data["completed_at"] = None
    
    for key, value in update_data.items():
        setattr(item, key, value)
    
    await db.commit()
    await db.refresh(item)
    return item


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_todo(
    item_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(TodoItem).where(
            TodoItem.id == item_id,
            TodoItem.user_id == current_user.id
        )
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Todo item not found")
    
    await db.delete(item)
    await db.commit()
    return None
