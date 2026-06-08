from datetime import datetime
from typing import Any, List, Optional

from pydantic import BaseModel, ConfigDict, Field


class FormFieldSchema(BaseModel):
    type: str = Field(..., min_length=1, max_length=50)
    label: str = Field(..., min_length=1, max_length=255)
    required: bool = False
    options: Optional[List[str]] = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {"type": "text", "label": "Full Name", "required": True}
        }
    )


class FormCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=2000)
    fields: List[FormFieldSchema] = Field(default_factory=list)
    status: str = Field(default="draft", pattern="^(draft|published|archived)$")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "title": "Customer Feedback",
                "description": "Collect feedback from customers",
                "status": "draft",
                "fields": [
                    {"type": "text", "label": "Name", "required": True},
                    {"type": "email", "label": "Email", "required": True},
                ],
            }
        }
    )


class FormUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=2000)
    fields: Optional[List[FormFieldSchema]] = None
    status: Optional[str] = Field(None, pattern="^(draft|published|archived)$")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "title": "Updated Form Title",
                "fields": [{"type": "text", "label": "Comments", "required": False}],
            }
        }
    )


class FormSummary(BaseModel):
    form_id: str
    title: str
    status: str
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "form_id": "550e8400-e29b-41d4-a716-446655440000",
                "title": "Customer Feedback",
                "status": "draft",
                "description": None,
                "created_at": "2026-06-10T12:00:00",
                "updated_at": "2026-06-10T12:00:00",
            }
        }
    )


class FormDetail(BaseModel):
    form_id: str
    title: str
    description: Optional[str] = None
    status: str
    form_schema: dict[str, Any] = Field(..., alias="schema")
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "form_id": "550e8400-e29b-41d4-a716-446655440000",
                "title": "Customer Feedback",
                "description": None,
                "status": "published",
                "schema": {"fields": [{"type": "text", "label": "Name", "required": True}]},
                "created_at": "2026-06-10T12:00:00",
                "updated_at": "2026-06-10T12:00:00",
            }
        },
    )


class FormCreateResponse(BaseModel):
    message: str
    form_id: str

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "message": "Form created",
                "form_id": "550e8400-e29b-41d4-a716-446655440000",
            }
        }
    )


class MessageResponse(BaseModel):
    message: str

    model_config = ConfigDict(json_schema_extra={"example": {"message": "Success"}})
