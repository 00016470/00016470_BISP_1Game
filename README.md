# 🎮 Gaming Club Booking System

[![CI/CD](https://github.com/gaming-club-tashkent/gaming_club_tashkent/actions/workflows/ci.yml/badge.svg)](https://github.com/gaming-club-tashkent/gaming_club_tashkent/actions/workflows/ci.yml)
[![Python 3.11](https://img.shields.io/badge/python-3.11-blue.svg)](https://www.python.org/downloads/)
[![Flutter 3.16](https://img.shields.io/badge/flutter-3.16.0-02569B.svg?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688.svg?logo=fastapi)](https://fastapi.tiangolo.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A full-stack mobile application for discovering and booking gaming club sessions in Tashkent. Built with a **FastAPI** backend and a **Flutter** mobile app following Clean Architecture principles.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Gaming Club Booking System                    │
├─────────────────┬───────────────────────────────────────────────┤
│   Flutter App   │              FastAPI Backend                   │
│  (Clean Arch)   │  ┌──────────┐  ┌────────┐  ┌─────────────┐  │
│                 │  │  Routers │→ │Services│→ │  SQLAlchemy │  │
│  BLoC + Repos   │  └──────────┘  └────────┘  └──────┬──────┘  │
│  Dio + JWT      │  ┌──────────┐              ┌──────▼──────┐  │
│  GoRouter       │  │  Auth    │              │ PostgreSQL  │  │
└───────┬─────────┘  │  Limiter │              └─────────────┘  │
        │            └──────────┘                                 │
        └──────────────────── HTTP REST API ───────────────────────┘
```

---

## Features

- 🔐 **JWT Authentication** — Access + refresh token flow with secure rotation
- 🏪 **Club Discovery** — Browse, search, and filter gaming clubs by rating or price
- 📅 **Slot Booking** — View available time slots and create reservations
- ❌ **Booking Management** — View history and cancel upcoming bookings
- 🔄 **Auto Status Updates** — Scheduled job marks past bookings as completed
- 🚦 **Rate Limiting** — Per-endpoint rate limiting via SlowAPI
- 📱 **Offline Support** — Connectivity detection with user-facing offline banner
- 🎨 **Neon/Glassmorphism UI** — Dark-themed gaming aesthetic with smooth animations

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter 3.16, Dart 3 |
| State Management | flutter_bloc 8 (BLoC pattern) |
| Navigation | GoRouter 12 |
| HTTP Client | Dio 5 + flutter_secure_storage |
| Architecture | Clean Architecture (Data / Domain / Presentation) |
| Backend | FastAPI 0.111, Python 3.11 |
| ORM | SQLAlchemy 2.0 (async) |
| Database | PostgreSQL 15 |
| Migrations | Alembic |
| Auth | python-jose (JWT), passlib (bcrypt) |
| Scheduler | APScheduler 3 |
| Rate Limiting | SlowAPI |
| Containerisation | Docker + Docker Compose |
| CI/CD | GitHub Actions |

---

## Local Development

### Prerequisites

- Python 3.11+
- Flutter 3.16+
- PostgreSQL 15 (or Docker)

### Backend

```bash
cd backend

# Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy and configure environment variables
cp .env.example .env             # edit DATABASE_URL, SECRET_KEY, etc.

# Run database migrations
alembic upgrade head

# Start the development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs are available at <http://localhost:8000/docs>.

### Flutter App

```bash
cd flutter_app

# Fetch packages
flutter pub get

# Run on a connected device or emulator
flutter run
```

Update `lib/config/constants.dart` to point `baseUrl` at your backend if needed.

---

## Docker (Recommended)

Spin up the full stack — PostgreSQL + FastAPI — with a single command:

```bash
# Build and start all services
docker compose up --build

# Run in the background
docker compose up --build -d

# Tear down (keeps postgres_data volume)
docker compose down

# Tear down and remove all data
docker compose down -v
```

The API will be available at <http://localhost:8000> and the database at `localhost:5432`.

> **⚠️ Production note:** Replace `SECRET_KEY` in `docker-compose.yml` with a strong random value before deploying.

---

## API Endpoints

### Auth — `/api/auth`

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/api/auth/register` | ❌ | Register a new user; returns token pair |
| `POST` | `/api/auth/login` | ❌ | Login with email + password; returns token pair |
| `POST` | `/api/auth/refresh` | ❌ | Exchange a refresh token for a new token pair |

### Clubs — `/api/clubs`

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `GET` | `/api/clubs` | ❌ | List clubs; supports `?search=` and `?sortBy=rating\|price` |
| `GET` | `/api/clubs/{club_id}` | ❌ | Get details of a single club |
| `GET` | `/api/clubs/{club_id}/slots` | ❌ | Get available time slots for a date (`?date=YYYY-MM-DD`) |

### Bookings — `/api/bookings`

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/api/bookings` | ✅ | Create a new booking |
| `GET` | `/api/bookings` | ✅ | List the current user's bookings |
| `GET` | `/api/bookings/{booking_id}` | ✅ | Get a specific booking |
| `DELETE` | `/api/bookings/{booking_id}` | ✅ | Cancel a booking |

### System

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `GET` | `/health` | ❌ | Health check — returns `{"status": "ok"}` |
| `GET` | `/docs` | ❌ | Interactive Swagger UI |
| `GET` | `/redoc` | ❌ | ReDoc documentation |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql+asyncpg://postgres:password@localhost:5432/gaming_club` | Async PostgreSQL connection string |
| `SECRET_KEY` | *(insecure dev default)* | JWT signing secret — **change in production** |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `15` | Access token lifetime (minutes) |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `7` | Refresh token lifetime (days) |
| `ALLOWED_ORIGINS` | `http://localhost:3000,...` | Comma-separated CORS origins |
| `RATE_LIMIT_PER_MINUTE` | `100` | Max requests per minute per IP |

Create a `backend/.env` file to override defaults during local development.

---

## Running Tests

### Backend

```bash
cd backend

# All tests with verbose output
python -m pytest tests/ -v --tb=short

# With coverage report
python -m pytest tests/ -v --cov=app --cov-report=term-missing
```

### Flutter

```bash
cd flutter_app

# Unit + widget tests
flutter test

# With coverage
flutter test --coverage
```

---

## Project Structure

```
gaming_club_tashkent/
├── docker-compose.yml
├── README.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── alembic.ini
│   ├── alembic/
│   │   ├── env.py
│   │   └── versions/
│   │       └── 001_initial.py
│   └── app/
│       ├── main.py
│       ├── config.py
│       ├── database.py
│       ├── dependencies.py
│       ├── exceptions.py
│       ├── jobs/
│       │   └── booking_status_job.py
│       ├── middleware/
│       │   └── logging_middleware.py
│       ├── models/
│       │   ├── user.py
│       │   ├── club.py
│       │   ├── booking.py
│       │   └── refresh_token.py
│       ├── routers/
│       │   ├── auth.py
│       │   ├── clubs.py
│       │   └── bookings.py
│       ├── schemas/
│       │   ├── auth.py
│       │   ├── club.py
│       │   ├── booking.py
│       │   ├── slot.py
│       │   └── common.py
│       ├── services/
│       │   ├── auth_service.py
│       │   ├── club_service.py
│       │   ├── booking_service.py
│       │   └── slot_service.py
│       └── tests/
│           ├── conftest.py
│           ├── test_auth.py
│           ├── test_clubs.py
│           └── test_bookings.py
└── flutter_app/
    ├── pubspec.yaml
    ├── analysis_options.yaml
    ├── lib/
    │   ├── config/
    │   │   ├── constants.dart
    │   │   ├── router.dart
    │   │   └── theme.dart
    │   ├── core/
    │   │   ├── error/
    │   │   ├── network/
    │   │   ├── usecases/
    │   │   └── widgets/
    │   └── features/
    │       ├── auth/
    │       │   ├── data/
    │       │   ├── domain/
    │       │   └── presentation/
    │       ├── bookings/
    │       │   ├── data/
    │       │   ├── domain/
    │       │   └── presentation/
    │       └── clubs/
    │           ├── data/
    │           ├── domain/
    │           └── presentation/
    └── test/
```

---

## CI/CD

The GitHub Actions pipeline (`.github/workflows/ci.yml`) runs on every push and pull request to `main`:

| Job | Trigger | Description |
|-----|---------|-------------|
| `backend-tests` | push / PR | Runs pytest against a live PostgreSQL 15 service container |
| `flutter-tests` | push / PR | Runs `flutter test` |
| `build-apk` | push to `main` only | Builds a release APK and uploads it as a workflow artifact |

---

## License

This project is licensed under the [MIT License](LICENSE).
