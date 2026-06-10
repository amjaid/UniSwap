# UniSwap

UniSwap is a university marketplace app for students to buy, sell, and swap items on campus. Built with **Flutter** (frontend) + **Django REST Framework** (backend) + **PostgreSQL**.

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

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x, Riverpod, GoRouter |
| **Backend** | Django 5.x, Django REST Framework |
| **Auth** | JWT (djangorestframework-simplejwt) |
| **Database** | PostgreSQL (SQLite for development) |
| **File Storage** | Django FileField (local / S3) |
| **State Management** | Riverpod (Flutter) |

## Project Structure

```
UniSwap/
├── lib/                          # Flutter frontend
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   ├── routes.dart           # GoRouter with auth redirect
│   │   └── theme.dart            # App theme
│   ├── models/                   # Data models
│   ├── services/                 # Django API service layer
│   │   ├── api_client.dart       # HTTP client + JWT interceptor
│   │   ├── django_auth_service.dart
│   │   ├── item_service.dart
│   │   ├── transaction_service.dart
│   │   ├── chat_service.dart
│   │   ├── django_notification_service.dart
│   │   ├── django_storage_service.dart
│   │   └── providers.dart        # Riverpod providers
│   ├── viewmodels/               # State management
│   ├── views/                    # Screens
│   └── widgets/                  # Reusable widgets
├── unswap_backend/               # Django backend
│   ├── settings.py               # DRF, JWT, CORS config
│   ├── urls.py                   # API routing (/api/)
│   ├── views.py                  # AdminStatsView
│   ├── users/                    # CustomUser, UserProfile, UserSettings
│   ├── items/                    # Item, Category, WishlistItem
│   ├── transactions/             # Transaction, Review
│   ├── chat/                     # Chat, ChatMessage
│   ├── notifications/            # Notification + signal handlers
│   └── tests/
│       └── test_api.py           # 47 integration tests
├── scripts/
│   └── migrate_from_firebase.py  # Firestore → Django migration
├── requirements.txt              # Python dependencies
├── pubspec.yaml                  # Flutter dependencies
└── documentation.md              # Full project documentation
```

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

## API Endpoints

All endpoints are under `/api/` prefix. See `documentation.md` for the full endpoint map.

### Auth
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register/` | POST | Register with university email |
| `/api/auth/token/` | POST | Obtain JWT access + refresh tokens |
| `/api/auth/token/refresh/` | POST | Refresh access token |
| `/api/auth/token/verify/` | POST | Verify token validity |

### Users
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/users/` | GET | List users (paginated) |
| `/api/users/{id}/` | GET | User detail |
| `/api/users/me/` | GET/PATCH | Current user profile |
| `/api/users/settings/` | GET/PATCH | User preferences |
| `/api/users/{id}/ratings/` | GET | Average rating |

### Items
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/items/` | GET/POST | List/Create items |
| `/api/items/{id}/` | GET/PATCH/DELETE | Item CRUD |
| `/api/items/{id}/mark_sold/` | POST | Seller marks sold |
| `/api/items/{id}/mark_available/` | POST | Seller re-lists |
| `/api/categories/` | GET | List categories |
| `/api/wishlist/` | GET/POST | User's wishlist |

### Transactions
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/transactions/` | GET/POST | User's transactions |
| `/api/transactions/{id}/complete/` | POST | Seller completes |
| `/api/transactions/{id}/cancel/` | POST | Either party cancels |
| `/api/reviews/` | GET/POST | Create/list reviews |

### Chat
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/chats/` | GET/POST | User's chats |
| `/api/chats/{id}/send_message/` | POST | Send message |
| `/api/chats/{id}/mark_read/` | POST | Mark messages read |

### Notifications
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/notifications/` | GET | User's notifications |
| `/api/notifications/unread/` | GET | Unread count + list |
| `/api/notifications/{id}/mark_read/` | POST | Mark one read |
| `/api/notifications/mark_all_read/` | POST | Mark all read |

### Admin
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/admin/stats/` | GET | Platform statistics (admin only) |

## Setup

### Backend (Django)

```bash
# Navigate to backend
cd unswap_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create admin user
python manage.py createsuperuser

# Start development server
python manage.py runserver 0.0.0.0:8000
```

### Frontend (Flutter)

```bash
# Install Flutter dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run on web
flutter run -d chrome
```

### Run Tests

```bash
cd unswap_backend
python manage.py test

# With coverage
pip install coverage
coverage run --source='.' manage.py test
coverage report
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DJANGO_SECRET_KEY` | (dev key) | Production secret key |
| `DJANGO_DEBUG` | True | Debug mode |
| `DJANGO_ALLOWED_HOSTS` | localhost,127.0.0.1,10.0.2.2 | Allowed hosts |
| `DATABASE_URL` | (SQLite) | PostgreSQL connection string |

## University Email Domains

Registration is restricted to these university domains:
- `utm.my` (Universiti Teknologi Malaysia)
- `student.utm.my`
- `um.edu.my` (Universiti Malaya)
- `ukm.edu.my` (Universiti Kebangsaan Malaysia)
- `upm.edu.my` (Universiti Putra Malaysia)
- `usm.my` (Universiti Sains Malaysia)
- `uim.edu.my` (Universiti Islam Malaysia)

Configure in `unswap_backend/settings.py` → `ALLOWED_UNIVERSITY_DOMAINS`.

## Migration from Firebase

The original app used Firebase Auth, Firestore, and Cloud Functions. The migration script at `scripts/migrate_from_firebase.py` exports Firestore collections to JSON and imports them into Django ORM.

## Design References

- Figma wireframes (PNG) live in `assets/wireframes/`
- App theme: `lib/config/theme.dart`
- Full documentation: `documentation.md`

## Key Paths

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point with notification polling |
| `lib/config/routes.dart` | GoRouter with auth state redirect |
| `lib/services/api_client.dart` | HTTP client with JWT interceptor |
| `lib/services/providers.dart` | Riverpod service providers |
| `unswap_backend/settings.py` | DRF, JWT, CORS, domain config |
| `unswap_backend/urls.py` | Main API routing |
| `unswap_backend/tests/test_api.py` | 47 integration tests |
| `documentation.md` | Full project documentation |
