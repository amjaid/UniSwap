# UniSwap Backend

Django REST Framework backend for the UniSwap university marketplace app.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Django 5.x + Django REST Framework |
| **Auth** | JWT (djangorestframework-simplejwt) |
| **Database** | PostgreSQL (SQLite for development) |
| **File Storage** | Django FileField (local / S3) |
| **CORS** | django-cors-headers |
| **Filtering** | django-filter |

## Project Structure

```
backend/
├── manage.py                  # Django management script
├── requirements.txt           # Python dependencies
├── db.sqlite3                 # Development database (gitignored)
├── .gitignore
├── README.md
├── unswap_backend/            # Project configuration
│   ├── settings.py            # DRF, JWT, CORS, domain config
│   ├── urls.py                # Main API routing (/api/)
│   ├── views.py               # AdminStatsView
│   ├── wsgi.py                # WSGI entry point
│   └── asgi.py                # ASGI entry point
├── users/                     # CustomUser, UserProfile, UserSettings
├── items/                     # Item, Category, WishlistItem
├── transactions/              # Transaction, Review
├── chat/                      # Chat, ChatMessage
├── notifications/             # Notification + signal handlers
├── scripts/
│   └── migrate_from_firebase.py  # Firestore → Django migration
└── unswap_backend/tests/
    └── test_api.py            # 47 integration tests
```

## Models

| App | Models |
|-----|--------|
| `users` | CustomUser, UserProfile, UserSettings |
| `items` | Category, Item, WishlistItem |
| `transactions` | Transaction, Review |
| `chat` | Chat, ChatMessage |
| `notifications` | Notification |

## API Endpoints

All endpoints are under `/api/` prefix.

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

### Prerequisites
- Python 3.10+
- pip

### Installation

```bash
# Navigate to backend
cd backend

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

### Run Tests

```bash
cd backend
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

Registration is restricted to these university domains (configured in `unswap_backend/settings.py`):
- `utm.my` (Universiti Teknologi Malaysia)
- `student.utm.my`
- `um.edu.my` (Universiti Malaya)
- `ukm.edu.my` (Universiti Kebangsaan Malaysia)
- `upm.edu.my` (Universiti Putra Malaysia)
- `usm.my` (Universiti Sains Malaysia)
- `uim.edu.my` (Universiti Islam Malaysia)

## Migration from Firebase

```bash
cd backend
python scripts/migrate_from_firebase.py migrate --project=unswap-app
```

## Testing

47 integration tests covering all major endpoints:

```bash
cd backend
python manage.py test
```
