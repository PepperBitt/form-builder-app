from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.user import User


def create_notification(
    db: Session,
    user_id: str,
    title: str,
    message: str,
    notification_type: str = "info",
) -> Notification:
    notification = Notification(
        user_id=user_id,
        title=title,
        message=message,
        notification_type=notification_type,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification


def list_notifications(
    db: Session,
    user: User,
    *,
    skip: int = 0,
    limit: int = 50,
    unread_only: bool = False,
) -> tuple[List[Notification], int, int]:
    query = db.query(Notification).filter(Notification.user_id == user.id)
    if unread_only:
        query = query.filter(Notification.is_read.is_(False))
    total = query.count()
    unread_count = (
        db.query(Notification)
        .filter(Notification.user_id == user.id, Notification.is_read.is_(False))
        .count()
    )
    items = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
    return items, total, unread_count


def mark_notifications_read(
    db: Session,
    user: User,
    notification_ids: Optional[List[str]] = None,
) -> int:
    query = db.query(Notification).filter(
        Notification.user_id == user.id,
        Notification.is_read.is_(False),
    )
    if notification_ids:
        query = query.filter(Notification.id.in_(notification_ids))
    updated = query.update({Notification.is_read: True}, synchronize_session=False)
    db.commit()
    return updated
