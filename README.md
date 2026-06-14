# Form Builder & Response Management System

Full-stack Form Builder: **FastAPI backend** + **Flutter frontend**, integrated end-to-end.

---

## Project structure

```
integrated/
├── backend/          # FastAPI + SQLAlchemy + PostgreSQL + Redis
│   ├── app/
│   │   ├── main.py              # Entry point with CORS, routers, static files
│   │   ├── core/                # database, security (JWT), dependencies
│   │   ├── api/routes/          # auth, form, response, export, upload
│   │   ├── models/              # SQLAlchemy: user, form, response
│   │   ├── schemas/             # Pydantic: form_schema, response_schema
│   │   ├── utils/               # schema_engine (dynamic validation)
│   │   ├── workers/             # Celery worker + export tasks
│   │   └── storage/uploads/     # User-uploaded files (gitignored)
│   ├── requirements.txt
│   └── .env.example
│
└── flutter_app/      # Flutter (Material 3 + Provider + GoRouter)
    ├── lib/
    │   ├── main.dart
    │   ├── app.dart
    │   ├── core/
    │   │   ├── constants/api_constants.dart     # baseUrl + endpoint paths
    │   │   ├── network/api_client.dart          # HTTP wrapper with JWT
    │   │   ├── models.dart                      # FormModel, FieldModel, etc.
    │   │   ├── theme/                           # AppColors, theme
    │   │   └── routes/app_router.dart
    │   ├── services/                            # auth, form, response, export
    │   ├── providers/                           # auth, form, response (real API)
    │   └── features/                            # UI screens
    └── pubspec.yaml
```

---

## What the integration does

The backend and frontend were built separately. Integration wired them together:

### Backend changes (in `app/main.py`)
- Removed duplicate imports
- Added `CORSMiddleware` so Flutter web/mobile can reach the API
- Mounted `/files` as a static directory for uploaded files
- Cleaner router registration

### Frontend changes
- `core/constants/api_constants.dart` — rewritten to match real backend paths (`/api/auth/login`, `/api/forms/create`, etc.). Previously hit non-existent `/api/v1/*` endpoints.
- `core/network/api_client.dart` — new HTTP wrapper that attaches JWT bearer tokens, handles JSON + form-data, decodes errors
- `services/{auth,form,response,export}_service.dart` — previously empty; now contain all HTTP calls
- `providers/{auth,form,response}_provider.dart` — switched from mock data (`Future.delayed` + hardcoded lists) to real backend calls
- `features/dashboard/dashboard_screen.dart` — fetches forms from backend on init; pull-to-refresh works
- `features/builder/form_builder_screen.dart` — loads form by id from backend on deep-link; save button persists to backend with feedback
- `features/responses/responses_dashboard_screen.dart` — loads responses when a form is selected
- `features/renderer/public_form_screen.dart` — submits responses; translates Flutter field-IDs to backend field-labels (required by the schema validator)
- `features/export/export_screen.dart` — actually downloads PDF/Excel from the backend
- `pubspec.yaml` — added `http: ^1.2.2`

### Field type mapping (see `services/form_service.dart`)
The Flutter `FieldType` enum is rich (`shortText`, `rating`, `multipleChoice`...); the backend stores a plain string. A small bidirectional mapper lives in `form_service.dart`:

| Flutter | Backend |
|---|---|
| shortText | text |
| longText | textarea |
| email | email |
| number | number |
| multipleChoice | radio |
| checkbox | checkbox |
| rating | rating |
| date | date |
| fileUpload | file |

---

## Running it

### Backend

```bash
cd backend
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt

# Optional: copy .env.example to .env and customize
# cp .env.example .env

# Start the server
uvicorn app.main:app --reload --port 8000
```

Backend is now at `http://localhost:8000`. Swagger UI at `http://localhost:8000/docs`.

**Notes:**
- The default Postgres URL points to a Neon cloud DB (credentials are in `app/core/database.py`). Replace this in production.
- Redis is optional — the `form.py` route gracefully falls back if Redis is unreachable.
- Celery workers are included but not required for the basic export flow (the routes in `export.py` generate files synchronously).

### Frontend

```bash
cd flutter_app
flutter pub get
```

**Important:** Edit `lib/core/constants/api_constants.dart` and set `baseUrl` correctly for your setup:

