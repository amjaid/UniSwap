"""
Serializers for the users app.

Handles user registration with university email validation,
profile serialization, and settings management.
"""

from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import UserProfile, UserSettings

User = get_user_model()


class UserRegistrationSerializer(serializers.ModelSerializer):
    """
    Serializer for user registration.

    Validates university email domain and creates the user
    with encrypted password. Auto-creates UserProfile and
    UserSettings via signal.
    """
    password = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        min_length=8,
        help_text='Password (minimum 8 characters)',
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        help_text='Confirm password (must match)',
    )

    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'password', 'password_confirm',
            'bio', 'avatar_url',
        ]
        read_only_fields = ['id']

    def validate_email(self, value):
        """Validate that the email domain is an allowed university domain."""
        email = value.lower().strip()
        domain = email.split('@')[-1]

        allowed_domains = getattr(settings, 'ALLOWED_UNIVERSITY_DOMAINS', [])
        if domain not in allowed_domains:
            raise serializers.ValidationError(
                f'Email domain "{domain}" is not recognized. '
                f'Please use your university email address.'
            )

        # Check for duplicate email
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError(
                'A user with this email address already exists.'
            )

        return email

    def validate(self, attrs):
        """Ensure passwords match."""
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError(
                {'password_confirm': 'Passwords do not match.'}
            )
        return attrs

    def create(self, validated_data):
        """Create user with encrypted password."""
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    """
    Serializer for user profile information.

    Includes computed fields like average rating and transaction count.
    """
    email = serializers.EmailField(source='user.email', read_only=True)
    name = serializers.CharField(source='user.name', read_only=True)
    avatar = serializers.ImageField(source='user.avatar', read_only=True)
    avatar_url = serializers.URLField(source='user.avatar_url', read_only=True)
    bio = serializers.CharField(source='user.bio', read_only=True)
    university_domain = serializers.CharField(
        source='user.university_domain', read_only=True
    )
    date_joined = serializers.DateTimeField(
        source='user.date_joined', read_only=True
    )

    class Meta:
        model = UserProfile
        fields = [
            'email', 'name', 'avatar', 'avatar_url', 'bio',
            'university_domain', 'date_joined',
            'rating_avg', 'total_transactions', 'reported_count',
        ]


class UserSettingsSerializer(serializers.ModelSerializer):
    """Serializer for user preferences and settings."""

    class Meta:
        model = UserSettings
        fields = [
            'notification_enabled', 'theme', 'language',
        ]


class UserListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for listing users (e.g., search results).
    """
    rating_avg = serializers.DecimalField(
        source='profile.rating_avg',
        max_digits=3,
        decimal_places=2,
        read_only=True,
    )

    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'avatar_url',
            'university_domain', 'rating_avg',
        ]


class UserDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for a single user profile.
    """
    profile = UserProfileSerializer(read_only=True)
    settings = UserSettingsSerializer(read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'avatar', 'avatar_url',
            'bio', 'university_domain', 'is_active',
            'date_joined', 'profile', 'settings',
        ]
        read_only_fields = [
            'id', 'email', 'university_domain',
            'is_active', 'date_joined',
        ]
