"""
Admin configuration for the items app.

Registers Category, Item, and WishlistItem with the Django admin.
"""

from django.contrib import admin

from .models import Category, Item, WishlistItem


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    """Admin for product categories."""
    list_display = ['name', 'slug']
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ['name']


@admin.register(Item)
class ItemAdmin(admin.ModelAdmin):
    """Admin for item listings."""
    list_display = [
        'title', 'price', 'condition', 'status', 'category',
        'seller', 'created_at',
    ]
    list_filter = ['status', 'condition', 'category', 'created_at']
    search_fields = ['title', 'description', 'seller__email', 'seller__name']
    date_hierarchy = 'created_at'
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at']

    fieldsets = (
        (None, {
            'fields': ('title', 'description', 'price'),
        }),
        ('Classification', {
            'fields': ('condition', 'category', 'status'),
        }),
        ('Images', {
            'fields': ('images',),
        }),
        ('Seller', {
            'fields': ('seller',),
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
        }),
    )


@admin.register(WishlistItem)
class WishlistItemAdmin(admin.ModelAdmin):
    """Admin for wishlist items."""
    list_display = ['user', 'item', 'added_at']
    list_filter = ['added_at']
    search_fields = ['user__email', 'item__title']
