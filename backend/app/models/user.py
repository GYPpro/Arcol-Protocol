from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, Float, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    api_keys = relationship("ApiKey", back_populates="user", cascade="all, delete-orphan")
    todo_items = relationship("TodoItem", back_populates="user", cascade="all, delete-orphan")
    time_sessions = relationship("TimeSession", back_populates="user", cascade="all, delete-orphan")
    assets = relationship("Asset", back_populates="user", cascade="all, delete-orphan")
    site_routes = relationship("SiteRoute", back_populates="user", cascade="all, delete-orphan")
    rss_feeds = relationship("RssFeed", back_populates="user", cascade="all, delete-orphan")
    settings = relationship("SystemSetting", back_populates="user", cascade="all, delete-orphan")


class ApiKey(Base):
    __tablename__ = "api_keys"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    key = Column(String(255), unique=True, index=True, nullable=False)
    provider = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_used_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="api_keys")


class QueueConfig(Base):
    __tablename__ = "queue_configs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    redis_host = Column(String(100), default="localhost")
    redis_port = Column(Integer, default=6379)
    redis_db = Column(Integer, default=0)
    redis_password = Column(String(255), nullable=True)
    queue_name = Column(String(100), default="default")
    consumer_process = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class TodoItem(Base):
    __tablename__ = "todo_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    priority = Column(Integer, default=3)
    due_date = Column(DateTime(timezone=True), nullable=True)
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    reminder_sent = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="todo_items")


class TimeSession(Base):
    __tablename__ = "time_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    task_name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=True)
    duration_seconds = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="time_sessions")


class Asset(Base):
    __tablename__ = "assets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    symbol = Column(String(20), nullable=False)
    exchange = Column(String(50), nullable=True)
    quantity = Column(Float, default=0)
    avg_cost = Column(Float, default=0)
    current_price = Column(Float, nullable=True)
    last_updated = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="assets")


class AssetPriceHistory(Base):
    __tablename__ = "asset_price_history"

    id = Column(Integer, primary_key=True, index=True)
    asset_id = Column(Integer, ForeignKey("assets.id", ondelete="CASCADE"), nullable=False)
    price = Column(Float, nullable=False)
    timestamp = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class SiteRoute(Base):
    __tablename__ = "site_routes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    url = Column(String(500), nullable=False)
    group_name = Column(String(50), nullable=True)
    tag = Column(String(50), nullable=True)
    process_name = Column(String(100), nullable=True)
    docker_container_id = Column(String(100), nullable=True)
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="site_routes")


class ProcessStatus(Base):
    __tablename__ = "process_status"

    id = Column(Integer, primary_key=True, index=True)
    site_route_id = Column(Integer, ForeignKey("site_routes.id", ondelete="CASCADE"), nullable=False)
    is_running = Column(Boolean, default=False)
    cpu_percent = Column(Float, default=0)
    memory_percent = Column(Float, default=0)
    memory_mb = Column(Float, default=0)
    status = Column(String(50), default="unknown")
    last_check = Column(DateTime(timezone=True), server_default=func.now())
    error_message = Column(Text, nullable=True)


class RssFeed(Base):
    __tablename__ = "rss_feeds"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    url = Column(String(500), nullable=False)
    feed_type = Column(String(20), default="rss")
    fetch_interval_minutes = Column(Integer, default=60)
    ai_analysis_enabled = Column(Boolean, default=True)
    importance_threshold = Column(Float, default=0.7)
    last_fetched = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="rss_feeds")
    items = relationship("RssItem", back_populates="feed", cascade="all, delete-orphan")


class RssItem(Base):
    __tablename__ = "rss_items"

    id = Column(Integer, primary_key=True, index=True)
    feed_id = Column(Integer, ForeignKey("rss_feeds.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(500), nullable=False)
    link = Column(String(1000), nullable=True)
    description = Column(Text, nullable=True)
    content = Column(Text, nullable=True)
    author = Column(String(100), nullable=True)
    published_at = Column(DateTime(timezone=True), nullable=True)
    guid = Column(String(500), nullable=True)
    ai_summary = Column(Text, nullable=True)
    ai_category = Column(String(100), nullable=True)
    ai_importance = Column(Float, nullable=True)
    pushed_to_queue = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    feed = relationship("RssFeed", back_populates="items")


class SystemSetting(Base):
    __tablename__ = "system_settings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    key = Column(String(100), nullable=False)
    value = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="settings")


class ServerMetrics(Base):
    __tablename__ = "server_metrics"

    id = Column(Integer, primary_key=True, index=True)
    cpu_percent = Column(Float, default=0)
    memory_percent = Column(Float, default=0)
    memory_used_mb = Column(Float, default=0)
    memory_total_mb = Column(Float, default=0)
    disk_percent = Column(Float, default=0)
    disk_used_gb = Column(Float, default=0)
    disk_total_gb = Column(Float, default=0)
    network_sent_mb = Column(Float, default=0)
    network_recv_mb = Column(Float, default=0)
    timestamp = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class MonitorThreshold(Base):
    __tablename__ = "monitor_thresholds"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    metric_name = Column(String(50), nullable=False)
    threshold_value = Column(Float, nullable=False)
    comparison = Column(String(10), default="gt")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class AlertHistory(Base):
    __tablename__ = "alert_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    alert_type = Column(String(50), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    severity = Column(String(20), default="info")
    is_resolved = Column(Boolean, default=False)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
