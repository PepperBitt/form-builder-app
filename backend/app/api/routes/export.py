from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.form_response import FormResponse
from app.models.user import User
from app.schemas.user_schema import ErrorResponse
from app.services import export_service, form_service

router = APIRouter()


def _get_form_responses(db: Session, form_id: str):
    form = form_service.get_form_or_404(db, form_id)
    responses = db.query(FormResponse).filter(FormResponse.form_id == form_id).all()
    return form, responses


def _authorized_export(
    db: Session,
    form_id: str,
    current_user: User,
):
    form = form_service.get_form_or_404(db, form_id)
    form_service.ensure_form_owner(form, current_user)
    responses = db.query(FormResponse).filter(FormResponse.form_id == form_id).all()
    return form, responses


@router.get(
    "/{form_id}/json",
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Export form and responses as JSON",
)
def export_responses_json(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form, responses = _authorized_export(db, form_id, current_user)
    file_path = export_service.export_form_json(form, responses)
    return FileResponse(
        path=file_path,
        filename=f"{form.title}_export.json",
        media_type="application/json",
    )


@router.get(
    "/{form_id}/csv",
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Export form responses as CSV",
)
def export_responses_csv(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form, responses = _authorized_export(db, form_id, current_user)
    file_path = export_service.export_form_csv(form, responses)
    return FileResponse(
        path=file_path,
        filename=f"{form.title}_responses.csv",
        media_type="text/csv",
    )


@router.get(
    "/{form_id}/pdf",
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Export form responses as PDF",
)
def export_responses_pdf(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form, responses = _authorized_export(db, form_id, current_user)
    file_path = export_service.export_form_pdf(form, responses)
    return FileResponse(
        path=file_path,
        filename=f"{form.title}_responses.pdf",
        media_type="application/pdf",
    )


@router.get(
    "/{form_id}/excel",
    responses={
        401: {"model": ErrorResponse},
        403: {"model": ErrorResponse},
        404: {"model": ErrorResponse},
    },
    summary="Export form responses as Excel (legacy path)",
)
def export_responses_excel(
    form_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    form, responses = _authorized_export(db, form_id, current_user)
    file_path = export_service.export_form_excel(form, responses)
    return FileResponse(
        path=file_path,
        filename=f"{form.title}_responses.xlsx",
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    )
