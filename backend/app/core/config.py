from pydantic_settings import BaseSettings
from functools import lru_cache
import os


class Settings(BaseSettings):
    PROJECT_NAME: str = "Arcol Protocol"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    DATABASE_URL: str = "sqlite+aiosqlite:///./arcol.db"
    REDIS_URL: str = "redis://localhost:6379/0"

    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7

    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    USE_SQLITE: bool = True

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
