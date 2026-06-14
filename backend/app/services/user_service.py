from typing import Optional

from sqlalchemy.orm import Session

from app.models.user import User
from app.models.user_settings import UserSettings
from app.schemas.user_schema import UserProfileUpdate, UserSettingsUpdate


def get_or_create_settings(db: Session, user: User) -> UserSettings:
    settings = db.query(UserSettings).filter(UserSettings.user_id == user.id).first()
    if not settings:
        settings = UserSettings(user_id=user.id)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings


def update_profile(db: Session, user: User, payload: UserProfileUpdate) -> User:
    if payload.full_name is not None:
        user.full_name = payload.full_name
    if payload.avatar_url is not None:
        user.avatar_url = payload.avatar_url
    db.commit()
    db.refresh(user)
    return user


def update_settings(
    db: Session, user: User, payload: UserSettingsUpdate
) -> UserSettings:
    settings = get_or_create_settings(db, user)
    if payload.email_notifications is not None:
        settings.email_notifications = payload.email_notifications
    if payload.push_notifications is not None:
        settings.push_notifications = payload.push_notifications
    if payload.theme is not None:
        settings.theme = payload.theme
    if payload.language is not None:
        settings.language = payload.language
    if payload.preferences is not None:
        settings.preferences = payload.preferences
    db.commit()
    db.refresh(settings)
    return settings


def profile_to_dict(user: User) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "avatar_url": user.avatar_url,
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }


def settings_to_dict(settings: UserSettings) -> dict:
    return {
        "email_notifications": settings.email_notifications,
        "push_notifications": settings.push_notifications,
        "theme": settings.theme,
        "language": settings.language,
        "preferences": settings.preferences or {},
    }
