"""
Serializers for the items app.

Handles item listing CRUD, wishlist management, and category data.
"""

from rest_framework import serializers

from .models import Category, Item, WishlistItem


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for product categories."""

    class Meta:
        model = Category
        fields = ['id', 'name', 'slug']


class ItemListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for item list views.

    Includes seller name and first image only for performance.
    """
    seller_name = serializers.CharField(source='seller.name', read_only=True)
    seller_id = serializers.IntegerField(source='seller.id', read_only=True)
    seller_avatar_url = serializers.URLField(
        source='seller.avatar_url', read_only=True
    )
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

    def get_first_image(self, obj):
        """Return the first image URL from the images array, if any."""
        if obj.images and len(obj.images) > 0:
            return obj.images[0]
        return None


class ItemDetailSerializer(serializers.ModelSerializer):
    """
    Full serializer for item detail views.

    Includes all images and complete seller information.
    """
    seller_name = serializers.CharField(source='seller.name', read_only=True)
    seller_id = serializers.IntegerField(source='seller.id', read_only=True)
    seller_avatar_url = serializers.URLField(
        source='seller.avatar_url', read_only=True
    )
    seller_rating = serializers.DecimalField(
        source='seller.profile.rating_avg',
        max_digits=3, decimal_places=2, read_only=True, default=0.00,
    )
    category_name = serializers.CharField(
        source='category.name', read_only=True, default=None
    )
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
    """

    class Meta:
        model = Item
        fields = [
            'title', 'description', 'price', 'condition',
            'category', 'images',
        ]

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
