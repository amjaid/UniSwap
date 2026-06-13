"""
Custom admin statistics views for UniSwap.

Provides API endpoints for platform-wide statistics
used by the admin dashboard (US-401).
"""

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import Avg, Count
from django.utils import timezone
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from items.models import Item
from transactions.models import Review, Transaction

User = get_user_model()


class AdminStatsView(APIView):
    """
    Return platform-wide statistics for the admin dashboard.

    Provides:
    - total_users: Number of registered users
    - active_listings: Number of items with status 'available'
    - monthly_transactions: Number of transactions this month
    - total_transactions: All-time transaction count
    - avg_rating: Average rating across all reviews
    - total_reviews: Number of reviews submitted
    - users_by_domain: User count grouped by university domain
    - items_by_category: Item count grouped by category
    - recent_transactions: Last 10 transactions
    """
    permission_classes = [IsAdminUser]

    def get(self, request):
        now = timezone.now()
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        # Core statistics
        total_users = User.objects.count()
        active_listings = Item.objects.filter(status='available').count()
        monthly_transactions = Transaction.objects.filter(
            transaction_date__gte=month_start
        ).count()
        total_transactions = Transaction.objects.count()

        # Rating statistics
        rating_stats = Review.objects.aggregate(
            avg_rating=Avg('rating'),
            total_reviews=Count('id'),
        )

        # Users by university domain
        users_by_domain = list(
            User.objects.values('university_domain')
            .annotate(count=Count('id'))
            .order_by('-count')
        )

        # Items by category
        items_by_category = list(
            Item.objects.values('category__name')
            .annotate(count=Count('id'))
            .order_by('-count')
        )

        # Recent transactions
        recent_transactions = list(
            Transaction.objects.select_related(
                'buyer', 'seller', 'item'
            ).order_by('-transaction_date')[:10].values(
                'id', 'status', 'transaction_date',
                'buyer__email', 'seller__email', 'item__title',
            )
        )

        return Response({
            'total_users': total_users,
            'active_listings': active_listings,
            'monthly_transactions': monthly_transactions,
            'total_transactions': total_transactions,
            'avg_rating': float(rating_stats['avg_rating'] or 0.0),
            'total_reviews': rating_stats['total_reviews'],
            'users_by_domain': users_by_domain,
            'items_by_category': items_by_category,
            'recent_transactions': recent_transactions,
        })
