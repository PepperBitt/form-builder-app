import os
from functools import lru_cache


class Settings:
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:admin123@localhost:5432/formsdb",
    )
    SECRET_KEY: str = os.getenv(
        "SECRET_KEY", "your-super-secret-key-change-in-production"
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "app/storage/uploads")
    EXPORT_DIR: str = os.getenv("EXPORT_DIR", "app/storage/exports")


@lru_cache
def get_settings() -> Settings:
    return Settings()
