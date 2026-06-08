from sqlalchemy import Column, String, JSON, DateTime, ForeignKey
from app.core.database import Base
import uuid
from datetime import datetime

class Response(Base):
    __tablename__ = "responses"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    form_id = Column(String, ForeignKey("forms.id"), nullable=False)
    response_data = Column(JSON, nullable=False)
    submitted_at = Column(DateTime, default=datetime.utcnow)