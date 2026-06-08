from sqlalchemy import Column, String, JSON, DateTime
from app.core.database import Base
import uuid
from datetime import datetime

class Form(Base):
    __tablename__ = "forms"

    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, index=True)
    schema_data = Column(JSON) 
    created_at = Column(DateTime, default=datetime.utcnow)
    