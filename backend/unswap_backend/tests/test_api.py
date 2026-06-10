"""
Comprehensive integration tests for all critical API endpoints.

Covers authentication, users, items, transactions, chat, and notifications.
Uses Django's test client with JWT token authentication.
"""

import json
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from rest_framework import status
from rest_framework.test import APIClient

from chat.models import Chat, ChatMessage
from items.models import Category, Item, WishlistItem
from notifications.models import Notification
from transactions.models import Review, Transaction

User = get_user_model()


class BaseAPITestCase(TestCase):
    """Base test case with common setup and helper methods."""

    @classmethod
    def setUpTestData(cls):
        """Create test data shared across all tests."""
        # Create test users
        cls.user1 = User.objects.create_user(
            email='alice@university.edu',
            name='Alice Johnson',
            password='testpass123',
            university_domain='university.edu',
        )
        cls.user2 = User.objects.create_user(
            email='bob@university.edu',
            name='Bob Smith',
            password='testpass123',
            university_domain='university.edu',
        )
        cls.admin_user = User.objects.create_superuser(
            email='admin@university.edu',
            name='Admin User',
            password='adminpass123',
            university_domain='university.edu',
        )

        # Create categories
        cls.category = Category.objects.create(
            name='Textbooks', slug='textbooks'
        )
        cls.category2 = Category.objects.create(
            name='Electronics', slug='electronics'
        )

        # Create items
        cls.item1 = Item.objects.create(
            title='Calculus Textbook',
            description='Like new, barely used.',
            price=Decimal('45.00'),
            condition='like_new',
            category=cls.category,
            seller=cls.user1,
            status='available',
        )
        cls.item2 = Item.objects.create(
            title='Laptop',
            description='Good condition, 1 year old.',
            price=Decimal('500.00'),
            condition='good',
            category=cls.category2,
            seller=cls.user2,
            status='available',
        )

    def setUp(self):
        """Set up test client and authenticate."""
        self.client = APIClient()

    def authenticate(self, user):
        """Obtain JWT token and set auth header."""
        response = self.client.post('/api/auth/token/', {
            'email': user.email,
            'password': 'testpass123',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        token = response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

    def get_token(self, user):
        """Get a JWT token pair for a user without setting headers."""
        response = self.client.post('/api/auth/token/', {
            'email': user.email,
            'password': 'testpass123',
        }, format='json')
        return response.data

    def authenticate_admin(self):
        """Authenticate as admin user (admin has different password)."""
        response = self.client.post('/api/auth/token/', {
            'email': self.admin_user.email,
            'password': 'adminpass123',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        token = response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')


class AuthenticationTests(BaseAPITestCase):
    """Tests for JWT authentication and registration."""

    def test_user_registration_success(self):
        """Test successful user registration with valid university email."""
        response = self.client.post('/api/auth/register/', {
            'email': 'charlie@university.edu',
            'name': 'Charlie Brown',
            'password': 'securepass123',
            'password_confirm': 'securepass123',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['email'], 'charlie@university.edu')
        self.assertIn('id', response.data)

    def test_user_registration_invalid_domain(self):
        """Test registration with non-university email is rejected."""
        response = self.client.post('/api/auth/register/', {
            'email': 'charlie@gmail.com',
            'name': 'Charlie Brown',
            'password': 'securepass123',
            'password_confirm': 'securepass123',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('email', response.data)

    def test_user_registration_password_mismatch(self):
        """Test registration with mismatched passwords."""
        response = self.client.post('/api/auth/register/', {
            'email': 'charlie@university.edu',
            'name': 'Charlie Brown',
            'password': 'securepass123',
            'password_confirm': 'differentpass',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_jwt_token_obtain(self):
        """Test obtaining JWT token with valid credentials."""
        response = self.client.post('/api/auth/token/', {
            'email': 'alice@university.edu',
            'password': 'testpass123',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_jwt_token_refresh(self):
        """Test refreshing JWT token."""
        tokens = self.get_token(self.user1)
        # Use the refresh token, not the access token
        response = self.client.post('/api/auth/token/refresh/', {
            'refresh': tokens['refresh'],
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)

    def test_jwt_token_verify(self):
        """Test verifying JWT token."""
        tokens = self.get_token(self.user1)
        response = self.client.post('/api/auth/token/verify/', {
            'token': tokens['access'],
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_unauthenticated_access_denied(self):
        """Test that unauthenticated requests to protected endpoints fail."""
        response = self.client.get('/api/users/me/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class UserTests(BaseAPITestCase):
    """Tests for user profile and settings endpoints."""

    def test_get_current_user(self):
        """Test GET /api/users/me/ returns current user profile."""
        self.authenticate(self.user1)
        response = self.client.get('/api/users/me/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['email'], 'alice@university.edu')
        self.assertIn('profile', response.data)
        self.assertIn('settings', response.data)

    def test_update_current_user(self):
        """Test PATCH /api/users/me/ updates user fields."""
        self.authenticate(self.user1)
        response = self.client.patch('/api/users/me/', {
            'name': 'Alice J.',
            'bio': 'Computer Science student',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Alice J.')

    def test_get_user_settings(self):
        """Test GET /api/users/settings/ returns settings."""
        self.authenticate(self.user1)
        response = self.client.get('/api/users/settings/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('notification_enabled', response.data)
        self.assertIn('theme', response.data)

    def test_update_user_settings(self):
        """Test PATCH /api/users/settings/ updates settings."""
        self.authenticate(self.user1)
        response = self.client.patch('/api/users/settings/', {
            'theme': 'dark',
            'notification_enabled': False,
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['theme'], 'dark')
        self.assertFalse(response.data['notification_enabled'])

    def test_list_users(self):
        """Test GET /api/users/ returns paginated user list."""
        self.authenticate(self.user1)
        response = self.client.get('/api/users/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)

    def test_get_user_detail(self):
        """Test GET /api/users/{id}/ returns user details."""
        self.authenticate(self.user1)
        response = self.client.get(f'/api/users/{self.user2.id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['email'], 'bob@university.edu')

    def test_get_user_ratings(self):
        """Test GET /api/users/{id}/ratings/ returns rating info."""
        self.authenticate(self.user1)
        response = self.client.get(
            f'/api/users/{self.user2.id}/ratings/'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('rating_avg', response.data)


class ItemTests(BaseAPITestCase):
    """Tests for item listing endpoints."""

    def test_list_items(self):
        """Test GET /api/items/ returns paginated items."""
        response = self.client.get('/api/items/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)

    def test_get_item_detail(self):
        """Test GET /api/items/{id}/ returns item details."""
        response = self.client.get(f'/api/items/{self.item1.id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Calculus Textbook')

    def test_create_item(self):
        """Test POST /api/items/ creates a new listing."""
        self.authenticate(self.user1)
        response = self.client.post('/api/items/', {
            'title': 'Python Programming Book',
            'description': 'Great condition.',
            'price': '35.00',
            'condition': 'good',
            'category': self.category.id,
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Python Programming Book')

    def test_update_own_item(self):
        """Test PATCH /api/items/{id/} updates own item."""
        self.authenticate(self.user1)
        response = self.client.patch(
            f'/api/items/{self.item1.id}/',
            {'price': '40.00'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['price'], '40.00')

    def test_cannot_update_others_item(self):
        """Test user cannot update another user's item."""
        self.authenticate(self.user2)
        response = self.client.patch(
            f'/api/items/{self.item1.id}/',
            {'price': '40.00'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_mark_item_sold(self):
        """Test POST /api/items/{id}/mark_sold/ marks item as sold."""
        self.authenticate(self.user1)
        response = self.client.post(
            f'/api/items/{self.item1.id}/mark_sold/'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'sold')

    def test_non_seller_cannot_mark_sold(self):
        """Test non-seller cannot mark item as sold."""
        self.authenticate(self.user2)
        response = self.client.post(
            f'/api/items/{self.item1.id}/mark_sold/'
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_filter_items_by_category(self):
        """Test filtering items by category."""
        response = self.client.get(
            f'/api/items/?category={self.category.id}'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        for item in response.data['results']:
            self.assertEqual(
                item['category_name'], 'Textbooks'
            )

    def test_search_items(self):
        """Test searching items by title."""
        response = self.client.get('/api/items/?search=Calculus')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data['results']) > 0)

    def test_list_categories(self):
        """Test GET /api/categories/ returns all categories."""
        response = self.client.get('/api/categories/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data) >= 2)


class WishlistTests(BaseAPITestCase):
    """Tests for wishlist endpoints."""

    def test_add_to_wishlist(self):
        """Test POST /api/wishlist/ adds item to wishlist."""
        self.authenticate(self.user1)
        response = self.client.post('/api/wishlist/', {
            'item': self.item2.id,
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_list_wishlist(self):
        """Test GET /api/wishlist/ returns user's wishlist."""
        self.authenticate(self.user1)
        WishlistItem.objects.create(
            user=self.user1, item=self.item2
        )
        response = self.client.get('/api/wishlist/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data['results']) > 0)

    def test_remove_from_wishlist(self):
        """Test DELETE /api/wishlist/{id}/ removes item."""
        self.authenticate(self.user1)
        wishlist_item = WishlistItem.objects.create(
            user=self.user1, item=self.item2
        )
        response = self.client.delete(
            f'/api/wishlist/{wishlist_item.id}/'
        )
        self.assertEqual(
            response.status_code, status.HTTP_204_NO_CONTENT
        )


class TransactionTests(BaseAPITestCase):
    """Tests for transaction endpoints."""

    def test_create_transaction(self):
        """Test POST /api/transactions/ creates a transaction."""
        self.authenticate(self.user2)
        response = self.client.post('/api/transactions/', {
            'item': self.item1.id,
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['status'], 'pending')

    def test_list_transactions(self):
        """Test GET /api/transactions/ returns user's transactions."""
        self.authenticate(self.user1)
        response = self.client.get('/api/transactions/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_complete_transaction(self):
        """Test POST /api/transactions/{id}/complete/."""
        self.authenticate(self.user2)
        txn = Transaction.objects.create(
            buyer=self.user2,
            seller=self.user1,
            item=self.item1,
            status='pending',
        )
        self.authenticate(self.user1)  # Seller completes
        response = self.client.post(
            f'/api/transactions/{txn.id}/complete/'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'completed')

    def test_cancel_transaction(self):
        """Test POST /api/transactions/{id}/cancel/."""
        self.authenticate(self.user2)
        txn = Transaction.objects.create(
            buyer=self.user2,
            seller=self.user1,
            item=self.item1,
            status='pending',
        )
        response = self.client.post(
            f'/api/transactions/{txn.id}/cancel/'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'cancelled')


class ReviewTests(BaseAPITestCase):
    """Tests for review endpoints."""

    def test_create_review(self):
        """Test POST /api/reviews/ creates a review."""
        self.authenticate(self.user1)
        response = self.client.post('/api/reviews/', {
            'reviewee': self.user2.id,
            'rating': 5,
            'comment': 'Great seller!',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['rating'], 5)

    def test_cannot_self_review(self):
        """Test user cannot review themselves."""
        self.authenticate(self.user1)
        response = self.client.post('/api/reviews/', {
            'reviewee': self.user1.id,
            'rating': 5,
            'comment': 'Myself!',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_update_review(self):
        """Test reviews cannot be updated."""
        self.authenticate(self.user1)
        review = Review.objects.create(
            reviewer=self.user1,
            reviewee=self.user2,
            rating=4,
            comment='Good',
        )
        response = self.client.patch(
            f'/api/reviews/{review.id}/',
            {'rating': 3},
            format='json',
        )
        self.assertEqual(
            response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED
        )

    def test_cannot_delete_review(self):
        """Test reviews cannot be deleted."""
        self.authenticate(self.user1)
        review = Review.objects.create(
            reviewer=self.user1,
            reviewee=self.user2,
            rating=4,
            comment='Good',
        )
        response = self.client.delete(
            f'/api/reviews/{review.id}/'
        )
        self.assertEqual(
            response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED
        )


class ChatTests(BaseAPITestCase):
    """Tests for chat endpoints."""

    def test_create_chat(self):
        """Test POST /api/chats/ creates a chat."""
        self.authenticate(self.user1)
        response = self.client.post('/api/chats/', {
            'participants': [self.user2.id],
            'item': self.item1.id,
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_list_chats(self):
        """Test GET /api/chats/ returns user's chats."""
        self.authenticate(self.user1)
        chat = Chat.objects.create(item=self.item1)
        chat.participants.add(self.user1, self.user2)
        response = self.client.get('/api/chats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data['results']) > 0)

    def test_send_message(self):
        """Test POST /api/chats/{id}/send_message/."""
        self.authenticate(self.user1)
        chat = Chat.objects.create(item=self.item1)
        chat.participants.add(self.user1, self.user2)
        response = self.client.post(
            f'/api/chats/{chat.id}/send_message/',
            {'content': 'Hello, is this still available?'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(
            response.data['content'], 'Hello, is this still available?'
        )

    def test_mark_messages_read(self):
        """Test POST /api/chats/{id}/mark_read/."""
        self.authenticate(self.user1)
        chat = Chat.objects.create(item=self.item1)
        chat.participants.add(self.user1, self.user2)
        ChatMessage.objects.create(
            chat=chat, sender=self.user2,
            content='Test message',
        )
        response = self.client.post(
            f'/api/chats/{chat.id}/mark_read/'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['marked_read'], 1)


class NotificationTests(BaseAPITestCase):
    """Tests for notification endpoints."""

    def test_list_notifications(self):
        """Test GET /api/notifications/ returns user's notifications."""
        self.authenticate(self.user1)
        Notification.objects.create(
            recipient=self.user1,
            type=Notification.Type.NEW_MESSAGE,
            content='You have a new message.',
        )
        response = self.client.get('/api/notifications/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data['results']) > 0)

    def test_unread_notifications(self):
        """Test GET /api/notifications/unread/."""
        self.authenticate(self.user1)
        Notification.objects.create(
            recipient=self.user1,
            type=Notification.Type.NEW_MESSAGE,
            content='Unread message.',
        )
        response = self.client.get('/api/notifications/unread/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['unread_count'], 1)

    def test_mark_notification_read(self):
        """Test POST /api/notifications/{id}/mark_read/."""
        self.authenticate(self.user1)
        notification = Notification.objects.create(
            recipient=self.user1,
            type=Notification.Type.NEW_MESSAGE,
            content='Mark me as read.',
        )
        response = self.client.post(
            f'/api/notifications/{notification.id}/mark_read/'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['is_read'])

    def test_mark_all_notifications_read(self):
        """Test POST /api/notifications/mark_all_read/."""
        self.authenticate(self.user1)
        for i in range(3):
            Notification.objects.create(
                recipient=self.user1,
                type=Notification.Type.NEW_MESSAGE,
                content=f'Notification {i}',
            )
        response = self.client.post(
            '/api/notifications/mark_all_read/'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['marked_read'], 3)


class AdminStatsTests(BaseAPITestCase):
    """Tests for admin statistics endpoint."""

    def test_admin_stats_requires_admin(self):
        """Test non-admin users cannot access admin stats."""
        self.authenticate(self.user1)
        response = self.client.get('/api/admin/stats/')
        self.assertEqual(
            response.status_code, status.HTTP_403_FORBIDDEN
        )

    def test_admin_stats_returns_data(self):
        """Test admin can access statistics."""
        self.authenticate_admin()
        response = self.client.get('/api/admin/stats/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_users', response.data)
        self.assertIn('active_listings', response.data)
        self.assertIn('avg_rating', response.data)


class NotificationSignalTests(BaseAPITestCase):
    """Tests for automatic notification creation via signals."""

    def test_message_creates_notification(self):
        """Test sending a message creates notification for other participants."""
        chat = Chat.objects.create(item=self.item1)
        chat.participants.add(self.user1, self.user2)

        # User1 sends a message
        ChatMessage.objects.create(
            chat=chat, sender=self.user1,
            content='Hey Bob!',
        )

        # User2 should have a notification
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.user2,
                type=Notification.Type.NEW_MESSAGE,
            ).exists()
        )

    def test_transaction_creates_notification(self):
        """Test creating a transaction creates notification for seller."""
        Transaction.objects.create(
            buyer=self.user2,
            seller=self.user1,
            item=self.item1,
            status='pending',
        )

        # Seller should have a notification
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.user1,
                type=Notification.Type.TRANSACTION_UPDATE,
            ).exists()
        )
