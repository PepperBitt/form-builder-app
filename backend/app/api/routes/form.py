from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_optional_user
from app.models.user import User
from app.schemas.form_schema import (
    FormCreate,
    FormCreateResponse,
    FormDetail,
    FormSummary,
    FormUpdate,
    MessageResponse,
    ShareLinkResponse,
)
from app.schemas.user_schema import ErrorResponse, PaginatedResponse
from app.services import cache_service, form_service

router = APIRouter()


@router.post(
    "/create",
    status_code=status.HTTP_201_CREATED,
    response_model=FormCreateResponse,
    responses={401: {"model": ErrorResponse}, 422: {"model": ErrorResponse}},
    summary="Create a new form",
)
def create_form(
    form_data: FormCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form = form_service.create_form(db, current_user, form_data)
    return {"message": "Form created", "form_id": form.id}


@router.get(
    "/drafts",
    response_model=PaginatedResponse[FormSummary],
    responses={401: {"model": ErrorResponse}},
    summary="List current user's draft forms",
)
def list_drafts(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    forms, total = form_service.list_user_forms(
        db, current_user, skip=skip, limit=limit, status_filter="draft"
    )
    page = (skip // limit) + 1 if limit else 1
    return {
        "total": total,
        "page": page,
        "page_size": len(forms),
        "items": [form_service._form_to_summary(form) for form in forms],
    }


@router.get(
    "/",
    response_model=list[FormSummary],
    summary="List published forms (public)",
)
def get_all_forms(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    from app.models.form import Form

    forms = (
        db.query(Form)
        .filter(
            Form.deleted_at.is_(None),
            Form.status == "published",
        )
        .order_by(Form.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [form_service._form_to_summary(form) for form in forms]


# ── IMPORTANT: static-path GET routes must come BEFORE /{form_id} ──────────

@router.get(
    "/share/{share_token}",
    response_model=FormDetail,
    responses={403: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
    summary="Access a published form via its share token (public)",
)
def get_form_by_share_token(
    share_token: str,
    db: Session = Depends(get_db),
):
    form = form_service.get_form_by_share_token(db, share_token)
    return form_service._form_to_detail(form)


# ── Parameterised routes below ──────────────────────────────────────────────

@router.get(
    "/{form_id}",
    response_model=FormDetail,
    responses={404: {"model": ErrorResponse}},
    summary="Get form by ID",
)
def get_form(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
):
    cached = cache_service.get_cached_form(form_id)
    if cached:
        if cached.get("status") != "published":
            if current_user is None:
                raise HTTPException(status_code=404, detail="Form not found")
            form = form_service.get_form_or_404(db, form_id)
            form_service.ensure_form_owner(form, current_user)
        return cached

    form = form_service.get_form_or_404(db, form_id)
    if form.status != "published":
        if current_user is None:
            raise HTTPException(status_code=404, detail="Form not found")
        form_service.ensure_form_owner(form, current_user)

    form_data = form_service._form_to_detail(form)
    if form.status == "published":
        cache_service.set_cached_form(form_id, form_data)
    return form_data


@router.put(
    "/{form_id}",
    response_model=FormDetail,
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Update a form",
)
def update_form(
    form_id: str,
    payload: FormUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form = form_service.get_form_or_404(db, form_id)
    form_service.ensure_form_owner(form, current_user)
    form = form_service.update_form(db, form, payload)
    cache_service.invalidate_form_cache(form_id)
    return form_service._form_to_detail(form)


@router.delete(
    "/{form_id}",
    response_model=MessageResponse,
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Soft-delete a form",
)
def delete_form(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form = form_service.get_form_or_404(db, form_id)
    form_service.ensure_form_owner(form, current_user)
    form_service.soft_delete_form(db, form)
    cache_service.invalidate_form_cache(form_id)
    return {"message": "Form deleted"}


@router.post(
    "/{form_id}/publish",
    response_model=FormDetail,
    responses={
        400: {"model": ErrorResponse},
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Publish a form",
)
def publish_form(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form = form_service.get_form_or_404(db, form_id)
    form_service.ensure_form_owner(form, current_user)
    form = form_service.publish_form(db, form)
    cache_service.invalidate_form_cache(form_id)
    return form_service._form_to_detail(form)


@router.post(
    "/{form_id}/unpublish",
    response_model=FormDetail,
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Unpublish a form (revert to draft)",
)
def unpublish_form(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form = form_service.get_form_or_404(db, form_id)
    form_service.ensure_form_owner(form, current_user)
    form = form_service.unpublish_form(db, form)
    cache_service.invalidate_form_cache(form_id)
    return form_service._form_to_detail(form)


@router.post(
    "/{form_id}/draft",
    response_model=FormDetail,
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Save or update form as draft",
)
def save_draft(
    form_id: str,
    payload: FormUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form = form_service.get_form_or_404(db, form_id)
    form_service.ensure_form_owner(form, current_user)
    update_payload = payload.model_copy(update={"status": "draft"})
    form = form_service.update_form(db, form, update_payload)
    cache_service.invalidate_form_cache(form_id)
    return form_service._form_to_detail(form)


@router.post(
    "/{form_id}/share",
    response_model=ShareLinkResponse,
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Generate (or retrieve) a public share link for a form",
)
def get_share_link(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form = form_service.get_form_or_404(db, form_id)
    form_service.ensure_form_owner(form, current_user)
    form = form_service.generate_share_link(db, form)
    return {
        "share_token": form.share_token,
        "share_url": form_service._build_share_url(form.share_token),
    }
