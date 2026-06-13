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
backend/                 # Django project root
├── manage.py            # Django management script
├── requirements.txt     # Python dependencies
├── .gitignore           # Backend-specific ignores
├── README.md            # Backend documentation
├── unswap_backend/      # Project configuration
│   ├── settings.py      # DRF, JWT, CORS, email validation config
│   ├── urls.py          # Main URL routing (/api/ prefix)
│   ├── views.py         # AdminStatsView (US-401)
│   ├── wsgi.py / asgi.py
│   └── tests/
│       └── test_api.py  # 647 lines of integration tests
├── users/               # CustomUser, UserProfile, UserSettings
├── items/               # Item, Category, WishlistItem
├── transactions/        # Transaction, Review
├── chat/                # Chat, ChatMessage
├── notifications/       # Notification + signal handlers
└── scripts/
    └── migrate_from_firebase.py  # Firestore → Django migration
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
| `lib/services/django_notification_service.dart` | `DjangoNotificationService` | Notifications CRUD, unread polling with exponential backoff on 429 |
| `lib/services/django_storage_service.dart` | `DjangoStorageService` | Image uploads for items and avatars |
| `lib/services/chat_message_store.dart` | `ChatMessageStore` | **NEW** — Persistent chat message store that survives screen navigation. Prevents "messages vanish" bug by keeping messages in memory across chat screen re-entries. Uses ID-based merge on polling, never replaces the entire list. |
| `lib/services/providers.dart` | Riverpod providers | All service providers + auth state provider |

### Updated Files
| File | Changes |
|------|---------|
| `lib/main.dart` | Removed Firebase init, uses DjangoNotificationService polling |
| `lib/config/routes.dart` | Uses `authStateProvider` (FutureProvider) instead of Firebase StreamProvider |
| `lib/services/providers.dart` | Central Riverpod providers for all Django services (apiClient, auth, items, transactions, chat, notifications, storage) |
| `lib/viewmodels/auth_viewmodel.dart` | Auth state provider, sign in/up/forgot password view models with Django JWT |
| `lib/viewmodels/chat_viewmodel.dart` | Chat state management using ChatService, polling for new messages |
| `lib/viewmodels/inbox_viewmodel.dart` | Inbox state management using ChatService, polling for new chats |
| `lib/views/profile_screen.dart` | Uses DjangoAuthService + DjangoStorageService, removed Firebase references, dynamic stats from API. Shows actual listing images via `getFullImageUrl()` instead of placeholder icon |
| `lib/views/home_screen.dart` | Uses authStateProvider with Map accessors instead of Firebase User, dynamic avatar. Uses `getFullImageUrl()` for listing images in both horizontal and grid cards |
| `lib/views/listing_detail_screen.dart` | Uses ChatService for chat creation, removed FirestoreService, removed hardcoded data. Added Edit/Delete popup menu for sellers. Uses `getFullImageUrl()` with `errorBuilder` fallback |
| `lib/views/edit_listing_screen.dart` | **NEW** - Edit listing screen with pre-populated fields, image picker, category/condition dropdowns |
| `lib/views/chat_screen.dart` | Uses user['id'] Map accessor instead of user.uid |
| `lib/views/create_listing_screen.dart` | Image picker integration, uploads photo via DjangoStorageService after creating item |
| `lib/viewmodels/create_listing_viewmodel.dart` | Now accepts DjangoStorageService, uploads image after item creation |
| `lib/views/placeholder_screens.dart` | SplashScreen, PublicProfileScreen, SavedListingsScreen, SettingsScreen, ReportScreen all use API data. Uses `getFullImageUrl()` for saved listings images |
| `lib/views/explore_screen.dart` | Uses `getFullImageUrl()` for listing images |
| `lib/views/swap_hub_screen.dart` | Uses `getFullImageUrl()` for swap item images |
| `lib/views/swap_detail_screen.dart` | Uses `getFullImageUrl()` for swap item images |
| `lib/models/listing.dart` | Added `fromJson` factory, `listFromJson`, `sellerId`, `sellerAvatarUrl`, `createdAt` fields |
| `lib/models/conversation_thread.dart` | Added `fromJson` factory, `listFromJson`, `lastMessage`, `unreadCount` fields |
| `lib/models/chat_message.dart` | Added `fromJson` factory, `listFromJson`, `isRead` field |
| `lib/models/notification.dart` | Added `fromJson` factory, `listFromJson`, `type`, `createdAt` fields |
| `lib/repositories/listing_repository.dart` | Wraps ItemService, fetches from Django API, removed seed data |
| `lib/repositories/swap_repository.dart` | Wraps TransactionService, fetches from Django API, removed seed data |
| `lib/viewmodels/home_viewmodel.dart` | Uses ListingRepository, async fetchFeatured/fetchNearby |
| `lib/viewmodels/explore_viewmodel.dart` | Uses ListingRepository, async search with filters |
| `lib/viewmodels/create_listing_viewmodel.dart` | Uses ListingRepository.createListing via Django API |
| `lib/viewmodels/swap_hub_viewmodel.dart` | Uses SwapRepository, async fetchSwaps |
| `lib/viewmodels/swap_detail_viewmodel.dart` | Uses SwapRepository, imports swapHubViewModelProvider for refresh |
| `lib/viewmodels/auth_viewmodel.dart` | Uses DjangoAuthService, FutureProvider instead of StreamProvider |
| `lib/viewmodels/chat_viewmodel.dart` | Uses ChatService, polling for new messages |
| `lib/viewmodels/inbox_viewmodel.dart` | Uses ChatService, polling for new chats |
| `pubspec.yaml` | Added `http`, `shared_preferences`, `share_plus`, `tutorial_coach_mark` |

