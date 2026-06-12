from fastapi import HTTPException
from typing import Dict, Any

def validate_response_data(form_schema: Dict[str, Any], user_response: Dict[str, Any]):
    """
    Dynamically validates user responses against the form's JSON schema.
    """
    fields = form_schema.get("fields", [])
    
    for field in fields:
        field_name = field.get("label")
        is_required = field.get("required", False)
        field_type = field.get("type", "text")
        
        # 1. Check for missing required fields
        if is_required and field_name not in user_response:
            raise HTTPException(
                status_code=400, 
                detail=f"Validation Error: '{field_name}' is a required field."
            )
            
        # 2. Perform basic type checking if the field is present
        if field_name in user_response:
            value = user_response[field_name]
            
            if field_type == "text" and not isinstance(value, str):
                raise HTTPException(
                    status_code=400, 
                    detail=f"Validation Error: '{field_name}' must be a text string."
                )
            
    return True
