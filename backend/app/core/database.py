import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Force Python to read your local .env file
load_dotenv() 

# Grab the Docker URL from the .env file
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

# Safety check just in case the .env is missing
if not SQLALCHEMY_DATABASE_URL:
    raise ValueError("No DATABASE_URL found! Check your .env file.")

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    pool_pre_ping=True,  # Pings the DB to check if it's awake before querying
    pool_recycle=300     # Recycles connections older than 5 minutes
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()