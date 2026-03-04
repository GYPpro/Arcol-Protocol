from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class ApiKeyBase(BaseModel):
    name: str
    provider: Optional[str] = None


class ApiKeyCreate(ApiKeyBase):
    pass


class ApiKeyResponse(ApiKeyBase):
    id: int
    key: str
    created_at: datetime

    class Config:
        from_attributes = True


class QueueConfigBase(BaseModel):
    name: str
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0
    redis_password: Optional[str] = None
    queue_name: str = "default"
    consumer_process: Optional[str] = None
    is_active: bool = True


class QueueConfigCreate(QueueConfigBase):
    pass


class QueueConfigUpdate(BaseModel):
    name: Optional[str] = None
    redis_host: Optional[str] = None
    redis_port: Optional[int] = None
    redis_db: Optional[int] = None
    redis_password: Optional[str] = None
    queue_name: Optional[str] = None
    consumer_process: Optional[str] = None
    is_active: Optional[bool] = None


class QueueConfigResponse(QueueConfigBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class QueueTestResult(BaseModel):
    success: bool
    message: str


class TodoItemBase(BaseModel):
    title: str
    description: Optional[str] = None
    priority: int = 3
    due_date: Optional[datetime] = None


class TodoItemCreate(TodoItemBase):
    pass


class TodoItemUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    priority: Optional[int] = None
    due_date: Optional[datetime] = None
    completed: Optional[bool] = None


class TodoItemResponse(TodoItemBase):
    id: int
    completed: bool
    completed_at: Optional[datetime]
    created_at: datetime
    reminder_sent: bool

    class Config:
        from_attributes = True


class TimeSessionBase(BaseModel):
    task_name: str
    description: Optional[str] = None


class TimeSessionCreate(TimeSessionBase):
    pass


class TimeSessionUpdate(BaseModel):
    end_time: Optional[datetime] = None
    duration_seconds: Optional[int] = None


class TimeSessionResponse(TimeSessionBase):
    id: int
    start_time: datetime
    end_time: Optional[datetime]
    duration_seconds: int
    created_at: datetime

    class Config:
        from_attributes = True


class TimeSessionActiveResponse(BaseModel):
    is_active: bool
    session: Optional[TimeSessionResponse] = None


class AssetBase(BaseModel):
    name: str
    symbol: str
    exchange: Optional[str] = None
    quantity: float = 0
    avg_cost: float = 0


class AssetCreate(AssetBase):
    pass


class AssetUpdate(BaseModel):
    name: Optional[str] = None
    symbol: Optional[str] = None
    exchange: Optional[str] = None
    quantity: Optional[float] = None
    avg_cost: Optional[float] = None
    current_price: Optional[float] = None


class AssetResponse(AssetBase):
    id: int
    current_price: Optional[float]
    last_updated: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True


class AssetWithValue(AssetResponse):
    total_value: float
    profit_loss: float
    profit_loss_percent: float


class AssetPriceHistoryResponse(BaseModel):
    id: int
    price: float
    timestamp: datetime

    class Config:
        from_attributes = True


class SiteRouteBase(BaseModel):
    name: str
    url: str
    group_name: Optional[str] = None
    tag: Optional[str] = None
    process_name: Optional[str] = None
    docker_container_id: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True


class SiteRouteCreate(SiteRouteBase):
    pass


class SiteRouteUpdate(BaseModel):
    name: Optional[str] = None
    url: Optional[str] = None
    group_name: Optional[str] = None
    tag: Optional[str] = None
    process_name: Optional[str] = None
    docker_container_id: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class SiteRouteResponse(SiteRouteBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class SiteRouteWithStatus(SiteRouteResponse):
    process_status: Optional["ProcessStatusResponse"] = None


class ProcessStatusResponse(BaseModel):
    id: int
    is_running: bool
    cpu_percent: float
    memory_percent: float
    memory_mb: float
    status: str
    last_check: datetime
    error_message: Optional[str]

    class Config:
        from_attributes = True


class RssFeedBase(BaseModel):
    name: str
    url: str
    feed_type: str = "rss"
    fetch_interval_minutes: int = 60
    ai_analysis_enabled: bool = True
    importance_threshold: float = 0.7
    is_active: bool = True


class RssFeedCreate(RssFeedBase):
    pass


class RssFeedUpdate(BaseModel):
    name: Optional[str] = None
    url: Optional[str] = None
    feed_type: Optional[str] = None
    fetch_interval_minutes: Optional[int] = None
    ai_analysis_enabled: Optional[bool] = None
    importance_threshold: Optional[float] = None
    is_active: Optional[bool] = None


class RssFeedResponse(RssFeedBase):
    id: int
    last_fetched: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True


class RssItemBase(BaseModel):
    title: str
    link: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None
    author: Optional[str] = None
    published_at: Optional[datetime] = None
    guid: Optional[str] = None


class RssItemResponse(RssItemBase):
    id: int
    feed_id: int
    ai_summary: Optional[str]
    ai_category: Optional[str]
    ai_importance: Optional[float]
    pushed_to_queue: bool
    created_at: datetime

    class Config:
        from_attributes = True


class SystemSettingBase(BaseModel):
    key: str
    value: Optional[str] = None


class SystemSettingCreate(SystemSettingBase):
    pass


class SystemSettingUpdate(BaseModel):
    value: Optional[str] = None


class SystemSettingResponse(SystemSettingBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class ServerMetricsResponse(BaseModel):
    id: int
    cpu_percent: float
    memory_percent: float
    memory_used_mb: float
    memory_total_mb: float
    disk_percent: float
    disk_used_gb: float
    disk_total_gb: float
    network_sent_mb: float
    network_recv_mb: float
    timestamp: datetime

    class Config:
        from_attributes = True


class MonitorThresholdBase(BaseModel):
    metric_name: str
    threshold_value: float
    comparison: str = "gt"
    is_active: bool = True


class MonitorThresholdCreate(MonitorThresholdBase):
    pass


class MonitorThresholdUpdate(BaseModel):
    threshold_value: Optional[float] = None
    comparison: Optional[str] = None
    is_active: Optional[bool] = None


class MonitorThresholdResponse(MonitorThresholdBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class AlertHistoryResponse(BaseModel):
    id: int
    alert_type: str
    title: str
    message: str
    severity: str
    is_resolved: bool
    resolved_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True


class AIRequest(BaseModel):
    prompt: str
    model: Optional[str] = None
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 2048


class AIResponse(BaseModel):
    response: str
    model: str
    usage: dict


class GuestOverview(BaseModel):
    current_focus: Optional[TimeSessionActiveResponse]
    assets_overview: List[AssetWithValue]
    site_routes_status: List[SiteRouteWithStatus]
    recent_rss_items: List[RssItemResponse]
