"""
Chat and ChatMessage models for UniSwap.

Provides real-time messaging between users for negotiating
transactions and arranging meetups.
"""

from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


class Chat(models.Model):
    """
    A conversation thread between two or more users.

    Optionally linked to an item for context (e.g., "I'm interested in your
    textbook"). Participants are stored as a many-to-many relationship.
    """
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='chats',
        verbose_name=_('participants'),
    )
    item = models.ForeignKey(
        'items.Item',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='chats',
        verbose_name=_('item'),
        help_text=_('Optional: the item this chat is about'),
    )
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)

    class Meta:
        verbose_name = _('chat')
        verbose_name_plural = _('chats')
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['-updated_at']),
        ]

    def __str__(self):
        participant_emails = ', '.join(
            user.email for user in self.participants.all()[:3]
        )
        item_title = self.item.title if self.item else 'General'
        return f'Chat about {item_title}: {participant_emails}'


class ChatMessage(models.Model):
    """
    An individual message within a chat conversation.

    Messages are ordered by creation timestamp and support read receipts.
    """
    chat = models.ForeignKey(
        Chat,
        on_delete=models.CASCADE,
        related_name='messages',
        verbose_name=_('chat'),
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_messages',
        verbose_name=_('sender'),
    )
    content = models.TextField(
        _('content'),
        max_length=5000,
        help_text=_('Message text content'),
    )
    is_read = models.BooleanField(
        _('is read'),
        default=False,
        help_text=_('Whether the message has been read by recipients'),
    )
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)

    class Meta:
        verbose_name = _('chat message')
        verbose_name_plural = _('chat messages')
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['chat', 'created_at']),
            models.Index(fields=['sender']),
            models.Index(fields=['is_read']),
        ]

    def __str__(self):
        return f'{self.sender.email}: {self.content[:50]}...'
