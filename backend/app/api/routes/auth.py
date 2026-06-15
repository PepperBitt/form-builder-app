from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from pydantic import BaseModel, ConfigDict, EmailStr
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.core.security import create_access_token, get_password_hash, verify_password
from app.models.user import User
from app.services.user_service import get_or_create_settings

router = APIRouter()
settings = get_settings()


class UserCreate(BaseModel):
    email: EmailStr
    password: str

    model_config = ConfigDict(
        json_schema_extra={"example": {"email": "user@example.com", "password": "secret123"}}
    )


class TokenResponse(BaseModel):
    access_token: str
    token_type: str

    model_config = ConfigDict(
        json_schema_extra={
            "example": {"access_token": "eyJ...", "token_type": "bearer"}
        }
    )


class MessageResponse(BaseModel):
    message: str


class GoogleLoginRequest(BaseModel):
    id_token: str

    model_config = ConfigDict(
        json_schema_extra={"example": {"id_token": "<google-id-token-string>"}}
    )


@router.post(
    "/signup",
    status_code=status.HTTP_201_CREATED,
    response_model=MessageResponse,
    responses={400: {"model": MessageResponse}},
)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = get_password_hash(user.password)
    new_user = User(email=user.email, hashed_password=hashed_password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    get_or_create_settings(db, new_user)
    return {"message": "User created successfully"}


@router.post(
    "/login",
    response_model=TokenResponse,
    responses={401: {"model": MessageResponse}},
)
def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}


@router.post(
    "/google",
    response_model=TokenResponse,
    responses={400: {"model": MessageResponse}, 401: {"model": MessageResponse}},
    summary="Sign in / sign up with Google ID token",
)
def google_login(payload: GoogleLoginRequest, db: Session = Depends(get_db)):
    """
    Accepts a Google ID token (obtained client-side via Google Sign-In SDK),
    verifies it, then creates or retrieves the user and returns a JWT.
    """
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Google login is not configured on this server",
        )

    try:
        id_info = google_id_token.verify_oauth2_token(
            payload.id_token,
            google_requests.Request(),
            settings.GOOGLE_CLIENT_ID,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google token: {exc}",
        )

    google_sub = id_info["sub"]
    email: str = id_info.get("email", "")
    full_name: str = id_info.get("name", "")
    avatar_url: str = id_info.get("picture", "")

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google account has no email address",
        )

    # Try to find by google_id first, then by email
    user = db.query(User).filter(User.google_id == google_sub).first()
    if user is None:
        user = db.query(User).filter(User.email == email).first()
        if user:
            # Link existing email account to Google
            user.google_id = google_sub
            if not user.avatar_url and avatar_url:
                user.avatar_url = avatar_url
            if not user.full_name and full_name:
                user.full_name = full_name
            db.commit()
            db.refresh(user)
        else:
            # New user — create account
            user = User(
                email=email,
                google_id=google_sub,
                full_name=full_name or None,
                avatar_url=avatar_url or None,
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            get_or_create_settings(db, user)

    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

