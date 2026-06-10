# UniSwap - Flutter + Django REST Framework Migration

## Project Overview
UniSwap is a university marketplace app being migrated from Firebase to Django REST Framework (DRF) backend with PostgreSQL.

## Architecture
- **Frontend**: Flutter (Riverpod state management, GoRouter navigation)
- **Backend**: Django 5.x + DRF + SimpleJWT
- **Database**: PostgreSQL (SQLite for development)
- **Auth**: JWT tokens (djangorestframework-simplejwt)
- **File Storage**: Django FileField (local/S3)

---

## Phase 1: Project Setup & Data Models ✅ COMPLETE

### Django Project Structure
```
unswap_backend/          # Django project root
├── settings.py          # DRF, JWT, CORS, email validation config
├── urls.py              # Main URL routing (/api/ prefix)
├── views.py             # AdminStatsView (US-401)
├── wsgi.py / asgi.py
├── tests/
│   └── test_api.py      # 647 lines of integration tests
├── users/               # CustomUser, UserProfile, UserSettings
├── items/               # Item, Category, WishlistItem
├── transactions/        # Transaction, Review
├── chat/                # Chat, ChatMessage
└── notifications/       # Notification + signal handlers
```

### Django Apps Created
| App | Models | Key Features |
|-----|--------|-------------|
| **users** | CustomUser, UserProfile, UserSettings | Email auth, university domain validation, auto-create profile/settings on signup |
| **items** | Item, Category, WishlistItem | Full CRUD, search/filter, mark_sold/mark_available actions |
| **transactions** | Transaction, Review | Lifecycle (pending→completed/cancelled), rating system |
| **chat** | Chat, ChatMessage | Participant-based, send_message/mark_read actions |
| **notifications** | Notification | Signal-based creation on messages/transactions, unread polling |

### Key Configuration
- **JWT**: 30min access token, 7-day refresh, rotation enabled
- **CORS**: All origins in debug, restricted in production
- **Pagination**: 20 items per page
- **Throttling**: 100/hr anonymous, 1000/hr authenticated
- **University domains**: utm.my, um.edu.my, ukm.edu.my, upm.edu.my, usm.my, uim.edu.my
- **File uploads**: 10MB max, jpg/jpeg/png/gif/webp only

---

## Phase 2: API Endpoints ✅ COMPLETE

### Endpoint Map
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/auth/token/` | POST | No | Obtain JWT pair |
| `/api/auth/token/refresh/` | POST | No | Refresh access token |
| `/api/auth/token/verify/` | POST | No | Verify token validity |
| `/api/auth/register/` | POST | No | Register with email validation |
| `/api/users/` | GET | Yes | List users (paginated) |
| `/api/users/{id}/` | GET | Yes | User detail |
| `/api/users/me/` | GET/PATCH | Yes | Current user profile |
| `/api/users/settings/` | GET/PATCH | Yes | User preferences |
| `/api/users/{id}/ratings/` | GET | Yes | Average rating |
| `/api/items/` | GET/POST | Mixed | List/Create items |
| `/api/items/{id}/` | GET/PATCH/DELETE | Mixed | Item CRUD |
| `/api/items/{id}/mark_sold/` | POST | Yes | Seller marks sold |
| `/api/items/{id}/mark_available/` | POST | Yes | Seller re-lists |
| `/api/categories/` | GET | No | List categories |
| `/api/wishlist/` | GET/POST | Yes | User's wishlist |
| `/api/wishlist/{id}/` | DELETE | Yes | Remove from wishlist |
| `/api/transactions/` | GET/POST | Yes | User's transactions |
| `/api/transactions/{id}/complete/` | POST | Yes | Seller completes |
| `/api/transactions/{id}/cancel/` | POST | Yes | Either party cancels |
| `/api/reviews/` | GET/POST | Yes | Create/list reviews |
| `/api/chats/` | GET/POST | Yes | User's chats |
| `/api/chats/{id}/send_message/` | POST | Yes | Send message |
| `/api/chats/{id}/mark_read/` | POST | Yes | Mark messages read |
| `/api/messages/` | GET | Yes | Filter messages |
| `/api/notifications/` | GET | Yes | User's notifications |
| `/api/notifications/unread/` | GET | Yes | Unread count + list |
| `/api/notifications/{id}/mark_read/` | POST | Yes | Mark one read |
| `/api/notifications/mark_all_read/` | POST | Yes | Mark all read |
| `/api/admin/stats/` | GET | Admin | Platform statistics |

---

## Phase 3: Flutter Client Refactoring ✅ COMPLETE

### New Service Layer (replaces Firebase)
| File | Class | Purpose |
|------|-------|---------|
| `lib/services/api_client.dart` | `ApiClient` | HTTP client with JWT interceptor, token refresh, error handling |
| `lib/services/django_auth_service.dart` | `DjangoAuthService` | Login, register, logout, profile, settings, password reset |
| `lib/services/item_service.dart` | `ItemService` | Item CRUD, search/filter, wishlist, mark_sold/available |
| `lib/services/transaction_service.dart` | `TransactionService` | Transaction lifecycle, reviews |
| `lib/services/chat_service.dart` | `ChatService` | Chats, messages, polling for real-time updates |
| `lib/services/django_notification_service.dart` | `DjangoNotificationService` | Notifications CRUD, unread polling |
| `lib/services/django_storage_service.dart` | `DjangoStorageService` | Image uploads for items and avatars |
| `lib/services/providers.dart` | Riverpod providers | All service providers + auth state provider |

### Updated Files
| File | Changes |
|------|---------|
| `lib/main.dart` | Removed Firebase init, uses DjangoNotificationService polling |
| `lib/config/routes.dart` | Uses `authStateProvider` (FutureProvider) instead of Firebase StreamProvider |
| `pubspec.yaml` | Added `http`, `shared_preferences`, `share_plus`, `tutorial_coach_mark` |

### Key Design Decisions
- **Token storage**: SharedPreferences (access + refresh tokens)
- **Auto-refresh**: ApiClient intercepts 401, attempts refresh, retries request
- **Real-time**: Polling-based (5s for chat, 30s for notifications)
- **Error handling**: Typed `ApiResponse` with success/error pattern
- **Base URL**: `http://10.0.2.2:8000/api` (Android emulator → localhost)