- Running Flutter on the same machine as the backend: `http://localhost:8000`
- **Android emulator** hitting the host machine: `http://10.0.2.2:8000`
- Physical phone on same WiFi as your laptop: `http://<your-laptop-lan-ip>:8000`
- Deployed backend: `https://your-domain.com`

Then:

```bash
flutter run
```

Or for web:
```bash
flutter run -d chrome
```

---

## Testing the end-to-end flow

1. **Start the backend** (`uvicorn app.main:app --reload`)
2. **Start the Flutter app** on your preferred target
3. **Sign up** — creates a user in the `users` table
4. **Login** — receives a JWT that the `ApiClient` attaches to future requests
5. **Create a new form** from the dashboard → builder opens → add fields → hit Save
6. **Preview the form** from the builder (eye icon) → navigates to public form screen
7. **Submit a response** from the public view
8. **Check the Responses tab** → should show your submission
9. **Open Export** from a form → pick PDF or Excel → hits the backend export endpoint

If any step fails, check:
- Browser dev console (if on Flutter web) for CORS errors → backend CORS is set to `allow_origins=["*"]` so this should not happen
- Backend terminal for request logs
- `baseUrl` in `api_constants.dart` matches where the backend actually runs

---

## Known limitations (not fixed by integration — would need backend work)

- **No form UPDATE endpoint** — saving a form always creates a new one. A future `PUT /api/forms/{id}` would be needed.
- **No form DELETE endpoint** — deletion is local-only in the Flutter app.
- **Live/Draft toggle is local-only** — backend doesn't track this state.
- **User name** is captured on the Flutter signup form but not persisted (the `User` model only has email + password). Adding a `name` column + migration would fix this.
- **Analytics endpoint exists** on the backend but the Flutter Analytics screen was not wired to it (it shows static dashboard visuals). Wiring is one additional `ResponseService.getAnalytics()` call.

---

## Dockerized full-stack environment

The entire application stack is containerized using Docker Compose so the frontend, backend, database, and cache can be started together with a single command.

Services included

The Docker setup runs the following containers:

Flutter Web frontend (served via Nginx)
FastAPI backend (Uvicorn server)
PostgreSQL database
Redis cache

This allows the full system to run consistently across machines without manual dependency installation.

Running with Docker

From the backend/ directory:

docker compose up --build

This starts:

frontend → http://localhost:3000
backend → http://localhost:8000
Swagger UI → http://localhost:8000/docs
PostgreSQL → localhost:5432
Redis → localhost:6379

Stop services:

docker compose down
Verifying containers are running

Check active containers:
``bash
docker ps

Expected services:

internship-backend
flutter-frontend
postgres-db
redis-cache
Verifying PostgreSQL container
``bash
docker exec -it postgres-db psql -U postgres

Exit with:

\q
Verifying Redis container
docker exec -it redis-cache redis-cli

Then run:
``bash
ping

Expected response:

PONG
Persistent database storage

PostgreSQL uses a Docker volume to persist data.

Forms and responses remain available after restarting containers:
``bash
docker compose down
docker compose up
Frontend integration with Docker backend

The Flutter Web frontend is served through an Nginx container and accessed via:

http://localhost:3000

API requests are handled by the FastAPI backend exposed at:

http://localhost:8000

Login, form creation, response submission, analytics retrieval, and export endpoints were verified against the Dockerized API.

One-command startup workflow

The entire system can be launched with:

```bash
docker compose up --build

This initializes:

Flutter Web frontend
FastAPI API server
PostgreSQL database
Redis cache

Application:

http://localhost:3000

API documentation:

http://localhost:8000/docs
## System Architecture

Browser
   │
   ▼
Flutter Web (Nginx container) → FastAPI container
                                   │
                                   ├── PostgreSQL container
                                   └── Redis container

Explanation:

The browser loads the Flutter Web UI from the frontend container
Requests are sent to the FastAPI backend
The backend communicates with PostgreSQL for persistence
Redis is used for caching and performance optimization

## Credits

- Backend: FastAPI + SQLAlchemy + PostgreSQL (Neon) + Redis + ReportLab + openpyxl
- Frontend: Flutter 3.4 + Provider + GoRouter + Google Fonts + http
- Integration layer: added during this round (CORS, service layer, provider wiring)