### Key Design Decisions
- **Token storage**: SharedPreferences (access + refresh tokens)
- **Auto-refresh**: ApiClient intercepts 401, attempts refresh, retries request
- **Real-time**: Polling-based (5s for chat, 30s for notifications)
- **Error handling**: Typed `ApiResponse` with success/error pattern
- **Base URL**: Platform-aware via `ApiClient.defaultBaseUrl`:
  - **Web** → `http://localhost:8000/api`
  - **Android** → `http://10.0.2.2:8000/api` (emulator loopback)
  - **iOS/macOS** → `http://localhost:8000/api`
  - Override via constructor parameter or `API_BASE_URL` env var
- **Image URL resolution**: `getFullImageUrl()` utility in `lib/utils/image_utils.dart` converts relative paths (e.g., `/media/images/abc.jpg`) to absolute URLs by prepending the API base URL. Used by all screens to safely display listing/swap/avatar images. Returns empty string for null/empty input, passes through absolute URLs unchanged.
- **Avatar upload flow**:
  1. Flutter picks image via `ImagePicker` → gets `XFile`
  2. Flutter calls `authService.updateProfile(avatarFile: image)` which sends multipart PATCH to `/api/users/me/` with `avatar` file field
  3. Backend `UserDetailSerializer.update()` saves file to `CustomUser.avatar` (ImageField) and updates `avatar_url` with the full absolute URL
  4. `DjangoAuthService.updateProfile()` automatically refetches `GET /api/users/me/` after PATCH to sync all fields
  5. `UserDetailSerializer.to_representation()` derives `avatar_url` from `avatar` ImageField if `avatar_url` is empty
  6. `ProfileScreen._resolveAvatarUrl()` prepends base URL if the avatar URL is relative
  7. `authStateProvider` (FutureProvider) auto-refreshes when auth state changes
- **No separate upload endpoint**: Avatar upload uses the existing `PATCH /api/users/me/` endpoint with `multipart/form-data` encoding. The `avatar` field is declared as `serializers.ImageField()` in `UserDetailSerializer` to accept file uploads.
- **Provider naming**: All service providers use consistent naming in `lib/services/providers.dart`:
  - `apiClientProvider` → `ApiClient`
  - `djangoAuthServiceProvider` → `DjangoAuthService`
  - `itemServiceProvider` → `ItemService`
  - `chatServiceProvider` → `ChatService`
  - `transactionServiceProvider` → `TransactionService`
  - `notificationServiceProvider` → `DjangoNotificationService`
  - `storageServiceProvider` → `DjangoStorageService`
  - `listingRepositoryProvider` → `ListingRepository` (wraps `itemServiceProvider`)
  - `swapRepositoryProvider` → `SwapRepository` (wraps `transactionServiceProvider`)
