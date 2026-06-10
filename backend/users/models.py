"""
Custom User model and related profiles for UniSwap.

Extends Django's AbstractUser to use email as the unique identifier
instead of username, with university email validation support.
"""

from django.contrib.auth.base_user import BaseUserManager
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _


class CustomUserManager(BaseUserManager):
    """
    Custom user manager where email is the unique identifier.

    Does not require a username field for user creation.
    """

    def create_user(self, email, password=None, **extra_fields):
        """Create and save a regular user with the given email and password."""
        if not email:
            raise ValueError(_('The Email field must be set'))
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """Create and save a superuser with the given email and password."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError(_('Superuser must have is_staff=True.'))
        if extra_fields.get('is_superuser') is not True:
            raise ValueError(_('Superuser must have is_superuser=True.'))

        return self.create_user(email, password, **extra_fields)


class CustomUser(AbstractUser):
    """
    Custom user model using email as the unique identifier.

    Removes the username field and uses email for authentication.
    Stores the normalized university domain for quick validation.
    """
    username = None  # Remove username field; use email as identifier
    email = models.EmailField(
        _('email address'),
        unique=True,
        max_length=255,
        help_text=_('University email address (e.g., student@university.edu)'),
    )
    name = models.CharField(
        _('full name'),
        max_length=150,
        blank=True,
        help_text=_('Display name shown to other users'),
    )
    avatar = models.ImageField(
        _('avatar'),
        upload_to='avatars/',
        blank=True,
        null=True,
        help_text=_('Profile picture (optional)'),
    )
    avatar_url = models.URLField(
        _('avatar URL'),
        max_length=500,
        blank=True,
        help_text=_('External URL for avatar (if not using uploaded file)'),
    )
    bio = models.TextField(
        _('bio'),
        max_length=500,
        blank=True,
        help_text=_('Short biography or description'),
    )
    university_domain = models.CharField(
        _('university domain'),
        max_length=100,
        blank=True,
        help_text=_('Normalized email domain (e.g., utm.my)'),
    )
    is_active = models.BooleanField(
        _('active'),
        default=True,
        help_text=_('Designates whether this user should be treated as active.'),
    )
    date_joined = models.DateTimeField(_('date joined'), auto_now_add=True)

    # Use email as the unique identifier for authentication
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name']  # Required when creating a superuser

    objects = CustomUserManager()

    class Meta:
        verbose_name = _('user')
        verbose_name_plural = _('users')
        ordering = ['-date_joined']
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['university_domain']),
        ]

    def __str__(self):
        return self.email

    def save(self, *args, **kwargs):
        """Extract and store the university domain from email on save."""
        if self.email:
            # Normalize: extract domain part after @
            domain = self.email.split('@')[-1].lower().strip()
            self.university_domain = domain
        super().save(*args, **kwargs)


class UserProfile(models.Model):
    """
    Extended profile information for a user.

    One-to-one relationship with CustomUser. Stores rating,
    transaction count, and moderation data.
    """
    user = models.OneToOneField(
        CustomUser,
        on_delete=models.CASCADE,
        related_name='profile',
        primary_key=True,
    )
    rating_avg = models.DecimalField(
        _('average rating'),
        max_digits=3,
        decimal_places=2,
        default=0.00,
        help_text=_('Average rating from 1.00 to 5.00'),
    )
    total_transactions = models.PositiveIntegerField(
        _('total transactions'),
        default=0,
        help_text=_('Total number of completed transactions'),
    )
    reported_count = models.PositiveIntegerField(
        _('reported count'),
        default=0,
        help_text=_('Number of times this user has been reported'),
    )

    class Meta:
        verbose_name = _('user profile')
        verbose_name_plural = _('user profiles')

    def __str__(self):
        return f'Profile of {self.user.email}'


class UserSettings(models.Model):
    """
    User preferences and settings.

    One-to-one relationship with CustomUser. Controls notification
    preferences, theme selection, and language settings.
    """
    class Theme(models.TextChoices):
        LIGHT = 'light', _('Light')
        DARK = 'dark', _('Dark')
        SYSTEM = 'system', _('System Default')

    class Language(models.TextChoices):
        ENGLISH = 'en', _('English')
        MALAY = 'ms', _('Bahasa Melayu')
        CHINESE = 'zh', _('中文')

    user = models.OneToOneField(
        CustomUser,
        on_delete=models.CASCADE,
        related_name='settings',
        primary_key=True,
    )
    notification_enabled = models.BooleanField(
        _('notifications enabled'),
        default=True,
        help_text=_('Receive push notifications'),
    )
    theme = models.CharField(
        _('theme'),
        max_length=10,
        choices=Theme.choices,
        default=Theme.SYSTEM,
        help_text=_('Application theme preference'),
    )
    language = models.CharField(
        _('language'),
        max_length=5,
        choices=Language.choices,
        default=Language.ENGLISH,
        help_text=_('Application language'),
    )

    class Meta:
        verbose_name = _('user settings')
        verbose_name_plural = _('user settings')

    def __str__(self):
        return f'Settings for {self.user.email}'


# Signal to auto-create UserProfile and UserSettings when a new user is created
from django.db.models.signals import post_save
from django.dispatch import receiver


@receiver(post_save, sender=CustomUser)
def create_user_profile_and_settings(sender, instance, created, **kwargs):
    """Automatically create UserProfile and UserSettings for new users."""
    if created:
        UserProfile.objects.create(user=instance)
        UserSettings.objects.create(user=instance)
