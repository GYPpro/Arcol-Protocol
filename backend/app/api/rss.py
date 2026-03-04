from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional

from app.database import get_db
from app.core.security import get_current_active_user
from app.models.user import User, RssFeed, RssItem
from app.schemas.common import (
    RssFeedCreate,
    RssFeedUpdate,
    RssFeedResponse,
    RssItemResponse
)
import feedparser
from datetime import datetime

router = APIRouter(prefix="/rss", tags=["rss"])


@router.post("/feeds", response_model=RssFeedResponse, status_code=status.HTTP_201_CREATED)
async def create_feed(
    feed: RssFeedCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    db_feed = RssFeed(**feed.model_dump(), user_id=current_user.id)
    db.add(db_feed)
    await db.commit()
    await db.refresh(db_feed)
    return db_feed


@router.get("/feeds", response_model=List[RssFeedResponse])
async def list_feeds(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(RssFeed).where(RssFeed.user_id == current_user.id)
    )
    return result.scalars().all()


@router.get("/feeds/{feed_id}", response_model=RssFeedResponse)
async def get_feed(
    feed_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(RssFeed).where(
            RssFeed.id == feed_id,
            RssFeed.user_id == current_user.id
        )
    )
    feed = result.scalar_one_or_none()
    if not feed:
        raise HTTPException(status_code=404, detail="Feed not found")
    return feed


@router.put("/feeds/{feed_id}", response_model=RssFeedResponse)
async def update_feed(
    feed_id: int,
    feed_update: RssFeedUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(RssFeed).where(
            RssFeed.id == feed_id,
            RssFeed.user_id == current_user.id
        )
    )
    feed = result.scalar_one_or_none()
    if not feed:
        raise HTTPException(status_code=404, detail="Feed not found")
    
    update_data = feed_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(feed, key, value)
    
    await db.commit()
    await db.refresh(feed)
    return feed


@router.delete("/feeds/{feed_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_feed(
    feed_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(RssFeed).where(
            RssFeed.id == feed_id,
            RssFeed.user_id == current_user.id
        )
    )
    feed = result.scalar_one_or_none()
    if not feed:
        raise HTTPException(status_code=404, detail="Feed not found")
    
    await db.delete(feed)
    await db.commit()
    return None


@router.post("/feeds/{feed_id}/fetch")
async def fetch_feed(
    feed_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(RssFeed).where(
            RssFeed.id == feed_id,
            RssFeed.user_id == current_user.id
        )
    )
    feed = result.scalar_one_or_none()
    if not feed:
        raise HTTPException(status_code=404, detail="Feed not found")
    
    try:
        parsed = feedparser.parse(feed.url)
        entries_added = 0
        
        for entry in parsed.entries[:20]:
            existing = await db.execute(
                select(RssItem).where(
                    RssItem.feed_id == feed_id,
                    RssItem.guid == entry.get("id", entry.link)
                )
            )
            if existing.scalar_one_or_none():
                continue
            
            published = None
            if hasattr(entry, "published_parsed") and entry.published_parsed:
                try:
                    from time import mktime
                    published = datetime.fromtimestamp(mktime(entry.published_parsed))
                except:
                    pass
            
            db_item = RssItem(
                feed_id=feed_id,
                title=entry.get("title", "Untitled"),
                link=entry.get("link"),
                description=entry.get("summary"),
                content=entry.get("content", [{}])[0].get("value") if hasattr(entry, "content") else None,
                author=entry.get("author"),
                published_at=published,
                guid=entry.get("id", entry.link)
            )
            db.add(db_item)
            entries_added += 1
        
        feed.last_fetched = datetime.utcnow()
        await db.commit()
        
        return {"success": True, "entries_added": entries_added}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/feeds/{feed_id}/items", response_model=List[RssItemResponse])
async def get_feed_items(
    feed_id: int,
    skip: int = 0,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(RssItem)
        .where(RssItem.feed_id == feed_id)
        .order_by(RssItem.published_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


@router.get("/items", response_model=List[RssItemResponse])
async def get_all_items(
    skip: int = 0,
    limit: int = 50,
    min_importance: Optional[float] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    query = select(RssItem).order_by(RssItem.published_at.desc())
    
    if min_importance is not None:
        query = query.where(RssItem.ai_importance >= min_importance)
    
    query = query.offset(skip).limit(limit)
    
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/items/recent", response_model=List[RssItemResponse])
async def get_recent_items(
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    result = await db.execute(
        select(RssItem)
        .order_by(RssItem.published_at.desc())
        .limit(limit)
    )
    return result.scalars().all()
