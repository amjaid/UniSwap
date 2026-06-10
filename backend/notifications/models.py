"""
Notification model for UniSwap.

Handles in-app notifications for various events like new messages,
offer updates, and transaction status changes.
"""

from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


class Notification(models.Model):
    """
    An in-app notification for a user.

    Notifications are created automatically by signal handlers when
    relevant events occur (new message, transaction update, etc.).
    The Flutter client polls for unread notifications periodically.
    """
    class Type(models.TextChoices):
        NEW_MESSAGE = 'new_message', _('New Message')
        OFFER_UPDATE = 'offer_update', _('Offer Update')
        TRANSACTION_UPDATE = 'transaction_update', _('Transaction Update')

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name=_('recipient'),
    )
    type = models.CharField(
        _('type'),
        max_length=30,
        choices=Type.choices,
        help_text=_('Type of notification event'),
    )
    content = models.TextField(
        _('content'),
        max_length=500,
        help_text=_('Notification message body'),
    )
    is_read = models.BooleanField(
        _('is read'),
        default=False,
        help_text=_('Whether the user has seen this notification'),
    )
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)

    class Meta:
        verbose_name = _('notification')
        verbose_name_plural = _('notifications')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient', 'is_read']),
            models.Index(fields=['-created_at']),
        ]

    def __str__(self):
        return f'{self.recipient.email}: {self.get_type_display()} - {self.content[:50]}'
