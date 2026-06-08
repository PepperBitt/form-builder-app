from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.form import Form
from app.models.response import Response
from app.schemas.response_schema import FormResponseCreate
from app.utils.schema_engine import validate_response_data

router = APIRouter()

@router.post("/submit", status_code=201)
def submit_response(response: FormResponseCreate, db: Session = Depends(get_db)):
   
    form = db.query(Form).filter(Form.id == response.form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Form not found")

    validate_response_data(form.schema_data, response.response_data)

    
    new_response = Response(
        form_id=response.form_id,
        response_data=response.response_data
    )
    db.add(new_response)
    db.commit()
    db.refresh(new_response)
    
    return {"message": "Response submitted successfully", "response_id": new_response.id}
@router.get("/{form_id}")
def get_form_responses(
    form_id: str, 
    skip: int = 0, 
    limit: int = 20, 
    db: Session = Depends(get_db)
):
    """
    Dashboard API: Fetch responses for a specific form with pagination.
    """
    
    form = db.query(Form).filter(Form.id == form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Form not found")

    
    responses = (
        db.query(Response)
        .filter(Response.form_id == form_id)
        .offset(skip)
        .limit(limit)
        .all()
    )
    
    total_responses = db.query(Response).filter(Response.form_id == form_id).count()

    return {
        "form_id": form.id,
        "form_title": form.title,
        "total_responses": total_responses,
        "page_size": len(responses),
        "data": [
            {
                "response_id": r.id,
                "submitted_at": r.submitted_at,
                "answers": r.response_data
            }
            for r in responses
        ]
    }
from collections import Counter

@router.get("/{form_id}/analytics")
def get_form_analytics(form_id: str, db: Session = Depends(get_db)):
    """
    Phase 3: Aggregates response data for the frontend dashboard analytics.
    """
    responses = db.query(Response).filter(Response.form_id == form_id).all()
    if not responses:
        return {"total_responses": 0, "analytics": {}}

    analytics_data = {}
    
    # Iterate through every user's response
    for r in responses:
        for question_label, answer in r.response_data.items():
            # Only aggregate strings or numbers (e.g., dropdowns, multiple choice)
            if isinstance(answer, (str, int, bool)):
                if question_label not in analytics_data:
                    analytics_data[question_label] = []
                analytics_data[question_label].append(str(answer))

    # Count the frequencies of each answer for charting
    final_stats = {}
    for question, answers in analytics_data.items():
        answer_counts = dict(Counter(answers))
        final_stats[question] = answer_counts

    return {
        "form_id": form_id,
        "total_responses": len(responses),
        "analytics": final_stats
    }