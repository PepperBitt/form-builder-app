# Form Builder API
A robust backend for the Form Builder application, featuring PostgreSQL database integration.

## Prerequisites
- Docker Desktop
- Python 3.12+

## Setup Instructions
1. Clone the repository.
2. Copy `.env.example` to `.env` and configure your settings.
3. Start the database:
   `docker run --name local-postgres -e POSTGRES_PASSWORD=postgres -p 5433:5432 -d postgres`
4. Install dependencies:
   `pip install -r backend/requirements.txt`
5. Start the server:
   `python -m uvicorn app.main:app --reload`
6. Build database tables:
   `python build_db.py`