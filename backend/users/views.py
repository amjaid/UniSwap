"""
API views for the users app.

Handles user registration, profile management, settings,
and admin-only user management endpoints.
"""

from django.contrib.auth import get_user_model
from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.filters import SearchFilter
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
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


# ──────────────────────────────────────────────
# Admin Views (is_staff only)
# ──────────────────────────────────────────────

class AdminUserPagination(PageNumberPagination):
    """Pagination for admin user list — 20 users per page."""
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class AdminUserListView(generics.ListAPIView):
    """
    GET /api/admin/users/ — List all users (paginated, searchable).

    Admin-only. Returns all users including inactive ones.
    Supports search by email or name via ?search= query param.
    """
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserListSerializer
    permission_classes = [IsAdminUser]
    pagination_class = AdminUserPagination
    filter_backends = [SearchFilter]
    search_fields = ['email', 'name']


class AdminUserDeleteView(generics.DestroyAPIView):
    """
    DELETE /api/admin/users/{id}/ — Soft-delete a user.

    Admin-only. Sets is_active=False instead of hard-deleting.
    """
    queryset = User.objects.all()
    permission_classes = [IsAdminUser]

    def perform_destroy(self, instance):
        """Soft-delete: set is_active=False instead of deleting."""
        instance.is_active = False
        instance.save(update_fields=['is_active'])


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

    @action(detail=False, methods=['post'], url_path='upload_avatar')
    def upload_avatar(self, request):
        """
        Upload a profile picture for the current user.

        Accepts a multipart form with an 'avatar' file field.
        Saves the file to the user's avatar ImageField and returns the URL.
        """
        user = request.user

        if 'avatar' not in request.FILES:
            return Response(
                {'error': 'No image file provided. Use field name "avatar".'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        file = request.FILES['avatar']

        # Validate file type
        import os
        ext = os.path.splitext(file.name)[1].lower()
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
        if ext not in allowed_extensions:
            return Response(
                {'error': f'Unsupported file type "{ext}". Allowed: {", ".join(allowed_extensions)}'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Validate file size (10MB max)
        if file.size > 10 * 1024 * 1024:
            return Response(
                {'error': 'File too large. Maximum size is 10MB.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Save the file to the avatar ImageField
        user.avatar.save(file.name, file, save=True)

        # Build the full URL and also update avatar_url field
        avatar_url = request.build_absolute_uri(user.avatar.url)
        user.avatar_url = avatar_url
        user.save(update_fields=['avatar_url'])

        return Response({
            'avatar_url': avatar_url,
            'message': 'Avatar uploaded successfully.',
        })

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
