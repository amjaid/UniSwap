"""
Serializers for the notifications app.

Handles in-app notification display and read status updates.
"""

from rest_framework import serializers

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for in-app notifications."""

    type_display = serializers.CharField(
        source='get_type_display', read_only=True
    )

    class Meta:
        model = Notification
        fields = [
            'id', 'recipient', 'type', 'type_display',
            'content', 'is_read', 'created_at',
        ]
        read_only_fields = [
            'id', 'recipient', 'type', 'type_display',
            'content', 'created_at',
        ]


class NotificationMarkReadSerializer(serializers.ModelSerializer):
    """Serializer for marking a notification as read."""

    class Meta:
        model = Notification
        fields = ['is_read']

    def update(self, instance, validated_data):
        """Mark notification as read."""
        instance.is_read = validated_data.get('is_read', True)
        instance.save(update_fields=['is_read'])
        return instance
