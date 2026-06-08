from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.form_schema import FormSummary
from app.schemas.user_schema import (
    ErrorResponse,
    PaginatedResponse,
    UserProfileResponse,
    UserProfileUpdate,
    UserSettingsResponse,
    UserSettingsUpdate,
)
from app.services import form_service, user_service

router = APIRouter()


@router.get(
    "/profile",
    response_model=UserProfileResponse,
    responses={401: {"model": ErrorResponse}},
    summary="Get current user profile",
)
def get_profile(current_user: User = Depends(get_current_user)):
    return user_service.profile_to_dict(current_user)


@router.put(
    "/profile",
    response_model=UserProfileResponse,
    responses={401: {"model": ErrorResponse}, 422: {"model": ErrorResponse}},
    summary="Update current user profile",
)
def update_profile(
    payload: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user = user_service.update_profile(db, current_user, payload)
    return user_service.profile_to_dict(user)


@router.get(
    "/settings",
    response_model=UserSettingsResponse,
    responses={401: {"model": ErrorResponse}},
    summary="Get current user settings",
)
def get_settings_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user_settings = user_service.get_or_create_settings(db, current_user)
    return user_service.settings_to_dict(user_settings)


@router.put(
    "/settings",
    response_model=UserSettingsResponse,
    responses={401: {"model": ErrorResponse}, 422: {"model": ErrorResponse}},
    summary="Update current user settings",
)
def update_settings_endpoint(
    payload: UserSettingsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user_settings = user_service.update_settings(db, current_user, payload)
    return user_service.settings_to_dict(user_settings)


@router.get(
    "/me/forms",
    response_model=PaginatedResponse[FormSummary],
    responses={401: {"model": ErrorResponse}},
    summary="List forms owned by the authenticated user",
)
def list_my_forms(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    status_filter: Optional[str] = Query(
        None, alias="status", pattern="^(draft|published|archived)$"
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    forms, total = form_service.list_user_forms(
        db,
        current_user,
        skip=skip,
        limit=limit,
        status_filter=status_filter,
    )
    page = (skip // limit) + 1 if limit else 1
    return {
        "total": total,
        "page": page,
        "page_size": len(forms),
        "items": [form_service._form_to_summary(form) for form in forms],
    }
