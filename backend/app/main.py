from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.core.database import engine, Base
from app.api.routes import form, response, export, upload, auth

# Create tables if they don't exist yet
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Form Builder API")

# CORS: allow Flutter app (web/mobile) to hit the backend
# During dev, "*" is fine. In production, replace with your frontend domain.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Make uploaded files publicly accessible at /files/<filename>
UPLOAD_DIR = "app/storage/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/files", StaticFiles(directory=UPLOAD_DIR), name="files")

# Routers
app.include_router(auth.router,     prefix="/api/auth",      tags=["Authentication"])
app.include_router(form.router,     prefix="/api/forms",     tags=["Forms"])
app.include_router(response.router, prefix="/api/responses", tags=["Responses"])
app.include_router(export.router,   prefix="/api/export",    tags=["Export"])
app.include_router(upload.router,   prefix="/api/upload",    tags=["Uploads"])


@app.get("/")
def root():
    return {"message": "Form Builder API is running. Go to /docs for Swagger UI"}


@app.get("/health")
def health():
    return {"status": "ok"}
