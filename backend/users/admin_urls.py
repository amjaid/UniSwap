"""
Admin URL configuration for the users app.

Provides admin-only endpoints for user management:
- List all users (paginated, searchable)
- Soft-delete users (set is_active=False)
"""

from django.urls import path

from .views import AdminUserDeleteView, AdminUserListView

urlpatterns = [
    path('', AdminUserListView.as_view(), name='admin-user-list'),
    path('<int:pk>/', AdminUserDeleteView.as_view(), name='admin-user-delete'),
]
