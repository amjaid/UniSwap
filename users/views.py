"""
API views for the users app.

Handles user registration, profile management, and settings.
"""

from django.contrib.auth import get_user_model
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import UserProfile, UserSettings
from .serializers import (
    UserDetailSerializer,
    UserListSerializer,
    UserProfileSerializer,
    UserRegistrationSerializer,
    UserSettingsSerializer,
)

User = get_user_model()


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing users.

    Provides:
    - List all users (paginated)
    - Retrieve a single user by ID
    - Get current user profile (/me/)
    - Update current user preferences (/me/preferences/)
    """
    queryset = User.objects.filter(is_active=True)
    search_fields = ['name', 'email', 'university_domain']
    ordering_fields = ['name', 'date_joined']

    def get_serializer_class(self):
        if self.action == 'list':
            return UserListSerializer
        return UserDetailSerializer

    def get_serializer_context(self):
        """Pass request context to serializers."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    @action(detail=False, methods=['get', 'patch'])
    def me(self, request):
        """
        Get or update the current user's profile.

        GET: Returns full profile with settings
        PATCH: Updates user fields (name, bio, avatar_url)
        """
        user = request.user

        if request.method == 'GET':
            serializer = UserDetailSerializer(
                user, context={'request': request}
            )
            return Response(serializer.data)

        # PATCH: partial update
        serializer = UserDetailSerializer(
            user,
            data=request.data,
            partial=True,
            context={'request': request},
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get', 'patch'], url_path='settings')
    def user_settings(self, request):
        """
        Get or update the current user's settings.

        GET: Returns notification_enabled, theme, language
        PATCH: Updates settings fields
        """
        user_settings, _ = UserSettings.objects.get_or_create(user=request.user)

        if request.method == 'GET':
            serializer = UserSettingsSerializer(user_settings)
            return Response(serializer.data)

        serializer = UserSettingsSerializer(
            user_settings,
            data=request.data,
            partial=True,
        )
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def ratings(self, request, pk=None):
        """
        Get average rating for a specific user.

        Returns the computed average rating from all reviews received.
        """
        try:
            profile = UserProfile.objects.get(user_id=pk)
            return Response({
                'user_id': pk,
                'rating_avg': float(profile.rating_avg),
                'total_transactions': profile.total_transactions,
            })
        except UserProfile.DoesNotExist:
            return Response(
                {'error': 'User profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )


class RegistrationViewSet(viewsets.GenericViewSet):
    """
    API endpoint for user registration.

    POST /api/auth/register/ - Create a new user account.
    Validates university email domain and password strength.
    """
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

    def create(self, request):
        """Register a new user."""
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(
                UserDetailSerializer(
                    user, context={'request': request}
                ).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
