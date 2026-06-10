"""
Admin configuration for the users app.

Registers CustomUser, UserProfile, and UserSettings with the Django admin.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _

from .models import CustomUser, UserProfile, UserSettings


@admin.register(CustomUser)
class CustomUserAdmin(BaseUserAdmin):
    """
    Custom admin for the CustomUser model.

    Displays email as the primary identifier instead of username.
    """
    list_display = [
        'email', 'name', 'university_domain', 'is_active', 'is_staff',
        'date_joined',
    ]
    list_filter = ['is_active', 'is_staff', 'university_domain']
    search_fields = ['email', 'name']
    ordering = ['-date_joined']

    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        (_('Personal info'), {
            'fields': ('name', 'bio', 'avatar', 'avatar_url'),
        }),
        (_('University'), {
            'fields': ('university_domain',),
        }),
        (_('Permissions'), {
            'fields': (
                'is_active', 'is_staff', 'is_superuser',
                'groups', 'user_permissions',
            ),
        }),
        (_('Important dates'), {
            'fields': ('last_login', 'date_joined'),
        }),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'name', 'password1', 'password2'),
        }),
    )


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """Admin for user profiles."""
    list_display = ['user', 'rating_avg', 'total_transactions', 'reported_count']
    list_filter = ['rating_avg']
    search_fields = ['user__email', 'user__name']


@admin.register(UserSettings)
class UserSettingsAdmin(admin.ModelAdmin):
    """Admin for user settings."""
    list_display = ['user', 'notification_enabled', 'theme', 'language']
    list_filter = ['notification_enabled', 'theme', 'language']
    search_fields = ['user__email']
