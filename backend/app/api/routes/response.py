from collections import Counter

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.form import Form
from app.models.form_response import FormResponse
from app.schemas.response_schema import FormResponseCreate
from app.services import form_service, notification_service
from app.utils.schema_engine import validate_response_data

router = APIRouter()


@router.post("/submit", status_code=status.HTTP_201_CREATED)
def submit_response(response: FormResponseCreate, db: Session = Depends(get_db)):
    form = form_service.get_form_or_404(db, response.form_id)
    if form.status != "published":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Form is not accepting responses",
        )

    validate_response_data(form.schema_data, response.response_data)

    new_response = FormResponse(
        form_id=response.form_id,
        response_data=response.response_data,
    )
    db.add(new_response)
    db.commit()
    db.refresh(new_response)

    notification_service.create_notification(
        db,
        user_id=form.user_id,
        title="New form response",
        message=f'Your form "{form.title}" received a new response.',
        notification_type="response",
    )

    return {
        "message": "Response submitted successfully",
        "response_id": new_response.id,
    }


@router.get("/{form_id}")
def get_form_responses(
    form_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    form = form_service.get_form_or_404(db, form_id)
    responses = (
        db.query(FormResponse)
        .filter(FormResponse.form_id == form_id)
        .offset(skip)
        .limit(limit)
        .all()
    )
    total_responses = (
        db.query(FormResponse).filter(FormResponse.form_id == form_id).count()
    )

    return {
        "form_id": form.id,
        "form_title": form.title,
        "total_responses": total_responses,
        "page_size": len(responses),
        "data": [
            {
                "response_id": response.id,
                "submitted_at": response.submitted_at,
                "answers": response.response_data,
            }
            for response in responses
        ],
    }


@router.get("/{form_id}/analytics")
def get_form_analytics(form_id: str, db: Session = Depends(get_db)):
    form_service.get_form_or_404(db, form_id)
    responses = db.query(FormResponse).filter(FormResponse.form_id == form_id).all()
    if not responses:
        return {"total_responses": 0, "analytics": {}}

    analytics_data = {}
    for response in responses:
        for question_label, answer in response.response_data.items():
            if isinstance(answer, (str, int, bool)):
                analytics_data.setdefault(question_label, []).append(str(answer))

    final_stats = {
        question: dict(Counter(answers))
        for question, answers in analytics_data.items()
    }

    return {
        "form_id": form_id,
        "total_responses": len(responses),
        "analytics": final_stats,
    }
