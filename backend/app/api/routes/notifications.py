from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.notification_schema import (
    MarkNotificationsReadRequest,
    NotificationListResponse,
    NotificationResponse,
)
from app.schemas.user_schema import ErrorResponse
from app.schemas.form_schema import MessageResponse
from app.services import notification_service

router = APIRouter()


@router.get(
    "",
    response_model=NotificationListResponse,
    responses={401: {"model": ErrorResponse}},
    summary="List notifications for the current user",
)
def list_notifications(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    unread_only: bool = Query(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items, total, unread_count = notification_service.list_notifications(
        db, current_user, skip=skip, limit=limit, unread_only=unread_only
    )
    return {
        "total": total,
        "unread_count": unread_count,
        "items": [
            {
                "id": item.id,
                "title": item.title,
                "message": item.message,
                "notification_type": item.notification_type,
                "is_read": item.is_read,
                "created_at": item.created_at,
            }
            for item in items
        ],
    }


@router.put(
    "/read",
    response_model=MessageResponse,
    responses={401: {"model": ErrorResponse}},
    summary="Mark notifications as read",
)
def mark_notifications_read(
    payload: MarkNotificationsReadRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    updated = notification_service.mark_notifications_read(
        db, current_user, payload.notification_ids
    )
    return {"message": f"Marked {updated} notification(s) as read"}