---

## Phase 4: Data Migration Script ✅ COMPLETE

### Script: `scripts/migrate_from_firebase.py`
- Exports all Firestore collections to JSON
- Uses Django ORM to load data preserving relationships
- Handles Firestore document ID → Django PK mapping
- Includes error handling and progress logging

---

## Phase 5: Sprint 4 Features ✅ COMPLETE

### US-401: Admin Stats & Reports
- `AdminStatsView` at `/api/admin/stats/`
- Returns: total_users, active_listings, monthly_transactions, avg_rating
- Admin-only access (IsAdminUser permission)
- Includes users_by_domain, items_by_category, recent_transactions

### US-402: Notifications
- `Notification` model with types: NEW_MESSAGE, OFFER_UPDATE, TRANSACTION_UPDATE
- Signal handlers auto-create notifications on:
  - New chat messages (notifies all other participants)
  - Transaction creation/status changes (notifies buyer + seller)
- API endpoints: list, unread count, mark_read, mark_all_read
- Flutter polls every 30 seconds for unread count

### US-403: Share Items (Frontend)
- Added `share_plus` package to pubspec.yaml
- No backend changes needed

### US-404: University Email Validation
- `ALLOWED_UNIVERSITY_DOMAINS` in settings.py
- `UserRegistrationSerializer.validate_email()` checks domain against allowlist
- Domains configured: utm.my, um.edu.my, ukm.edu.my, upm.edu.my, usm.my, uim.edu.my
- Domain auto-extracted and stored in `CustomUser.university_domain`

### US-405: Interactive Tutorial (Frontend)
- Added `tutorial_coach_mark` package to pubspec.yaml
- No backend changes needed

### US-406: Preferences & Settings
- `UserSettings` model (one-to-one with CustomUser)
- Fields: notification_enabled, theme (light/dark/system), language (en/ms/zh)
- Auto-created on user registration via signal
- API: GET/PATCH `/api/users/settings/`

### US-407: Comprehensive Testing
- 647 lines of integration tests in `unswap_backend/tests/test_api.py`
- Test classes:
  - `AuthenticationTests` - registration, JWT token lifecycle
  - `UserTests` - profile CRUD, settings, ratings
  - `ItemTests` - CRUD, permissions, search, filters
  - `WishlistTests` - add/remove/list
  - `TransactionTests` - create/complete/cancel
  - `ReviewTests` - create, self-review prevention, immutability
  - `ChatTests` - create, send message, mark read
  - `NotificationTests` - list, unread, mark read, mark all read
  - `AdminStatsTests` - admin-only access, data integrity
  - `NotificationSignalTests` - auto-creation on messages/transactions

---

## Running the Project

### Backend (Django)
```bash
cd unswap_backend
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

### Run Tests
```bash
python manage.py test
# Or with coverage:
pip install coverage
coverage run --source='.' manage.py test
coverage report
```

### Frontend (Flutter)
```bash
flutter pub get
flutter run
```

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `DJANGO_SECRET_KEY` | (dev key) | Production secret key |
| `DJANGO_DEBUG` | True | Debug mode |
| `DJANGO_ALLOWED_HOSTS` | localhost,127.0.0.1,10.0.2.2 | Allowed hosts |
| `DATABASE_URL` | (SQLite) | PostgreSQL connection string |

---

## Next Steps / Future Work
1. **WebSocket support** for real-time chat (replace polling)
2. **Push notifications** via FCM/APNs
3. **S3 file storage** configuration for production
4. **CI/CD pipeline** with automated testing
5. **Docker Compose** for local development
6. **Rate limiting** refinement for production
7. **Flutter screens** update to use new service layer (in progress)
