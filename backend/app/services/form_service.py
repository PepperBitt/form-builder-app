from typing import Any, List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.form import Form
from app.models.form_field import FormField
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


def _form_to_detail(form: Form) -> dict[str, Any]:
    return {
        "form_id": form.id,
        "title": form.title,
        "description": form.description,
        "status": form.status,
        "schema": form.schema_data or {"fields": []},
        "created_at": form.created_at,
        "updated_at": form.updated_at,
    }


def _form_to_summary(form: Form) -> dict[str, Any]:
    return {
        "form_id": form.id,
        "title": form.title,
        "status": form.status,
        "description": form.description,
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