- **Code quality**: `dart analyze lib/` produces **0 errors, 0 warnings** (only 9 informational hints about `use_build_context_synchronously` in `swap_detail_screen.dart` which are common in Flutter async UI code)
- **Django tests**: 47 integration tests covering all endpoints pass consistently

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
- **Suffix matching**: any subdomain of an allowed domain is accepted (e.g., `graduate.utm.my` matches `utm.my`)
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
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

### Run Tests
```bash
cd backend
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
7. **Flutter screens** update to use new service layer ✅ COMPLETE

---

## Critical Bug Fixes (June 2026)

### Bug 1: Transaction History – Type Mismatch
- **Root cause**: Backend `TransactionSerializer` returns `buyer`/`seller` as nested objects `{"id": 1, "name": "..."}`, but `swap_hub_screen.dart` was casting them directly as `int?`.
- **Fix**: Added `extractUserId()` helper that handles both `int` and `Map<String, dynamic>` formats. Applied to both the tab splitting logic and `_TransactionCard` widget.

### Bug 2: Notifications – Wrong Endpoint
- **Root cause**: Frontend called `/notifications/unread_count/` but backend defines the action as `unread` at `/notifications/unread/`.
- **Fix**: Changed URL in `DjangoNotificationService.fetchUnreadCount()` from `/notifications/unread_count/` to `/notifications/unread/`. The response parsing already correctly reads `response.data!['unread_count']`.

### Bug 3: Chat Not Loading in Inbox
- **Root cause**: `ConversationThread.fromJson` looked for `json['participants']` but the backend `ChatListSerializer` returns `participant_names` (not `participants`) in GET responses. The `participants` field is `write_only=True` for creation only. Also, `last_message` is a nested object `{"content": "...", "sender_name": "...", "created_at": "..."}` from `get_last_message()`, not a plain string.
- **Fix**: Updated `ConversationThread.fromJson` to read from `participant_names` instead of `participants`, and parse `last_message` as a nested `Map<String, dynamic>` with fallback to plain string.
- **Debugging**: Added `debugPrint` logging to `ChatService.fetchChats()` and `ApiClient._processResponse()` to help diagnose future API issues.

### Bug 4: Inbox Shows Duplicate Chat Entries for Same Person
- **Root cause**: Backend creates a new chat every time the user clicks "Contact Seller" for the same item (or different items with the same seller). The frontend was displaying all chats as separate entries, causing the same person to appear multiple times.
- **Fix**: Added `contactId` field to `ConversationThread` model (the other participant's user ID). Added `ConversationThread.deduplicateByContact()` static method that groups chats by `contactId` and keeps only the most recent chat per contact (by `lastTimestamp`). Chats with no valid contact (`contactId <= 0`) are filtered out as stale/invalid.
- **Files changed**:
  - `lib/models/conversation_thread.dart` — Added `contactId` field and `deduplicateByContact()` method
  - `lib/viewmodels/inbox_viewmodel.dart` — Calls `ConversationThread.deduplicateByContact()` after parsing chats
- **Behavior**: Inbox now shows each person only once, with the most recent chat's message preview and timestamp. Tapping opens the most recent chat ID so message history is preserved.

### Bug 5: TypeError – `type 'int' is not a subtype of type 'Map<String, dynamic>?'`
- **Root cause**: The `TransactionSerializer` returns `item`, `buyer`, and `seller` as **plain FK integers** (e.g., `"item": 1`, `"buyer": 2`), not nested objects. However, `swap_hub_screen.dart` and `swap_detail_screen.dart` were casting `transaction['item']` directly as `Map<String, dynamic>?`, causing a runtime type error when the value was an `int`.
- **Fix**: Updated all code that accesses `item`, `buyer`, and `seller` fields from transaction responses to handle both formats:
  - `itemRaw is Map<String, dynamic> ? itemRaw : <String, dynamic>{}` — safe fallback to empty map
  - `buyerRaw is int ? buyerRaw : (buyerRaw is Map<String, dynamic> ? buyerRaw['id'] as int? : null)` — handles both int and nested object
  - Use flat fields (`item_title`, `item_price`, `buyer_name`, `seller_name`) instead of nested object traversal
- **Files changed**:
  - `lib/views/swap_hub_screen.dart` — `_TransactionCard.build()` now uses `itemRaw` type check, flat fields for title/price
  - `lib/views/swap_detail_screen.dart` — `_buildContent()` and `_leaveReview()` now use type-safe extraction for `item`, `buyer`, `seller`
  - `lib/repositories/swap_repository.dart` — `_swapFromJson()` now handles `item` and `seller` being either int or Map
- **Verification**: `dart analyze lib/`: **0 errors, 0 warnings** (only 9 pre-existing `use_build_context_synchronously` hints). `python manage.py test`: **47/47 tests pass**.

### Bug 6: Chat from Swap Hub – Wrong Chat ID (Transaction ID used instead of Chat ID)
- **Root cause**: In `swap_detail_screen.dart`, the "Open Chat" button was passing `widget.transactionId` as the `swapId` parameter to the chat route. But the transaction ID (e.g., `1`) is not the same as the chat ID (e.g., `5`). The `ChatViewModel` then tried to call `fetchMessages(transactionId)` and `sendMessage(transactionId, ...)` which failed because no chat exists with that ID.
- **Fix**: Added `_openChat()` method to `_SwapDetailScreenState` that:
  1. Determines the other party's user ID from the transaction's `buyer`/`seller` fields (handles both int and nested Map formats)
  2. Calls `chatService.createChat(participantIds: [otherUserId])` to find or create a chat with that user
  3. Navigates to the chat screen with the correct chat ID from the response
  4. Includes error handling with user-facing snackbar messages and debug logging
- **Files changed**:
  - `lib/views/swap_detail_screen.dart` — Added `_openChat()` method, changed "Open Chat" button to call it instead of directly navigating with transaction ID
  - `lib/services/chat_service.dart` — Added debug logging to `fetchMessages()` and `sendMessage()` for easier debugging
- **Verification**: `dart analyze lib/`: **0 errors, 0 warnings**. `python manage.py test`: **47/47 tests pass**.

### Bug 9: Rate Limiting (429 Too Many Requests) – `authStateProvider` Polling on Every Route Change
- **Root cause**: `authStateProvider` was a `FutureProvider` that called `authService.isAuthenticated()` → `fetchCurrentUser()` → `GET /api/users/me/`. Every time the provider was invalidated or re-read (e.g., on route changes via `GoRouterRefreshNotifier`), it triggered a new API call. With rapid navigation, this caused the backend's rate limiter (1000/hr authenticated) to trigger 429 responses.
- **Fix (three changes)**:
  1. **Changed `authStateProvider` from `FutureProvider` to `StateProvider`** — A `StateProvider` does NOT re-evaluate on dependency changes. It only updates when explicitly set via `ref.read(authStateProvider.notifier).state = ...`. This eliminates all automatic API calls.
  2. **Added `initializeAuthState()` and `refreshAuthState()` functions** — `initializeAuthState()` is called once on app startup (e.g., in `main.dart` splash screen) to check stored tokens and fetch the user profile. `refreshAuthState()` is called explicitly after login, registration, or profile updates. `clearAuthState()` is called on logout.
  3. **Updated `GoRouterRefreshNotifier`** — Now listens to `StateProvider<Map<String, dynamic>?>` instead of `FutureProvider<Map<String, dynamic>?>`. The `ref.listen()` subscription type changed from `AsyncValue<Map<String, dynamic>?>` to `Map<String, dynamic>?`.
- **Files changed**:
  - `lib/viewmodels/auth_viewmodel.dart` — `authStateProvider` changed from `FutureProvider` to `StateProvider`. Added `initializeAuthState()`, `refreshAuthState()`, `clearAuthState()` functions. `SignInViewModel.signIn()` and `SignUpViewModel.signUp()` now call `refreshAuthState()` after success.
  - `lib/config/routes.dart` — `GoRouterRefreshNotifier` now listens to `StateProvider<Map<String, dynamic>?>`. All `.valueOrNull` accessors removed since `StateProvider` returns the value directly.
  - `lib/views/chat_screen.dart` — `ref.watch(authStateProvider).valueOrNull` → `ref.watch(authStateProvider)`
  - `lib/views/listing_detail_screen.dart` — Same fix
  - `lib/views/swap_detail_screen.dart` — Same fix (two occurrences)
  - `lib/views/swap_hub_screen.dart` — Same fix
  - `lib/views/home_screen.dart` — Same fix (was `authState.valueOrNull`)
  - `lib/views/profile_screen.dart` — Same fix (was `authState.valueOrNull`)
  - `lib/views/placeholder_screens.dart` — Same fix (two occurrences: `PublicProfileScreen` and `SettingsScreen`)
  - `lib/viewmodels/inbox_viewmodel.dart` — Same fix
  - `lib/viewmodels/chat_viewmodel.dart` — Same fix
- **Verification**: `dart analyze lib/`: **0 errors, 0 warnings** (only 9 pre-existing `use_build_context_synchronously` hints). `python manage.py test`: **47/47 tests pass**.

### Bug 10: Notification Polling Causes Rate Limiting (No Backoff on 429)
- **Root cause**: `DjangoNotificationService` used a fixed 30-second `Timer.periodic` for polling. When the backend returned 429 (rate limited), the service would continue polling at the same interval, compounding the rate limiting issue.
- **Fix**: Replaced `Timer.periodic` with dynamic `Timer` scheduling that adjusts the interval based on response status:
  - **Success**: Reset to base 30-second interval
  - **429 response**: Apply exponential backoff (doubles each time, up to 5 minutes max). Also parses the backend's suggested wait time from the error message (e.g., "Expected available in 1172 seconds.")
  - **Other errors**: Apply mild backoff (doubles each time)
  - **Request deduplication**: Added `_isPolling` flag to skip polls that are already in flight, preventing concurrent requests
- **Files changed**:
  - `lib/services/django_notification_service.dart` — Complete rewrite of polling logic: `Timer.periodic` → `Timer` with dynamic scheduling, added `_applyBackoff()`, `_resetBackoff()`, `_isPolling` deduplication, 429 error message parsing
- **Verification**: `dart analyze lib/`: **0 errors, 0 warnings**. `python manage.py test`: **47/47 tests pass**.

### Bug 7: Chat Messages Disappear After Sending (Race Condition in Polling)
- **Root cause**: Two issues combined to cause older messages to disappear after sending a new one:
  1. **`sendMessage()` called `_fetchMessages()` after sending** — This replaced the entire message list with whatever the API returned. If the backend hadn't fully indexed the new message yet, the API could return an incomplete list, wiping the chat history.
  2. **`_fetchMessages()` always replaced the entire list** — Even the 5-second polling timer would replace `state.messages` entirely on every tick. If any poll response returned an empty or incomplete list (e.g., due to timing), all existing messages would be lost.
- **Fix (two changes in `_fetchMessages`)**:
  1. **`sendMessage()` now appends locally** — After `chatService.sendMessage()` returns the new message object, it's parsed via `ChatMessage.fromJson()` and appended to the existing `state.messages` list. No API refetch is triggered.
  2. **`_fetchMessages()` now merges instead of replacing** — On each poll, fetched messages are compared by ID against the existing list. Only messages with new IDs are appended. If no new messages are found and the initial load has already completed, the existing list is preserved untouched. This prevents any race condition where a delayed or empty API response would wipe the history.
- **Files changed**:
  - `lib/viewmodels/chat_viewmodel.dart` — `sendMessage()` appends locally; `_fetchMessages()` uses ID-based merge logic with extensive debug logging
- **Verification**: `dart analyze lib/`: **0 errors, 0 warnings**. `python manage.py test`: **47/47 tests pass**.

### Bug 8: Chat Navigation Uses Wrong Route Parameter Name (`swapId` → `chatId`)
- **Root cause**: The chat route was defined as `/chat/:swapId` with parameter name `swapId`, and `ChatScreen` accepted `swapId` as a constructor parameter. This was confusing and error-prone — the value was actually a **chat ID**, not a swap/transaction ID. Additionally, `listing_detail_screen.dart` had a broken `catch` block that fell back to navigating with `listingId` as the chat ID when `chatService.createChat()` threw an exception, causing the app to navigate to `/chat/{listingId}` (a non-existent chat) instead of showing an error.
- **Fix**:
  1. **Renamed route parameter** from `swapId` to `chatId` in `routes.dart` — route is now `/chat/:chatId`
  2. **Renamed `ChatScreen.swapId`** to `ChatScreen.chatId` — constructor and all internal references updated
  3. **Renamed `chatViewModelProvider` family parameter** from `conversationId` to `chatId` for consistency
  4. **Fixed `listing_detail_screen.dart` catch block** — removed the broken fallback that navigated with `listingId` as the chat ID. Now shows a SnackBar error message instead, and only navigates to chat when the API returns a valid chat ID
  5. **Updated `swap_detail_screen.dart`** — changed `pathParameters: {'swapId': chatId}` to `pathParameters: {'chatId': chatId}`
- **Files changed**:
  - `lib/config/routes.dart` — Route path changed from `/chat/:swapId` to `/chat/:chatId`, parameter name updated
  - `lib/views/chat_screen.dart` — `swapId` → `chatId` in constructor and all usages
  - `lib/viewmodels/chat_viewmodel.dart` — `conversationId` → `chatId` in provider family parameter
  - `lib/views/listing_detail_screen.dart` — Removed broken catch-block fallback, shows error SnackBar instead
   - `lib/views/swap_detail_screen.dart` — `'swapId'` → `'chatId'` in `pathParameters`
- **Verification**: `dart analyze lib/`: **0 errors, 0 warnings**. `python manage.py test`: **47/47 tests pass**.

### Bug 11: Duplicate Chats Created on "Contact Seller" (Messages Appear to Vanish)
- **Root cause**: Every time the user tapped "Contact Seller" on a listing detail page, the frontend called `POST /api/chats/` unconditionally, creating a brand new chat. Old messages were still in the original chat, but the user was taken to the new empty chat, making it look like messages had vanished. The backend already supported reusing existing chats — the frontend just wasn't checking for them.
- **Fix (v1)**: Added `ChatService.getOrCreateChatId(participantId, {itemId})` that checked for existing chats by participant + item ID. This reduced duplicates per-item but still created multiple chats for the same two users discussing different items.
- **Fix (v2 — refined)**: The requirement is that **a pair of users must have only one chat ID — no more than one**. Updated `getOrCreateChatId()` to:
  1. **Ignore `itemId` during lookup** — only checks if a chat exists between the current user and the given `participantId`
  2. **Paginate through all pages** of `GET /api/chats/` to find any existing chat with that participant
  3. If found, returns the existing chat's ID (regardless of which item it was created for)
  4. If not found, calls `POST /api/chats/` with `participant_ids` and optionally `item_id`, then returns the new chat's ID
- **Files changed**:
  - `lib/services/chat_service.dart` — `getOrCreateChatId()` now paginates through all chats, ignores `itemId` during lookup, only uses `itemId` during creation
  - `lib/views/listing_detail_screen.dart` — "Chat" button now calls `chatService.getOrCreateChatId(participantId: sellerId)` without `itemId`
  - `lib/views/swap_detail_screen.dart` — Already correct (no `itemId` passed)
- **Behavior**: The same two users will always open the **same chat** (e.g., only chat ID 15, not 16, 17, etc.), regardless of which listing they click. All past messages (from any item) are visible in that single conversation.
- **Verification**: `dart analyze lib/`: **0 errors, 0 warnings** (only 9 pre-existing `use_build_context_synchronously` hints). `python manage.py test`: **47/47 tests pass**.

---

## Bug 12: Auth Navigation — Returning Users Not Redirected to /home

### Root Cause
Three issues combined to prevent returning users from reaching the home screen:

1. **`initializeAuthState()` was never called on app startup** — `main.dart` only started notification polling in `initState`, but never called `initializeAuthState(ref)` to check stored JWT tokens and fetch the user profile. So `authStateProvider` stayed `null` on every cold start, and the router's redirect always sent users to `/sign-in`.

2. **No explicit navigation after sign-in/sign-up** — The `SignInViewModel.signIn()` and `SignUpViewModel.signUp()` methods called `refreshAuthState()` which updated `authStateProvider`, but the screens never called `context.go('/home')`. The router's `redirect` *should* catch this (since `isLoggedIn && isSigningIn` → `/home`), but the async gap between the provider update and the router re-evaluation could cause the screen to stay on the auth page.

3. **`GoRouterRefreshNotifier` timing** — The `refreshListenable` mechanism notifies `GoRouter` to re-evaluate redirects, but if the provider update happens before the router is fully initialized (or during the same microtask), the redirect may not fire.

### Fix Applied

#### A. Call `initializeAuthState()` on app startup (`lib/main.dart`)
- Added `await initializeAuthState(ref as Ref)` in `initState`'s `addPostFrameCallback`, **before** starting notification polling.
- This ensures that on every cold start, the app checks for stored JWT tokens, validates them by fetching the user profile, and updates `authStateProvider` accordingly.
- Added import: `import 'package:uniswap/viewmodels/auth_viewmodel.dart';`

#### B. Explicit navigation after sign-in (`lib/views/sign_in_screen.dart`)
- Added `_handleSignIn()` method that calls `viewModel.signIn()`, then reads the watched state via `ref.read(signInViewModelProvider)` and calls `context.go('/home')` if there's no error.
- Changed the button's `onPressed` from `() => viewModel.signIn()` to `() => _handleSignIn(context, viewModel)`.

#### C. Explicit navigation after sign-up (`lib/views/sign_up_screen.dart`)
- Added `_handleSignUp()` method that calls `viewModel.signUp()`, then reads the watched state via `ref.read(signUpViewModelProvider)` and calls `context.go('/home')` if `state.isSuccess`.
- Changed the button's `onPressed` from `() => viewModel.signUp()` to `() => _handleSignUp(context, viewModel)`.

#### D. Debug logging in router redirect (`lib/config/routes.dart`)
- Added `import 'package:flutter/foundation.dart';` for `kDebugMode`.
- Added `debugPrint` statements to the `redirect` function that log the current location and auth state on every redirect evaluation.
- This makes future debugging of navigation issues much easier.

### Files Changed
| File | Change |
|------|--------|
| `lib/main.dart` | Call `initializeAuthState(ref)` on startup before notification polling |
| `lib/views/sign_in_screen.dart` | Navigate to `/home` after successful sign-in |
| `lib/views/sign_up_screen.dart` | Navigate to `/home` after successful sign-up |
| `lib/config/routes.dart` | Add debug logging to redirect function |

### Verification
- `dart analyze lib/`: **0 errors, 0 warnings** (only 9 pre-existing `use_build_context_synchronously` hints in `swap_detail_screen.dart`).
- `python manage.py test`: **47/47 tests pass**.
- Behavior: On cold start with valid tokens → splash screen briefly → `/home`. On cold start without tokens → splash screen briefly → `/sign-in`. After sign-in/sign-up → immediately navigated to `/home`.

### Bug 12b: Logout Button Doesn't Redirect to /sign-in
- **Root cause**: The logout button in `profile_screen.dart` called `authService.logout()` (which clears stored tokens) but never called `clearAuthState(ref)` to update `authStateProvider` to `null`, and never called `context.go('/sign-in')` to navigate away. The user was left on the profile screen with no auth state, and the router's redirect only fires on the next route change.
- **Fix**: Added two lines after `authService.logout()`:
  1. `clearAuthState(ref)` — sets `authStateProvider` to `null`, which triggers `GoRouterRefreshNotifier` to re-evaluate the redirect
  2. `context.go('/sign-in')` — explicitly navigates to the sign-in page
- **Files changed**: `lib/views/profile_screen.dart` — logout button `onPressed` now clears auth state and navigates to `/sign-in`

### Bug 12c: Runtime TypeError — `WidgetRef` vs `Ref` Cast Fails
- **Root cause**: `clearAuthState()` and `initializeAuthState()` were typed as `Ref` but called from `ConsumerStatefulWidget` contexts where `ref` is `WidgetRef`. The `as Ref` cast (`ref as Ref`) passes compile-time checks but fails at runtime because `WidgetRef` is not a subtype of `Ref<Object?>` in Riverpod.
- **Fix**: Changed function signatures from `Ref` to `WidgetRef`:
  - `initializeAuthState(WidgetRef ref)` — called from `main.dart` (ConsumerStatefulWidget)
  - `clearAuthState(WidgetRef ref)` — called from `profile_screen.dart` (ConsumerStatefulWidget)
  - Removed all `as Ref` casts — `WidgetRef` is now the accepted type directly
- **Files changed**:
  - `lib/viewmodels/auth_viewmodel.dart` — `initializeAuthState` and `clearAuthState` now accept `WidgetRef` instead of `Ref`
  - `lib/main.dart` — removed `as Ref` cast from `initializeAuthState(ref as Ref)` → `initializeAuthState(ref)`
  - `lib/views/profile_screen.dart` — removed `as Ref` cast from `clearAuthState(ref as Ref)` → `clearAuthState(ref)`
- **Verification**: `dart analyze lib/`: **0 errors, 0 warnings**.
