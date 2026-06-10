"""
API views for the transactions app.

Handles transaction lifecycle and user reviews.
"""

from django.db import models
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Review, Transaction
from .serializers import (
    ReviewSerializer,
    TransactionCreateSerializer,
    TransactionSerializer,
)


class TransactionViewSet(viewsets.ModelViewSet):
    """
    API endpoint for transactions.

    Users can view their own transactions (as buyer or seller).
    Provides custom actions for status updates.

    Filters:
    - status (pending/completed/cancelled)
    - transaction_date range
    """
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = {
        'status': ['exact'],
        'transaction_date': ['gte', 'lte'],
    }
    ordering_fields = ['transaction_date', 'completion_date']
    ordering = ['-transaction_date']

    def get_serializer_class(self):
        if self.action == 'create':
            return TransactionCreateSerializer
        return TransactionSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        """Return transactions where the user is buyer or seller."""
        user = self.request.user
        return Transaction.objects.filter(
            models.Q(buyer=user) | models.Q(seller=user)
        ).select_related('buyer', 'seller', 'item')

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """
        Mark a transaction as completed.

        Only the seller can mark a transaction as completed.
        Updates the item status to 'sold'.
        """
        transaction = self.get_object()

        if transaction.seller != request.user:
            return Response(
                {'error': 'Only the seller can complete this transaction.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if transaction.status != 'pending':
            return Response(
                {'error': f'Cannot complete a transaction with status "{transaction.status}".'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        transaction.status = 'completed'
        transaction.completion_date = timezone.now()
        transaction.save(update_fields=['status', 'completion_date'])

        # Update item status to sold
        item = transaction.item
        item.status = 'sold'
        item.save(update_fields=['status'])

        # Update seller's transaction count
        seller_profile = transaction.seller.profile
        seller_profile.total_transactions += 1
        seller_profile.save(update_fields=['total_transactions'])

        return Response(
            TransactionSerializer(
                transaction, context={'request': request}
            ).data
        )

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """
        Cancel a transaction.

        Either the buyer or seller can cancel.
        Returns the item to 'available' status.
        """
        transaction = self.get_object()

        if request.user not in (transaction.buyer, transaction.seller):
            return Response(
                {'error': 'Only participants can cancel this transaction.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if transaction.status != 'pending':
            return Response(
                {'error': f'Cannot cancel a transaction with status "{transaction.status}".'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        transaction.status = 'cancelled'
        transaction.save(update_fields=['status'])

        # Return item to available
        item = transaction.item
        item.status = 'available'
        item.save(update_fields=['status'])

        return Response(
            TransactionSerializer(
                transaction, context={'request': request}
            ).data
        )


class ReviewViewSet(viewsets.ModelViewSet):
    """
    API endpoint for reviews.

    Users can create reviews for other users after transactions.
    Only the create action is available; updates/deletes are not allowed.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = ReviewSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['rating', 'reviewee']
    ordering_fields = ['created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        """Return reviews where the user is reviewer or reviewee."""
        user = self.request.user
        return Review.objects.filter(
            models.Q(reviewer=user) | models.Q(reviewee=user)
        ).select_related('reviewer', 'reviewee')

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        """Set the reviewer to the current user."""
        serializer.save(reviewer=self.request.user)

    def update(self, request, *args, **kwargs):
        """Prevent updating reviews."""
        return Response(
            {'error': 'Reviews cannot be updated.'},
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def partial_update(self, request, *args, **kwargs):
        """Prevent partial updating reviews."""
        return Response(
            {'error': 'Reviews cannot be updated.'},
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def destroy(self, request, *args, **kwargs):
        """Prevent deleting reviews."""
        return Response(
            {'error': 'Reviews cannot be deleted.'},
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )
