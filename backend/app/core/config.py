import os
from functools import lru_cache
from dotenv import load_dotenv

load_dotenv()


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
    GOOGLE_CLIENT_ID: str = os.getenv("GOOGLE_CLIENT_ID", "")
    BASE_URL: str = os.getenv("BASE_URL", "http://localhost:8000")

    @property
    def google_oauth_configured(self) -> bool:
        if not self.GOOGLE_CLIENT_ID:
            return False
        placeholder_values = [
            "your-google-oauth-client-id.apps.googleusercontent.com",
            "your-google-oauth-client-id",
        ]
        return not any(placeholder in self.GOOGLE_CLIENT_ID for placeholder in placeholder_values)


@lru_cache
def get_settings() -> Settings:
    return Settings()
