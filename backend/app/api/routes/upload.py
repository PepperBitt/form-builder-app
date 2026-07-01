from fastapi import APIRouter, UploadFile, File, HTTPException
import os
import uuid

router = APIRouter()

# Create a local directory to act as our "Object Storage" for now
UPLOAD_DIR = "app/storage/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# --- Validation constants ---
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_EXTENSIONS = {
    "pdf", "doc", "docx", "xls", "xlsx",
    "png", "jpg", "jpeg", "gif",
    "txt", "csv", "zip",
}


@router.post("/")
async def upload_file(file: UploadFile = File(...)):
    """
    Phase 3: Handles file uploads from the form builder.
    Validates file size (≤10 MB) and extension before saving.
    """
    # --- Extension check ---
    original_name = file.filename or "unknown"
    file_extension = original_name.rsplit(".", 1)[-1].lower() if "." in original_name else ""
    if file_extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=415,
            detail=f"File type '.{file_extension}' is not allowed. "
                   f"Accepted types: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    # --- Size check (read file content into memory, reject if too large) ---
    try:
        contents = await file.read()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to read file: {e}")

    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"File exceeds the {MAX_FILE_SIZE // (1024 * 1024)} MB size limit.",
        )

    # --- Save ---
    try:
        secure_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join(UPLOAD_DIR, secure_filename)

        with open(file_path, "wb") as buffer:
            buffer.write(contents)

        # Return the path so the frontend can save it in the response JSON
        return {
            "filename": original_name,
            "stored_name": secure_filename,
            "url": f"/files/{secure_filename}",
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))