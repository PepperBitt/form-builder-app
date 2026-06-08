from fastapi import APIRouter, UploadFile, File, HTTPException
import shutil
import os
import uuid

router = APIRouter()

# Create a local directory to act as our "Object Storage" for now
UPLOAD_DIR = "app/storage/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/")
def upload_file(file: UploadFile = File(...)):
    """
    Phase 3: Handles file uploads from the form builder.
    """
    try:
        # Generate a unique secure filename
        file_extension = file.filename.split(".")[-1]
        secure_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join(UPLOAD_DIR, secure_filename)

        # Save the file to the server
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Return the path so the frontend can save it in the response JSON
        return {
            "filename": file.filename, 
            "stored_name": secure_filename,
            "url": f"/files/{secure_filename}"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))