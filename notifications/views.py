"""
API views for the notifications app.

Handles fetching and managing in-app notifications.
"""

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Notification
from .serializers import (
    NotificationMarkReadSerializer,
    NotificationSerializer,
)


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for user notifications.

    Users can only see their own notifications.
    Provides actions for marking notifications as read.

    The Flutter client should poll /api/notifications/unread/
    periodically to check for new notifications.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer
    ordering = ['-created_at']

    def get_queryset(self):
        """Return only the current user's notifications."""
        return Notification.objects.filter(
            recipient=self.request.user
        )

    @action(detail=False, methods=['get'])
    def unread(self, request):
        """
        Get count and list of unread notifications.

        Returns both the count and the most recent unread notifications.
        Useful for badge display in the Flutter app.
        """
        unread_qs = self.get_queryset().filter(is_read=False)
        count = unread_qs.count()
        recent = unread_qs[:10]

        return Response({
            'unread_count': count,
            'notifications': NotificationSerializer(
                recent, many=True
            ).data,
        })

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """
        Mark a single notification as read.
        """
        notification = self.get_object()

        if notification.recipient != request.user:
            return Response(
                {'error': 'You can only mark your own notifications as read.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = NotificationMarkReadSerializer(
            notification,
            data={'is_read': True},
            partial=True,
        )
        if serializer.is_valid():
            serializer.save()
            return Response(NotificationSerializer(notification).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """
        Mark all of the current user's notifications as read.
        """
        updated = self.get_queryset().filter(
            is_read=False
        ).update(is_read=True)

        return Response({
            'marked_read': updated,
            'message': f'{updated} notification(s) marked as read.',
        })
