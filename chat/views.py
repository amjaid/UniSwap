"""
API views for the chat app.

Handles chat conversations and messaging between users.
"""

from django.db import models
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Chat, ChatMessage
from .serializers import (
    ChatDetailSerializer,
    ChatListSerializer,
    ChatMessageSerializer,
)


class ChatViewSet(viewsets.ModelViewSet):
    """
    API endpoint for chat conversations.

    Users can only see their own chats.
    Supports creating new chats with other users.
    """
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['updated_at']
    ordering = ['-updated_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return ChatListSerializer
        elif self.action == 'create':
            return ChatListSerializer  # Simplified for creation
        return ChatDetailSerializer

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        """Return chats where the current user is a participant."""
        return Chat.objects.filter(
            participants=self.request.user
        ).prefetch_related(
            'participants', 'messages'
        ).select_related('item')

    def perform_create(self, serializer):
        """Create a chat and add the current user as a participant."""
        chat = serializer.save()
        chat.participants.add(self.request.user)

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """
        Mark all messages in a chat as read for the current user.

        Only marks messages sent by other users as read.
        """
        chat = self.get_object()

        # Verify user is a participant
        if request.user not in chat.participants.all():
            return Response(
                {'error': 'You are not a participant in this chat.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Mark all unread messages from other users as read
        updated = ChatMessage.objects.filter(
            chat=chat,
            is_read=False,
        ).exclude(
            sender=request.user
        ).update(is_read=True)

        return Response({
            'marked_read': updated,
            'chat_id': chat.id,
        })

    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        """
        Send a message in a chat conversation.

        The sender is automatically set to the current user.
        """
        chat = self.get_object()

        # Verify user is a participant
        if request.user not in chat.participants.all():
            return Response(
                {'error': 'You are not a participant in this chat.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        content = request.data.get('content', '').strip()
        if not content:
            return Response(
                {'error': 'Message content cannot be empty.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        message = ChatMessage.objects.create(
            chat=chat,
            sender=request.user,
            content=content,
        )

        # Update chat's updated_at timestamp
        chat.save(update_fields=['updated_at'])

        return Response(
            ChatMessageSerializer(message).data,
            status=status.HTTP_201_CREATED,
        )


class ChatMessageViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing chat messages.

    Messages are read-only through this endpoint.
    Use the chat's send_message action to create messages.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = ChatMessageSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['chat', 'is_read', 'sender']
    ordering_fields = ['created_at']
    ordering = ['created_at']

    def get_queryset(self):
        """Return messages from chats where the user is a participant."""
        return ChatMessage.objects.filter(
            chat__participants=self.request.user
        ).select_related('sender', 'chat')
