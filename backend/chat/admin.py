"""
Admin configuration for the chat app.

Registers Chat and ChatMessage with the Django admin.
"""

from django.contrib import admin

from .models import Chat, ChatMessage


class ChatMessageInline(admin.TabularInline):
    """Inline display of messages within a chat."""
    model = ChatMessage
    extra = 0
    readonly_fields = ['sender', 'content', 'created_at']
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(Chat)
class ChatAdmin(admin.ModelAdmin):
    """Admin for chat conversations."""
    list_display = ['id', 'item', 'created_at', 'updated_at']
    list_filter = ['created_at']
    search_fields = ['participants__email', 'item__title']
    filter_horizontal = ['participants']
    inlines = [ChatMessageInline]


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    """Admin for chat messages."""
    list_display = ['chat', 'sender', 'content_preview', 'is_read', 'created_at']
    list_filter = ['is_read', 'created_at']
    search_fields = ['content', 'sender__email']
    readonly_fields = ['chat', 'sender', 'content', 'created_at']

    def content_preview(self, obj):
        """Show a truncated preview of the message content."""
        return obj.content[:75] + '...' if len(obj.content) > 75 else obj.content
    content_preview.short_description = 'Content'
