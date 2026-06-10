# UniSwap

UniSwap is a university marketplace app for students to buy, sell, and swap items on campus.

## Architecture

```
┌─────────────────────┐      HTTP/JSON       ┌──────────────────────┐
│   Flutter App        │ ◄──────────────────► │  Django REST API     │
│   (Riverpod +        │      JWT Auth        │  (DRF + SimpleJWT)   │
│    GoRouter)         │                      │                      │
└─────────────────────┘                      └──────┬───────────────┘
                                                    │
                                           ┌────────▼────────┐
                                           │   PostgreSQL    │
                                           └─────────────────┘
```

## Repository Structure

```
UniSwap/
├── frontend/          # Flutter mobile app
│   ├── lib/           # Dart source code
│   ├── android/       # Android platform
│   ├── ios/           # iOS platform
│   ├── web/           # Web platform
│   ├── test/          # Flutter tests
│   ├── pubspec.yaml   # Flutter dependencies
│   └── README.md      # Frontend documentation
│
├── backend/           # Django REST API
│   ├── manage.py      # Django management script
│   ├── requirements.txt
│   ├── users/         # CustomUser, UserProfile, UserSettings
│   ├── items/         # Item, Category, WishlistItem
│   ├── transactions/  # Transaction, Review
│   ├── chat/          # Chat, ChatMessage
│   ├── notifications/ # Notification + signal handlers
│   ├── unswap_backend/ # Project config (settings, urls)
│   ├── scripts/       # Firebase migration script
│   └── README.md      # Backend documentation
│
├── docs/              # Additional documentation
├── assets/            # Shared assets (wireframes, etc.)
├── documentation.md   # Full project documentation
└── README.md          # This file
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x, Riverpod, GoRouter |
| **Backend** | Django 5.x, Django REST Framework |
| **Auth** | JWT (djangorestframework-simplejwt) |
| **Database** | PostgreSQL (SQLite for development) |
| **File Storage** | Django FileField (local / S3) |
| **State Management** | Riverpod (Flutter) |

## Features

### Sprint 1-3 (Complete)
- **Auth**: Sign-in, sign-up, email verification, forgot password
- **Listings**: Home feed, explore with search/filter, create listing, listing detail
- **Profile**: User profile, ratings, transaction history
- **Swap Hub**: Transaction timeline tracking and status actions
- **Inbox + Chat**: Real-time messaging with polling, unread counts
- **Notifications**: In-app notifications with polling

### Sprint 4 (Complete - Django Backend)
| US | Feature | Status |
|----|---------|--------|
| US-401 | Admin stats & reports dashboard | ✅ |
| US-402 | Notification system with signals | ✅ |
| US-403 | Share items (frontend intents) | ✅ |
| US-404 | University email domain validation | ✅ |
| US-405 | Interactive tutorial (frontend) | ✅ |
| US-406 | User preferences & settings | ✅ |
| US-407 | Comprehensive API testing | ✅ (47 tests) |

## Quick Start

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate     # Windows
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

### Frontend

```bash
flutter pub get
flutter run
```

See `backend/README.md` and `frontend/README.md` for detailed setup instructions.

## Documentation

- **Full documentation**: `documentation.md`
- **Backend API**: `backend/README.md`
- **Frontend setup**: `frontend/README.md`

## Migration from Firebase

The original app used Firebase Auth, Firestore, and Cloud Functions. The migration script at `backend/scripts/migrate_from_firebase.py` exports Firestore collections to JSON and imports them into Django ORM.

```bash
cd backend
python scripts/migrate_from_firebase.py migrate --project=unswap-app
```
