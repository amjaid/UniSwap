"""
URL configuration for the notifications app.

Maps notification API endpoints.
"""

from rest_framework.routers import DefaultRouter

from .views import NotificationViewSet

router = DefaultRouter()
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = []

urlpatterns += router.urls
