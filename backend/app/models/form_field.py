import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, JSON, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class FormField(Base):
    __tablename__ = "form_fields"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    form_id = Column(
        String, ForeignKey("forms.id", ondelete="CASCADE"), nullable=False, index=True
    )
    type = Column(String, nullable=False)
    label = Column(String, nullable=False)
    required = Column(Boolean, default=False, nullable=False)
    position = Column(Integer, default=0, nullable=False)
    options = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    form = relationship("Form", back_populates="fields")
