"""
Admin configuration for the notifications app.

Registers Notification with the Django admin.
"""

from django.contrib import admin

from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """Admin for in-app notifications."""
    list_display = ['recipient', 'type', 'content_preview', 'is_read', 'created_at']
    list_filter = ['type', 'is_read', 'created_at']
    search_fields = ['recipient__email', 'content']
    readonly_fields = ['recipient', 'type', 'content', 'created_at']

    def content_preview(self, obj):
        """Show a truncated preview of the notification content."""
        return obj.content[:75] + '...' if len(obj.content) > 75 else obj.content
    content_preview.short_description = 'Content'

    def has_add_permission(self, request):
        """Notifications should only be created programmatically."""
        return False
