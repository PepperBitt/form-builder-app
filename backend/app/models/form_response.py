import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, JSON, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class FormResponse(Base):
    __tablename__ = "form_responses"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    form_id = Column(
        String, ForeignKey("forms.id", ondelete="CASCADE"), nullable=False, index=True
    )
    response_data = Column(JSON, nullable=False)
    submitted_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    form = relationship("Form", back_populates="responses")
