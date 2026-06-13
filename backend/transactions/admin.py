"""
Admin configuration for the transactions app.

Registers Transaction and Review with the Django admin.
"""

from django.contrib import admin

from .models import Review, Transaction


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    """Admin for transactions."""
    list_display = [
        'item', 'buyer', 'seller', 'status',
        'transaction_date', 'completion_date',
    ]
    list_filter = ['status', 'transaction_date']
    search_fields = [
        'item__title', 'buyer__email', 'seller__email',
    ]
    date_hierarchy = 'transaction_date'
    readonly_fields = ['transaction_date']

    actions = ['mark_as_completed', 'mark_as_cancelled']

    def mark_as_completed(self, request, queryset):
        """Admin action to mark transactions as completed."""
        updated = queryset.update(status='completed')
        self.message_user(request, f'{updated} transaction(s) marked as completed.')
    mark_as_completed.short_description = 'Mark selected transactions as completed'

    def mark_as_cancelled(self, request, queryset):
        """Admin action to mark transactions as cancelled."""
        updated = queryset.update(status='cancelled')
        self.message_user(request, f'{updated} transaction(s) marked as cancelled.')
    mark_as_cancelled.short_description = 'Mark selected transactions as cancelled'


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    """Admin for reviews."""
    list_display = ['reviewer', 'reviewee', 'rating', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['reviewer__email', 'reviewee__email', 'comment']
