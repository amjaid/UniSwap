"""
Serializers for the transactions app.

Handles transaction lifecycle and user reviews.
"""

from django.db.models import Avg
from rest_framework import serializers

from .models import Review, Transaction


class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for transaction records."""

    buyer_name = serializers.CharField(source='buyer.name', read_only=True)
    buyer_email = serializers.EmailField(source='buyer.email', read_only=True)
    seller_name = serializers.CharField(source='seller.name', read_only=True)
    seller_email = serializers.EmailField(source='seller.email', read_only=True)
    item_title = serializers.CharField(source='item.title', read_only=True)
    item_price = serializers.DecimalField(
        source='item.price', max_digits=10, decimal_places=2, read_only=True
    )

    class Meta:
        model = Transaction
        fields = [
            'id', 'buyer', 'buyer_name', 'buyer_email',
            'seller', 'seller_name', 'seller_email',
            'item', 'item_title', 'item_price',
            'status', 'transaction_date', 'completion_date',
        ]
        read_only_fields = [
            'id', 'transaction_date', 'completion_date',
        ]


class TransactionCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating a new transaction.

    Automatically sets the buyer to the current user
    and validates that the item is available.
    """

    class Meta:
        model = Transaction
        fields = ['id', 'item', 'buyer', 'seller', 'status', 'transaction_date']
        read_only_fields = ['id', 'buyer', 'seller', 'status', 'transaction_date']

    def validate_item(self, value):
        """Ensure the item is available for purchase."""
        if value.status != 'available':
            raise serializers.ValidationError(
                'This item is not available for purchase.'
            )
        return value

    def create(self, validated_data):
        """Set buyer and seller, then mark item as pending."""
        request = self.context.get('request')
        item = validated_data['item']
        validated_data['buyer'] = request.user
        validated_data['seller'] = item.seller

        # Mark item as pending
        item.status = 'pending'
        item.save(update_fields=['status'])

        return super().create(validated_data)


class ReviewSerializer(serializers.ModelSerializer):
    """Serializer for user reviews."""

    reviewer_name = serializers.CharField(
        source='reviewer.name', read_only=True
    )
    reviewee_name = serializers.CharField(
        source='reviewee.name', read_only=True
    )

    class Meta:
        model = Review
        fields = [
            'id', 'reviewer', 'reviewer_name',
            'reviewee', 'reviewee_name',
            'transaction', 'rating', 'comment', 'created_at',
        ]
        read_only_fields = ['id', 'reviewer', 'created_at']

    def validate(self, attrs):
        """Prevent self-review and duplicate reviews."""
        request = self.context.get('request')
        reviewee = attrs.get('reviewee')

        if request.user == reviewee:
            raise serializers.ValidationError(
                'You cannot review yourself.'
            )

        # Check for existing review from this reviewer to this reviewee
        if Review.objects.filter(
            reviewer=request.user, reviewee=reviewee
        ).exists():
            raise serializers.ValidationError(
                'You have already reviewed this user.'
            )

        return attrs

    def create(self, validated_data):
        """Set the reviewer to the current user."""
        request = self.context.get('request')
        validated_data['reviewer'] = request.user
        review = super().create(validated_data)

        # Update the reviewee's average rating
        avg_rating = Review.objects.filter(
            reviewee=review.reviewee
        ).aggregate(Avg('rating'))['rating__avg']

        profile = review.reviewee.profile
        profile.rating_avg = round(avg_rating, 2) if avg_rating else 0.00
        profile.save(update_fields=['rating_avg'])

        return review
