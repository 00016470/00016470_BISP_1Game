# 🎮 1Game — Gaming Club Booking System

[![Python 3.11](https://img.shields.io/badge/python-3.11-blue.svg)](https://www.python.org/downloads/)
[![Flutter 3.16](https://img.shields.io/badge/flutter-3.16.0-02569B.svg?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688.svg?logo=fastapi)](https://fastapi.tiangolo.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A full-stack mobile application for discovering and booking gaming club sessions in Tashkent. Built with a **FastAPI** backend and a **Flutter** mobile app following Clean Architecture principles. Pre-loaded with **20 real gaming clubs** across Tashkent with interactive map integration.

**Live API:** <https://1game-api-production.up.railway.app>

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                           1Game Platform                             │
├──────────────────┬───────────────────────────────────────────────────┤
│   Flutter App    │              FastAPI Backend (v2.0.0)             │
│  (Clean Arch)    │  ┌──────────┐  ┌─────────┐  ┌──────────────┐   │
│                  │  │ Routers  │→ │Services │→ │  SQLAlchemy  │   │
│  BLoC + Repos    │  └──────────┘  └─────────┘  └──────┬───────┘   │
│  Dio + JWT       │  ┌──────────┐  ┌─────────┐  ┌──────▼───────┐   │
│  GoRouter        │  │  Auth    │  │  Admin  │  │  PostgreSQL  │   │
│  Flutter Map     │  │  Limiter │  │  Panel  │  │  (Railway)   │   │
└───────┬──────────┘  └──────────┘  └─────────┘  └──────────────┘   │
        │                                                              │
        └──────────────────── HTTP REST API ────────────────────────────┘
```

---

## Features

### Core
- 🔐 **JWT Authentication** — Access + refresh token flow with secure rotation
- 🏪 **Club Discovery** — Browse, search, and filter 20 real Tashkent gaming clubs by rating or price
- 🗺️ **Interactive Map** — Locate clubs on an OpenStreetMap-based map with location markers
- 📅 **Slot Booking** — View available time slots and create reservations (single & multi-slot)
- ❌ **Booking Management** — View history and cancel upcoming bookings
- 🔄 **Auto Status Updates** — Background job marks past bookings as completed every 2 minutes

### Wallet & Payments
- 💰 **Digital Wallet** — In-app wallet with balance management
- 💳 **Payment Processing** — Pay for bookings via wallet balance
- 📊 **Transaction History** — Full transaction ledger with filtering

### Admin
- 🛡️ **Admin Panel** — Manage clubs, view all bookings, track revenue across multiple clubs
- 📸 **Photo Upload** — Upload club images via the admin interface
- 📈 **Revenue Dashboard** — Multi-club revenue analytics

### UX
- 📱 **Offline Support** — Connectivity detection with user-facing offline banner
- 🎨 **Neon/Glassmorphism UI** — Dark-themed gaming aesthetic with smooth animations
- 🚦 **Rate Limiting** — Per-endpoint rate limiting via SlowAPI

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter 3.16, Dart 3 |
| State Management | flutter_bloc (BLoC pattern) |
| Navigation | GoRouter |
| HTTP Client | Dio + flutter_secure_storage |
| Maps | Flutter Map + OpenStreetMap tiles |
| Location | Geolocator + Geocoding |
| Architecture | Clean Architecture (Data / Domain / Presentation) |
| Backend | FastAPI 0.111, Python 3.11 |
| ORM | SQLAlchemy 2.0 (async) |
| Database | PostgreSQL 15 (Railway) |
| Migrations | Alembic (3 migrations) |
| Auth | python-jose (JWT), passlib (bcrypt) |
| Scheduler | APScheduler 3 |
| Rate Limiting | SlowAPI |
| Containerisation | Docker + Docker Compose |
| Deployment | Railway (backend + PostgreSQL) |
| Android Package | `com.onegame.app` |

---

## Deployment

The backend is deployed on **Railway** with a managed PostgreSQL database.

| Component | Platform | URL |
|-----------|----------|-----|
| API | Railway | <https://1game-api-production.up.railway.app> |
| Database | Railway PostgreSQL | Managed (internal) |
| Mobile App | Android APK | Built locally via `flutter build apk --release` |

### Deploy to Railway

1. Install [Railway CLI](https://docs.railway.app/develop/cli)
2. Link the project:
   ```bash
   cd backend
   railway link
   ```
3. Set environment variables on Railway dashboard:
   - `DATABASE_URL` — provided by Railway PostgreSQL plugin
   - `SECRET_KEY` — a strong random value
   - `ENVIRONMENT` — `production`
   - `ALLOWED_ORIGINS` — `*` or your domain
   - `RATE_LIMIT_PER_MINUTE` — `60`
4. Deploy:
   ```bash
   railway up
   ```

The `Procfile` runs migrations automatically before starting the server. Health checks are configured at `/health`.

### Build Release APK

```bash
cd flutter_app
flutter build apk --release --dart-define=BASE_URL=https://1game-api-production.up.railway.app
```

The APK is output to `build/app/outputs/flutter-apk/app-release.apk`.

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

Pass `--dart-define=BASE_URL=http://10.0.2.2:8000` for Android emulator, or update `lib/config/constants.dart`.

---

## Docker

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

Services include persistent volumes for `postgres_data` and `uploads_data`.

> **⚠️ Production note:** Set `SECRET_KEY` and `POSTGRES_PASSWORD` via environment variables — never commit secrets.

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
| `POST` | `/api/bookings` | ✅ | Create a new booking (single or multi-slot) |
| `GET` | `/api/bookings` | ✅ | List the current user's bookings |
| `GET` | `/api/bookings/{booking_id}` | ✅ | Get a specific booking |
| `DELETE` | `/api/bookings/{booking_id}` | ✅ | Cancel a booking |

### Wallet — `/api/wallet`

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `GET` | `/api/wallet` | ✅ | Get current wallet balance |
| `POST` | `/api/wallet/topup` | ✅ | Add funds to wallet |

### Transactions — `/api/transactions`

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `GET` | `/api/transactions` | ✅ | List user's transaction history |

### Payments — `/api/payments`

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/api/payments` | ✅ | Process a payment for a booking |

### Admin — `/api/admin`

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `GET` | `/api/admin/bookings` | ✅ 🛡️ | List all bookings (admin only) |
| `GET` | `/api/admin/revenue` | ✅ 🛡️ | Revenue analytics across clubs |
| `POST` | `/api/admin/clubs` | ✅ 🛡️ | Create a new club |
| `PUT` | `/api/admin/clubs/{club_id}` | ✅ 🛡️ | Update a club |

### Uploads — `/api/uploads`

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `POST` | `/api/uploads` | ✅ | Upload a club image |

### System

| Method | Path | Auth | Description |
|--------|------|:----:|-------------|
| `GET` | `/health` | ❌ | Health check — returns `{"status": "ok", "version": "2.0.0"}` |
| `GET` | `/docs` | ❌ | Interactive Swagger UI |
| `GET` | `/redoc` | ❌ | ReDoc documentation |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `sqlite+aiosqlite:///./gaming_club.db` | Database connection string (auto-converted to async for PostgreSQL) |
| `SECRET_KEY` | *(insecure dev default)* | JWT signing secret — **change in production** |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `15` | Access token lifetime (minutes) |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `7` | Refresh token lifetime (days) |
| `ALLOWED_ORIGINS` | `http://localhost:3000,...` | Comma-separated CORS origins |
| `RATE_LIMIT_PER_MINUTE` | `100` | Max requests per minute per IP |
| `ENVIRONMENT` | `development` | Set to `production` for production mode |

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
├── backend/
│   ├── Dockerfile
│   ├── Procfile
│   ├── railway.json
│   ├── requirements.txt
│   ├── alembic.ini
│   ├── alembic/
│   │   ├── env.py
│   │   └── versions/
│   │       ├── 001_initial.py
│   │       ├── 002_phase2.py
│   │       └── 003_admin_features.py
│   └── app/
│       ├── main.py
│       ├── config.py
│       ├── database.py
│       ├── dependencies.py
│       ├── exceptions.py
│       ├── seed.py
│       ├── jobs/
│       │   └── booking_status_job.py
│       ├── middleware/
│       │   └── logging_middleware.py
│       ├── models/
│       │   ├── admin.py
│       │   ├── booking.py
│       │   ├── club.py
│       │   ├── payment.py
│       │   ├── refresh_token.py
│       │   ├── transaction.py
│       │   ├── user.py
│       │   └── wallet.py
│       ├── routers/
│       │   ├── admin.py
│       │   ├── auth.py
│       │   ├── bookings.py
│       │   ├── clubs.py
│       │   ├── payments.py
│       │   ├── transactions.py
│       │   ├── uploads.py
│       │   └── wallet.py
│       ├── schemas/
│       │   ├── admin.py
│       │   ├── auth.py
│       │   ├── booking.py
│       │   ├── club.py
│       │   ├── common.py
│       │   ├── payment.py
│       │   ├── slot.py
│       │   ├── transaction.py
│       │   └── wallet.py
│       └── services/
│           ├── admin_service.py
│           ├── auth_service.py
│           ├── booking_service.py
│           ├── club_service.py
│           ├── payment_service.py
│           ├── slot_service.py
│           ├── transaction_service.py
│           └── wallet_service.py
├── backend/tests/
│   ├── conftest.py
│   ├── test_admin.py
│   ├── test_auth.py
│   ├── test_bookings.py
│   ├── test_clubs.py
│   ├── test_multi_slot.py
│   ├── test_payments.py
│   └── test_wallet.py
└── flutter_app/
    ├── pubspec.yaml
    ├── analysis_options.yaml
    ├── assets/
    │   └── icon/
    │       └── app_icon.png
    ├── android/
    │   └── app/
    │       ├── build.gradle.kts
    │       └── proguard-rules.pro
    ├── lib/
    │   ├── main.dart
    │   ├── home_scaffold.dart
    │   ├── injection.dart
    │   ├── router.dart
    │   ├── config/
    │   ├── core/
    │   └── features/
    │       ├── admin/
    │       ├── auth/
    │       ├── bookings/
    │       ├── clubs/
    │       ├── map/
    │       ├── payment/
    │       ├── profile/
    │       ├── transactions/
    │       └── wallet/
    └── test/
```

---

## Seed Data

The backend automatically seeds **20 real gaming clubs** in Tashkent on first startup, including:
- Club names and addresses
- GPS coordinates for map display
- Pricing, ratings, and available PCs/consoles
- Operating hours and contact information

---

## License

This project is licensed under the [MIT License](LICENSE).
