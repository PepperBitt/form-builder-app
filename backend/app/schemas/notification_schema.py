from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class NotificationResponse(BaseModel):
    id: str
    title: str
    message: str
    notification_type: str
    is_read: bool
    created_at: datetime

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "title": "New response",
                "message": "Your form received a new response.",
                "notification_type": "info",
                "is_read": False,
                "created_at": "2026-06-10T12:00:00",
            }
        }
    )


class NotificationListResponse(BaseModel):
    total: int
    unread_count: int
    items: List[NotificationResponse]


class MarkNotificationsReadRequest(BaseModel):
    notification_ids: Optional[List[str]] = Field(
        default=None,
        description="Specific notification IDs to mark read. Omit to mark all as read.",
    )

    model_config = ConfigDict(
        json_schema_extra={
            "example": {"notification_ids": ["550e8400-e29b-41d4-a716-446655440000"]}
        }
    )
