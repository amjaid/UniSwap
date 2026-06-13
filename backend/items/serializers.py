"""
Serializers for the items app.

Handles item listing CRUD, wishlist management, and category data.
All image URLs are converted to absolute URLs using the request context
so that Flutter clients can load them directly with NetworkImage.
"""

from rest_framework import serializers

from .models import Category, Item, WishlistItem


def _build_absolute_url(request, path):
    """
    Convert a relative path (e.g. '/media/images/abc.jpg') to an absolute URL
    using the current request. Returns the path unchanged if it's already
    absolute or if no request is available.
    """
    if not path or path.startswith('http://') or path.startswith('https://'):
        return path
    if request:
        return request.build_absolute_uri(path)
    return path


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for product categories."""

    class Meta:
        model = Category
        fields = ['id', 'name', 'slug']


class ItemListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for item list views.

    Includes seller name and first image only for performance.
    All image URLs are resolved to absolute URLs.
    """
    seller_name = serializers.CharField(source='seller.name', read_only=True)
    seller_id = serializers.IntegerField(source='seller.id', read_only=True)
    seller_avatar_url = serializers.SerializerMethodField()
    category_name = serializers.CharField(
        source='category.name', read_only=True, default=None
    )
    first_image = serializers.SerializerMethodField()

    class Meta:
        model = Item
        fields = [
            'id', 'title', 'price', 'condition', 'status',
            'category_name', 'first_image',
            'seller_id', 'seller_name', 'seller_avatar_url',
            'created_at',
        ]

    def get_seller_avatar_url(self, obj):
        """Return absolute URL for the seller's avatar."""
        request = self.context.get('request')
        return _build_absolute_url(request, obj.seller.avatar_url)

    def get_first_image(self, obj):
        """Return the first image URL (absolute) from the images array, if any."""
        if obj.images and len(obj.images) > 0:
            request = self.context.get('request')
            return _build_absolute_url(request, obj.images[0])
        return None


class ItemDetailSerializer(serializers.ModelSerializer):
    """
    Full serializer for item detail views.

    Includes all images and complete seller information.
    All image URLs are resolved to absolute URLs.
    """
    seller_name = serializers.CharField(source='seller.name', read_only=True)
    seller_id = serializers.IntegerField(source='seller.id', read_only=True)
    seller_avatar_url = serializers.SerializerMethodField()
    seller_rating = serializers.DecimalField(
        source='seller.profile.rating_avg',
        max_digits=3, decimal_places=2, read_only=True, default=0.00,
    )
    category_name = serializers.CharField(
        source='category.name', read_only=True, default=None
    )
    images = serializers.SerializerMethodField()
    is_wishlisted = serializers.SerializerMethodField()

    class Meta:
        model = Item
        fields = [
            'id', 'title', 'description', 'price', 'condition',
            'category', 'category_name', 'images', 'status',
            'seller_id', 'seller_name', 'seller_avatar_url', 'seller_rating',
            'is_wishlisted',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'seller', 'status', 'created_at', 'updated_at',
        ]

    def get_seller_avatar_url(self, obj):
        """Return absolute URL for the seller's avatar."""
        request = self.context.get('request')
        return _build_absolute_url(request, obj.seller.avatar_url)

    def get_images(self, obj):
        """Return all image URLs as absolute URLs."""
        request = self.context.get('request')
        if not obj.images:
            return []
        return [_build_absolute_url(request, img) for img in obj.images]

    def get_is_wishlisted(self, obj):
        """Check if the current user has this item in their wishlist."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return WishlistItem.objects.filter(
                user=request.user, item=obj
            ).exists()
        return False


class ItemCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating and updating item listings.

    Automatically sets the seller to the current authenticated user.
    Includes seller info and id in the response so the Flutter client
    can parse the created item immediately.
    All image URLs are resolved to absolute URLs.
    """
    seller_id = serializers.IntegerField(source='seller.id', read_only=True)
    seller_name = serializers.CharField(source='seller.name', read_only=True)
    seller_avatar_url = serializers.SerializerMethodField()
    category_name = serializers.CharField(
        source='category.name', read_only=True, default=None
    )
    images = serializers.SerializerMethodField()

    class Meta:
        model = Item
        fields = [
            'id', 'title', 'description', 'price', 'condition',
            'category', 'category_name', 'images',
            'seller_id', 'seller_name', 'seller_avatar_url',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'seller_id', 'seller_name', 'seller_avatar_url',
            'category_name', 'created_at', 'updated_at',
        ]

    def get_seller_avatar_url(self, obj):
        """Return absolute URL for the seller's avatar."""
        request = self.context.get('request')
        return _build_absolute_url(request, obj.seller.avatar_url)

    def get_images(self, obj):
        """Return all image URLs as absolute URLs."""
        request = self.context.get('request')
        if not obj.images:
            return []
        return [_build_absolute_url(request, img) for img in obj.images]

    def create(self, validated_data):
        """Set the seller to the current user."""
        request = self.context.get('request')
        validated_data['seller'] = request.user
        return super().create(validated_data)


class WishlistItemSerializer(serializers.ModelSerializer):
    """Serializer for wishlist items."""

    item_detail = ItemListSerializer(source='item', read_only=True)

    class Meta:
        model = WishlistItem
        fields = ['id', 'item', 'item_detail', 'added_at']
        read_only_fields = ['id', 'added_at']

    def validate(self, attrs):
        """Prevent duplicate wishlist entries."""
        request = self.context.get('request')
        item = attrs.get('item')
        if item and WishlistItem.objects.filter(
            user=request.user, item=item
        ).exists():
            raise serializers.ValidationError(
                'This item is already in your wishlist.'
            )
        return attrs

    def create(self, validated_data):
        """Set the user to the current authenticated user."""
        request = self.context.get('request')
        validated_data['user'] = request.user
        return super().create(validated_data)
