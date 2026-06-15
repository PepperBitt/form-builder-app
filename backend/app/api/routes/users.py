from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.form import Form
from app.models.form_response import FormResponse
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
    "/analytics",
    responses={401: {"model": ErrorResponse}},
    summary="Get analytics dashboard data for the authenticated user",
)
def get_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Returns real counts from the database for the current user's forms."""
    base_query = db.query(Form).filter(
        Form.user_id == current_user.id,
        Form.deleted_at.is_(None),
    )

    total_forms: int = base_query.count()
    published_forms: int = base_query.filter(Form.status == "published").count()

    # Re-issue base query (without the published filter) to get all form ids
    all_form_ids = [
        row.id
        for row in db.query(Form.id).filter(
            Form.user_id == current_user.id,
            Form.deleted_at.is_(None),
        ).all()
    ]

    if all_form_ids:
        total_responses: int = (
            db.query(FormResponse)
            .filter(FormResponse.form_id.in_(all_form_ids))
            .count()
        )
        recent_raw = (
            db.query(FormResponse)
            .filter(FormResponse.form_id.in_(all_form_ids))
            .order_by(FormResponse.submitted_at.desc())
            .limit(10)
            .all()
        )
    else:
        total_responses = 0
        recent_raw = []

    recent_responses = [
        {
            "response_id": r.id,
            "form_id": r.form_id,
            "submitted_at": r.submitted_at,
        }
        for r in recent_raw
    ]

    return {
        "total_forms": total_forms,
        "published_forms": published_forms,
        "total_responses": total_responses,
        "recent_responses": recent_responses,
    }


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

