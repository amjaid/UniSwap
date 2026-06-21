"""
API views for the items app.

Handles item listing CRUD, wishlist management, category browsing,
and admin-only item management endpoints.
"""

from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import (
    AllowAny,
    IsAdminUser,
    IsAuthenticated,
    IsAuthenticatedOrReadOnly,
)
from rest_framework.response import Response

from .models import Category, Item, WishlistItem
from .serializers import (
    CategorySerializer,
    ItemCreateSerializer,
    ItemDetailSerializer,
    ItemListSerializer,
    WishlistItemSerializer,
)


# ──────────────────────────────────────────────
# Admin Views (is_staff only)
# ──────────────────────────────────────────────

class AdminItemPagination(PageNumberPagination):
    """Pagination for admin item list — 20 items per page."""
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class AdminItemListView(generics.ListAPIView):
    """
    GET /api/admin/items/ — List all items (paginated, filterable, searchable).

    Admin-only. Returns all items including soft-deleted ones.
    Supports filtering by status via ?status= query param.
    Supports search by title via ?search= query param.
    """
    queryset = Item.objects.all().order_by('-created_at')
    serializer_class = ItemListSerializer
    permission_classes = [IsAdminUser]
    pagination_class = AdminItemPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['status']
    search_fields = ['title']


class AdminItemDeleteView(generics.DestroyAPIView):
    """
    DELETE /api/admin/items/{id}/ — Soft-delete an item.

    Admin-only. Sets is_deleted=True, deleted_at=now, deleted_by=admin.
    """
    queryset = Item.objects.all()
    permission_classes = [IsAdminUser]

    def perform_destroy(self, instance):
        """Soft-delete: mark as deleted instead of hard-deleting."""
        instance.is_deleted = True
        instance.deleted_at = timezone.now()
        instance.deleted_by = self.request.user
        instance.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by'])


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing categories.

    Provides a list of all categories for filter dropdowns.
    """
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]
    pagination_class = None  # Categories are small, no pagination needed


class ItemViewSet(viewsets.ModelViewSet):
    """
    API endpoint for item listings.

    Provides full CRUD with search, filtering, and pagination.
    Supports custom actions for marking items as sold.

    Filters:
    - category (exact match)
    - condition (exact match)
    - status (exact match)
    - price_min, price_max (range filter)
    - search (title, description)
    - ordering (price, created_at)
    """
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    filterset_fields = {
        'category': ['exact'],
        'condition': ['exact'],
        'status': ['exact'],
        'price': ['gte', 'lte', 'exact'],
    }
    search_fields = ['title', 'description']
    ordering_fields = ['price', 'created_at', 'updated_at']
    ordering = ['-created_at']

    def get_serializer_class(self):
        """Return different serializers based on action."""
        if self.action == 'list':
            return ItemListSerializer
        elif self.action in ('create', 'update', 'partial_update'):
            return ItemCreateSerializer
        return ItemDetailSerializer

    def get_serializer_context(self):
        """Pass request context to serializers."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        """Return available items for unauthenticated users."""
        qs = Item.objects.select_related(
            'seller', 'category'
        ).prefetch_related('wishlisted_by')

        if not self.request.user.is_authenticated:
            # Only show available items to anonymous users
            qs = qs.filter(status='available')

        return qs

    def perform_create(self, serializer):
        """Set the seller to the current user."""
        serializer.save(seller=self.request.user)

    def update(self, request, *args, **kwargs):
        """Restrict updates to the item's seller only."""
        item = self.get_object()
        if item.seller != request.user:
            return Response(
                {'error': 'You do not have permission to edit this listing.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        """Restrict partial updates to the item's seller only."""
        item = self.get_object()
        if item.seller != request.user:
            return Response(
                {'error': 'You do not have permission to edit this listing.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        """Restrict deletion to the item's seller only."""
        item = self.get_object()
        if item.seller != request.user:
            return Response(
                {'error': 'You do not have permission to delete this listing.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)

    @action(detail=True, methods=['post'])
    def mark_sold(self, request, pk=None):
        """
        Mark an item as sold.

        Only the seller can mark their item as sold.
        Updates the item status to 'sold'.
        """
        item = self.get_object()

        # Verify the current user is the seller
        if item.seller != request.user:
            return Response(
                {'error': 'Only the seller can mark this item as sold.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if item.status == 'sold':
            return Response(
                {'error': 'This item is already marked as sold.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        item.status = 'sold'
        item.save(update_fields=['status'])

        return Response(
            ItemDetailSerializer(
                item, context={'request': request}
            ).data
        )

    @action(detail=True, methods=['post'], url_path='upload_image')
    def upload_image(self, request, pk=None):
        """
        Upload an image for an item listing.

        Accepts a multipart form with an 'image' file field.
        Saves the file to the item's image directory and appends
        the URL to the item's images JSON array.
        """
        from django.core.files.storage import default_storage
        from django.core.files.base import ContentFile
        import os
        import uuid

        item = self.get_object()

        # Only the seller can upload images
        if item.seller != request.user:
            return Response(
                {'error': 'Only the seller can upload images for this item.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if 'image' not in request.FILES:
            return Response(
                {'error': 'No image file provided. Use field name "image".'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        file = request.FILES['image']

        # Validate file type
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

        # Save file with a unique name
        unique_name = f'items/{item.id}/{uuid.uuid4().hex}{ext}'
        saved_path = default_storage.save(unique_name, ContentFile(file.read()))
        image_url = request.build_absolute_uri(
            default_storage.url(saved_path)
        )

        # Append to the item's images JSON array
        current_images = list(item.images) if item.images else []
        current_images.append(image_url)
        item.images = current_images
        item.save(update_fields=['images'])

        return Response({
            'message': 'Image uploaded successfully.',
            'image_url': image_url,
            'image_count': len(current_images),
        })

    @action(detail=True, methods=['post'])
    def mark_available(self, request, pk=None):
        """
        Re-list an item as available.

        Only the seller can re-list their item.
        """
        item = self.get_object()

        if item.seller != request.user:
            return Response(
                {'error': 'Only the seller can re-list this item.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        item.status = 'available'
        item.save(update_fields=['status'])

        return Response(
            ItemDetailSerializer(
                item, context={'request': request}
            ).data
        )


class WishlistItemViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing the current user's wishlist.

    Provides CRUD operations for wishlist items.
    Users can only see and manage their own wishlist.
    """
    serializer_class = WishlistItemSerializer

    def get_queryset(self):
        """Return only the current user's wishlist items."""
        return WishlistItem.objects.filter(
            user=self.request.user
        ).select_related('item', 'item__seller')

    def get_serializer_context(self):
        """Pass request context to serializers."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        """Set the user to the current user."""
        serializer.save(user=self.request.user)
