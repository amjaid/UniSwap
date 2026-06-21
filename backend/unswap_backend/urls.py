"""
Main URL configuration for unswap_backend.

Maps all API endpoints under /api/ and includes JWT auth endpoints,
admin site, and DRF browsable API.
"""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)

from .views import AdminDashboardStatsView, AdminStatsView

# API URL prefix
API_PREFIX = 'api/'

urlpatterns = [
    # Django admin
    path('admin/', admin.site.urls),

    # JWT Authentication endpoints
    path(
        f'{API_PREFIX}auth/token/',
        TokenObtainPairView.as_view(),
        name='token_obtain_pair',
    ),
    path(
        f'{API_PREFIX}auth/token/refresh/',
        TokenRefreshView.as_view(),
        name='token_refresh',
    ),
    path(
        f'{API_PREFIX}auth/token/verify/',
        TokenVerifyView.as_view(),
        name='token_verify',
    ),

    # Admin statistics dashboard (US-401) — legacy endpoint
    path(
        f'{API_PREFIX}admin/stats/',
        AdminStatsView.as_view(),
        name='admin-stats',
    ),

    # Admin management endpoints (is_staff only)
    path(
        f'{API_PREFIX}admin/stats/dashboard/',
        AdminDashboardStatsView.as_view(),
        name='admin-dashboard-stats',
    ),
    path(f'{API_PREFIX}admin/users/', include('users.admin_urls')),
    path(f'{API_PREFIX}admin/items/', include('items.admin_urls')),

    # App-specific API endpoints
    path(f'{API_PREFIX}', include('users.urls')),
    path(f'{API_PREFIX}', include('items.urls')),
    path(f'{API_PREFIX}', include('transactions.urls')),
    path(f'{API_PREFIX}', include('chat.urls')),
    path(f'{API_PREFIX}', include('notifications.urls')),

    # DRF browsable API auth
    path('api-auth/', include('rest_framework.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT,
    )
