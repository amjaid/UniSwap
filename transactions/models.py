"""
Transaction and Review models for UniSwap.

Tracks the lifecycle of a purchase/sale between two users,
and the reviews they leave for each other after completion.
"""

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils.translation import gettext_lazy as _


class Transaction(models.Model):
    """
    Represents a transaction between a buyer and seller for an item.

    Tracks the entire lifecycle from initial offer to completion or cancellation.
    """
    class Status(models.TextChoices):
        PENDING = 'pending', _('Pending')
        COMPLETED = 'completed', _('Completed')
        CANCELLED = 'cancelled', _('Cancelled')

    buyer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='purchases',
        verbose_name=_('buyer'),
    )
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sales',
        verbose_name=_('seller'),
    )
    item = models.ForeignKey(
        'items.Item',
        on_delete=models.CASCADE,
        related_name='transactions',
        verbose_name=_('item'),
    )
    status = models.CharField(
        _('status'),
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        help_text=_('Current transaction status'),
    )
    transaction_date = models.DateTimeField(
        _('transaction date'),
        auto_now_add=True,
        help_text=_('When the transaction was initiated'),
    )
    completion_date = models.DateTimeField(
        _('completion date'),
        null=True,
        blank=True,
        help_text=_('When the transaction was completed or cancelled'),
    )

    class Meta:
        verbose_name = _('transaction')
        verbose_name_plural = _('transactions')
        ordering = ['-transaction_date']
        indexes = [
            models.Index(fields=['buyer']),
            models.Index(fields=['seller']),
            models.Index(fields=['status']),
            models.Index(fields=['-transaction_date']),
        ]

    def __str__(self):
        return f'{self.buyer.email} -> {self.item.title} ({self.status})'


class Review(models.Model):
    """
    A rating and review left by a user for another user after a transaction.

    Reviews help build trust within the university community.
    The transaction association is optional to allow reviews outside
    of formal transactions (e.g., meetup feedback).
    """
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reviews_given',
        verbose_name=_('reviewer'),
    )
    reviewee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reviews_received',
        verbose_name=_('reviewee'),
    )
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviews',
        verbose_name=_('transaction'),
    )
    rating = models.IntegerField(
        _('rating'),
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text=_('Rating from 1 (worst) to 5 (best)'),
    )
    comment = models.TextField(
        _('comment'),
        max_length=1000,
        blank=True,
        help_text=_('Optional written review'),
    )
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)

    class Meta:
        verbose_name = _('review')
        verbose_name_plural = _('reviews')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['reviewer']),
            models.Index(fields=['reviewee']),
            models.Index(fields=['-created_at']),
        ]

    def __str__(self):
        return f'{self.reviewer.email} -> {self.reviewee.email}: {self.rating}/5'
