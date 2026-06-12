import json
import redis
import os
from app.core.dependencies import get_current_user
from app.models.user import User
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.form import Form
from app.schemas.form_schema import FormSchema

router = APIRouter()

# Initialize Redis client (defaults to localhost:6379)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
redis_client = redis.from_url(REDIS_URL, decode_responses=True)

@router.post("/create", status_code=201)
def create_form(form_data: FormSchema, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    new_form = Form(
        title=form_data.title,
        schema_data={"fields": [field.dict() for field in form_data.fields]}
        # Note: In a future update, you can add created_by=current_user.id here!
    )
    db.add(new_form)
    db.commit()
    db.refresh(new_form)
    return {"message": "Form created", "form_id": new_form.id, "owner": current_user.email}

@router.get("/{form_id}")
def get_form(form_id: str, db: Session = Depends(get_db)):
    # 1. Check Redis Cache First
    try:
        cached_form = redis_client.get(f"form:{form_id}")
        if cached_form:
            print("🚀 Serving from Redis Cache!")
            return json.loads(cached_form)
    except redis.ConnectionError:
        print("⚠️ Redis is down, falling back to Database...")

    # 2. If not in cache (or Redis is down), fetch from Database
    form = db.query(Form).filter(Form.id == form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Form not found")
    
    form_data = {
        "form_id": form.id,
        "title": form.title,
        "schema": form.schema_data
    }

    # 3. Save to Redis Cache for future requests (expires in 1 hour)
    try:
        print("🐢 Serving from Database (and caching for next time)")
        redis_client.setex(f"form:{form_id}", 3600, json.dumps(form_data))
    except redis.ConnectionError:
        pass # Ignore cache failure if Redis is down

    return form_data

@router.get("/")
def get_all_forms(db: Session = Depends(get_db)):
    forms = db.query(Form).all()
    return [
        {
            "form_id": f.id, 
            "title": f.title, 
            "created_at": f.created_at
        } 
        for f in forms
    ]