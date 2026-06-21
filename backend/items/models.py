"""
Item and WishlistItem models for UniSwap.

Represents listings that users can create, browse, and add to their wishlist.
"""

from django.conf import settings
from django.db import models
from django.utils.translation import gettext_lazy as _


class Category(models.Model):
    """
    Product category for organizing item listings.

    Categories help users filter and discover items by type.
    """
    name = models.CharField(
        _('name'),
        max_length=100,
        unique=True,
        help_text=_('Category name (e.g., Textbooks, Electronics)'),
    )
    slug = models.SlugField(
        _('slug'),
        max_length=100,
        unique=True,
        help_text=_('URL-friendly identifier (e.g., textbooks)'),
    )

    class Meta:
        verbose_name = _('category')
        verbose_name_plural = _('categories')
        ordering = ['name']

    def __str__(self):
        return self.name


class Item(models.Model):
    """
    A listing item posted by a user for sale or swap.

    Tracks the item's condition, price, status, and seller information.
    Supports multiple images via a JSON array of URLs.
    """
    class Condition(models.TextChoices):
        NEW = 'new', _('New')
        LIKE_NEW = 'like_new', _('Like New')
        GOOD = 'good', _('Good')
        FAIR = 'fair', _('Fair')

    class Status(models.TextChoices):
        AVAILABLE = 'available', _('Available')
        SOLD = 'sold', _('Sold')
        PENDING = 'pending', _('Pending')

    title = models.CharField(
        _('title'),
        max_length=200,
        help_text=_('Item title/name'),
    )
    description = models.TextField(
        _('description'),
        max_length=2000,
        blank=True,
        help_text=_('Detailed description of the item'),
    )
    price = models.DecimalField(
        _('price'),
        max_digits=10,
        decimal_places=2,
        help_text=_('Price in local currency'),
    )
    condition = models.CharField(
        _('condition'),
        max_length=20,
        choices=Condition.choices,
        default=Condition.GOOD,
        help_text=_('Physical condition of the item'),
    )
    category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='items',
        verbose_name=_('category'),
    )
    # Store image URLs as JSON array (supports multiple images)
    images = models.JSONField(
        _('images'),
        default=list,
        blank=True,
        help_text=_('Array of image URLs for this listing'),
    )
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name=_('seller'),
    )
    status = models.CharField(
        _('status'),
        max_length=20,
        choices=Status.choices,
        default=Status.AVAILABLE,
        help_text=_('Current listing status'),
    )
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)

    # Soft-delete fields for admin moderation
    is_deleted = models.BooleanField(
        _('is deleted'),
        default=False,
        help_text=_('Soft-delete flag for admin moderation'),
    )
    deleted_at = models.DateTimeField(
        _('deleted at'),
        null=True,
        blank=True,
        help_text=_('When this item was soft-deleted'),
    )
    deleted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='deleted_items',
        verbose_name=_('deleted by'),
        help_text=_('Admin who soft-deleted this item'),
    )

    class Meta:
        verbose_name = _('item')
        verbose_name_plural = _('items')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['condition']),
            models.Index(fields=['category']),
            models.Index(fields=['seller']),
            models.Index(fields=['-created_at']),
            models.Index(fields=['price']),
            models.Index(fields=['is_deleted']),
        ]

    def __str__(self):
        return self.title


class WishlistItem(models.Model):
    """
    A saved/favorited item in a user's wishlist.

    Users can add items to their wishlist to track items they're interested in.
    Each user-item pair is unique (no duplicate wishlist entries).
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='wishlist_items',
        verbose_name=_('user'),
    )
    item = models.ForeignKey(
        Item,
        on_delete=models.CASCADE,
        related_name='wishlisted_by',
        verbose_name=_('item'),
    )
    added_at = models.DateTimeField(_('added at'), auto_now_add=True)

    class Meta:
        verbose_name = _('wishlist item')
        verbose_name_plural = _('wishlist items')
        ordering = ['-added_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'item'],
                name='unique_user_wishlist_item',
            ),
        ]
        indexes = [
            models.Index(fields=['user', 'item']),
        ]

    def __str__(self):
        return f'{self.user.email} - {self.item.title}'
