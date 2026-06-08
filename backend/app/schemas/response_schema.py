from pydantic import BaseModel
from typing import Dict, Any

class FormResponseCreate(BaseModel):
    form_id: str
    response_data: Dict[str, Any]