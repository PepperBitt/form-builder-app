from typing import Any, List, Optional
import secrets

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.form import Form
from app.models.form_field import FormField
from app.models.form_response import FormResponse
from app.models.user import User
from app.schemas.form_schema import FormCreate, FormFieldSchema, FormUpdate


def _fields_to_schema_data(fields: List[FormFieldSchema]) -> dict[str, Any]:
    return {"fields": [field.model_dump() for field in fields]}


def _sync_form_fields(db: Session, form: Form, fields: List[FormFieldSchema]) -> None:
    db.query(FormField).filter(FormField.form_id == form.id).delete()
    for index, field in enumerate(fields):
        db.add(
            FormField(
                form_id=form.id,
                type=field.type,
                label=field.label,
                required=field.required,
                position=index,
                options=field.options,
            )
        )


def _response_count(db_or_form: Any) -> int:
    """Return the response count from the already-loaded relationship list."""
    responses = getattr(db_or_form, "responses", None)
    if responses is not None:
        return len(responses)
    return 0


def _build_share_url(share_token: Optional[str]) -> Optional[str]:
    if not share_token:
        return None
    settings = get_settings()
    return f"{settings.BASE_URL}/api/forms/share/{share_token}"


def _form_to_detail(form: Form) -> dict[str, Any]:
    return {
        "form_id": form.id,
        "title": form.title,
        "description": form.description,
        "status": form.status,
        "schema": form.schema_data or {"fields": []},
        "total_responses": _response_count(form),
        "share_token": form.share_token,
        "share_url": _build_share_url(form.share_token),
        "created_at": form.created_at,
        "updated_at": form.updated_at,
    }


def _form_to_summary(form: Form) -> dict[str, Any]:
    return {
        "form_id": form.id,
        "title": form.title,
        "status": form.status,
        "description": form.description,
        "total_responses": _response_count(form),
        "created_at": form.created_at,
        "updated_at": form.updated_at,
    }



def get_form_or_404(db: Session, form_id: str, include_deleted: bool = False) -> Form:
    query = db.query(Form).filter(Form.id == form_id)
    if not include_deleted:
        query = query.filter(Form.deleted_at.is_(None))
    form = query.first()
    if not form:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Form not found")
    return form


def ensure_form_owner(form: Form, user: User) -> None:
    if form.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this form",
        )


def create_form(db: Session, user: User, payload: FormCreate) -> Form:
    schema_data = _fields_to_schema_data(payload.fields)
    form = Form(
        user_id=user.id,
        title=payload.title,
        description=payload.description,
        status=payload.status,
        schema_data=schema_data,
    )
    db.add(form)
    db.flush()
    _sync_form_fields(db, form, payload.fields)
    db.commit()
    db.refresh(form)
    return form


def update_form(db: Session, form: Form, payload: FormUpdate) -> Form:
    if payload.title is not None:
        form.title = payload.title
    if payload.description is not None:
        form.description = payload.description
    if payload.status is not None:
        form.status = payload.status
    if payload.fields is not None:
        form.schema_data = _fields_to_schema_data(payload.fields)
        _sync_form_fields(db, form, payload.fields)
    db.commit()
    db.refresh(form)
    return form


def soft_delete_form(db: Session, form: Form) -> None:
    from datetime import datetime

    form.deleted_at = datetime.utcnow()
    form.status = "archived"
    db.commit()


def list_user_forms(
    db: Session,
    user: User,
    *,
    skip: int = 0,
    limit: int = 20,
    status_filter: Optional[str] = None,
) -> tuple[list[Form], int]:
    query = db.query(Form).filter(
        Form.user_id == user.id,
        Form.deleted_at.is_(None),
    )
    if status_filter:
        query = query.filter(Form.status == status_filter)
    total = query.count()
    forms = query.order_by(Form.updated_at.desc()).offset(skip).limit(limit).all()
    return forms, total


def publish_form(db: Session, form: Form) -> Form:
    if not form.schema_data or not form.schema_data.get("fields"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot publish a form without fields",
        )
    form.status = "published"
    db.commit()
    db.refresh(form)
    return form


def unpublish_form(db: Session, form: Form) -> Form:
    form.status = "draft"
    db.commit()
    db.refresh(form)
    return form


def generate_share_link(db: Session, form: Form) -> Form:
    """Generate a unique share token for a form (idempotent — reuses existing token)."""
    if not form.share_token:
        token = secrets.token_urlsafe(16)
        # Ensure uniqueness (collision is astronomically unlikely but be safe)
        while db.query(Form).filter(Form.share_token == token).first():
            token = secrets.token_urlsafe(16)
        form.share_token = token
        db.commit()
        db.refresh(form)
    return form


def get_form_by_share_token(db: Session, share_token: str) -> Form:
    form = (
        db.query(Form)
        .filter(Form.share_token == share_token, Form.deleted_at.is_(None))
        .first()
    )
    if not form:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Form not found")
    if form.status != "published":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This form is not publicly available",
        )
    return form
