from pydantic import BaseModel
from typing import List

class FormField(BaseModel):
    type: str       
    label: str      
    required: bool = False

class FormSchema(BaseModel):
    title: str
    fields: List[FormField]