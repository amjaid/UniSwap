"""
Serializers for the chat app.

Handles chat conversations and messages between users.
"""

from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import Chat, ChatMessage

User = get_user_model()


class ChatMessageSerializer(serializers.ModelSerializer):
    """Serializer for individual chat messages."""

    sender_name = serializers.CharField(source='sender.name', read_only=True)
    sender_email = serializers.EmailField(source='sender.email', read_only=True)

    class Meta:
        model = ChatMessage
        fields = [
            'id', 'chat', 'sender', 'sender_name', 'sender_email',
            'content', 'is_read', 'created_at',
        ]
        read_only_fields = ['id', 'sender', 'is_read', 'created_at']

    def create(self, validated_data):
        """Set the sender to the current user."""
        request = self.context.get('request')
        validated_data['sender'] = request.user
        return super().create(validated_data)


class ChatListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for chat list views.

    Includes last message preview and participant info.
    For creation, accepts a list of participant IDs (the current
    user is automatically added by perform_create in the view).
    """
    last_message = serializers.SerializerMethodField()
    participant_names = serializers.SerializerMethodField()
    item_title = serializers.CharField(
        source='item.title', read_only=True, default=None
    )
    unread_count = serializers.SerializerMethodField()
    participants = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=User.objects.all(),
        write_only=True,
        help_text='List of user IDs to add as participants (current user is added automatically)',
    )

    class Meta:
        model = Chat
        fields = [
            'id', 'participants', 'participant_names', 'item', 'item_title',
            'last_message', 'unread_count',
            'created_at', 'updated_at',
        ]

    def get_last_message(self, obj):
        """Return the most recent message preview."""
        last_msg = obj.messages.order_by('-created_at').first()
        if last_msg:
            return {
                'content': last_msg.content[:100],
                'sender_name': last_msg.sender.name,
                'created_at': last_msg.created_at,
            }
        return None

    def get_participant_names(self, obj):
        """Return names of all participants except the current user."""
        request = self.context.get('request')
        return [
            {'id': p.id, 'name': p.name, 'avatar_url': p.avatar_url}
            for p in obj.participants.all()
            if p != request.user
        ]

    def get_unread_count(self, obj):
        """Count unread messages for the current user."""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.messages.filter(
                is_read=False
            ).exclude(
                sender=request.user
            ).count()
        return 0


class ChatDetailSerializer(serializers.ModelSerializer):
    """Full serializer for chat detail with messages."""

    messages = ChatMessageSerializer(many=True, read_only=True)
    participant_details = serializers.SerializerMethodField()
    item_title = serializers.CharField(
        source='item.title', read_only=True, default=None
    )

    class Meta:
        model = Chat
        fields = [
            'id', 'participant_details', 'item', 'item_title',
            'messages', 'created_at', 'updated_at',
        ]

    def get_participant_details(self, obj):
        """Return details of all participants."""
        return [
            {
                'id': p.id,
                'name': p.name,
                'email': p.email,
                'avatar_url': p.avatar_url,
            }
            for p in obj.participants.all()
        ]
