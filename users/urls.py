"""
URL configuration for the users app.

Maps user-related API endpoints.
"""

from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import RegistrationViewSet, UserViewSet

# Router for UserViewSet (generates /users/, /users/{id}/, /users/me/, etc.)
router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')

urlpatterns = [
    # Registration endpoint (no auth required)
    path(
        'auth/register/',
        RegistrationViewSet.as_view({'post': 'create'}),
        name='user-register',
    ),
]

# Append router-generated URLs
urlpatterns += router.urls
