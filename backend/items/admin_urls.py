"""
Admin URL configuration for the items app.

Provides admin-only endpoints for item management:
- List all items (paginated, filterable by status, searchable)
- Soft-delete items (set is_deleted=True)
"""

from django.urls import path

from .views import AdminItemDeleteView, AdminItemListView

urlpatterns = [
    path('', AdminItemListView.as_view(), name='admin-item-list'),
    path('<int:pk>/', AdminItemDeleteView.as_view(), name='admin-item-delete'),
]
