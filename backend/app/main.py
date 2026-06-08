import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import get_settings
from app.core.database import Base, engine
from app.api.routes import auth, export, form, form_export, notifications, response, upload, users

logger = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as exc:
        logger.warning("Database table initialization skipped: %s", exc)
    yield


app = FastAPI(
    title="Form Builder API",
    version="1.0.0",
    description=(
        "Backend API for the Form Builder application. "
        "Supports form CRUD, drafts, publish/unpublish, user profile, settings, "
        "notifications, and data export."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
os.makedirs(settings.EXPORT_DIR, exist_ok=True)
app.mount("/files", StaticFiles(directory=settings.UPLOAD_DIR), name="files")

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(form.router, prefix="/api/forms", tags=["Forms"])
app.include_router(form_export.router, prefix="/api/forms", tags=["Forms"])
app.include_router(response.router, prefix="/api/responses", tags=["Responses"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications"])
app.include_router(export.router, prefix="/api/export", tags=["Export"])
app.include_router(upload.router, prefix="/api/upload", tags=["Uploads"])


@app.get("/", tags=["Health"])
def root():
    return {"message": "Form Builder API is running. Go to /docs for Swagger UI"}


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok"}
