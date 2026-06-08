from datetime import datetime
from typing import Any, Generic, List, Optional, TypeVar

from pydantic import BaseModel, ConfigDict, EmailStr, Field

T = TypeVar("T")


class ErrorResponse(BaseModel):
    detail: str

    model_config = ConfigDict(json_schema_extra={"example": {"detail": "Error message"}})


class PaginatedResponse(BaseModel, Generic[T]):
    total: int
    page: int
    page_size: int
    items: List[T]


class UserProfileResponse(BaseModel):
    id: str
    email: EmailStr
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "user@example.com",
                "full_name": "Jane Doe",
                "avatar_url": None,
                "created_at": "2026-06-10T12:00:00",
                "updated_at": "2026-06-10T12:00:00",
            }
        }
    )


class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(None, max_length=255)
    avatar_url: Optional[str] = Field(None, max_length=2048)

    model_config = ConfigDict(
        json_schema_extra={"example": {"full_name": "Jane Doe", "avatar_url": None}}
    )


class UserSettingsResponse(BaseModel):
    email_notifications: bool
    push_notifications: bool
    theme: str
    language: str
    preferences: dict[str, Any]

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "email_notifications": True,
                "push_notifications": True,
                "theme": "system",
                "language": "en",
                "preferences": {},
            }
        }
    )


class UserSettingsUpdate(BaseModel):
    email_notifications: Optional[bool] = None
    push_notifications: Optional[bool] = None
    theme: Optional[str] = Field(None, pattern="^(light|dark|system)$")
    language: Optional[str] = Field(None, min_length=2, max_length=10)
    preferences: Optional[dict[str, Any]] = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "email_notifications": True,
                "push_notifications": False,
                "theme": "dark",
                "language": "en",
            }
        }
    )
