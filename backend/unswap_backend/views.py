"""
Custom admin statistics views for UniSwap.

Provides API endpoints for platform-wide statistics
used by the admin dashboard (US-401).
"""

import logging
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import Avg, Count, Q
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from items.models import Item
from transactions.models import Review, Transaction

logger = logging.getLogger(__name__)
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


class AdminDashboardStatsView(APIView):
    """
    Enhanced dashboard statistics for the admin panel.

    GET /api/admin/stats/dashboard/

    Returns richer statistics including:
    - total_users, active_users, inactive_users
    - total_listings, active_listings, sold_listings, pending_listings
    - total_transactions, pending_transactions, completed_transactions
    - monthly_active_users (users active in last 30 days)
    - avg_rating, total_reviews
    """
    permission_classes = [IsAdminUser]

    def get(self, request):
        try:
            now = timezone.now()
            thirty_days_ago = now - timedelta(days=30)

            # User stats
            total_users = User.objects.count()
            active_users = User.objects.filter(is_active=True).count()
            inactive_users = total_users - active_users

            # Users active in last 30 days (have a transaction or review)
            # NOTE: Transaction model uses related_name='purchases' for buyer
            #       and related_name='sales' for seller.
            #       Review model uses related_name='reviews_given' for reviewer.
            monthly_active_users = User.objects.filter(
                Q(purchases__transaction_date__gte=thirty_days_ago) |
                Q(sales__transaction_date__gte=thirty_days_ago) |
                Q(reviews_given__created_at__gte=thirty_days_ago)
            ).distinct().count()

            # Listing stats
            total_listings = Item.objects.count()
            active_listings = Item.objects.filter(status='available').count()
            sold_listings = Item.objects.filter(status='sold').count()
            pending_listings = Item.objects.filter(status='pending').count()

            # Transaction stats
            total_transactions = Transaction.objects.count()
            pending_transactions = Transaction.objects.filter(status='pending').count()
            completed_transactions = Transaction.objects.filter(status='completed').count()
            cancelled_transactions = Transaction.objects.filter(status='cancelled').count()

            # Rating stats
            rating_stats = Review.objects.aggregate(
                avg_rating=Avg('rating'),
                total_reviews=Count('id'),
            )

            return Response({
                'total_users': total_users,
                'active_users': active_users,
                'inactive_users': inactive_users,
                'monthly_active_users': monthly_active_users,
                'total_listings': total_listings,
                'active_listings': active_listings,
                'sold_listings': sold_listings,
                'pending_listings': pending_listings,
                'total_transactions': total_transactions,
                'pending_transactions': pending_transactions,
                'completed_transactions': completed_transactions,
                'cancelled_transactions': cancelled_transactions,
                'avg_rating': float(rating_stats['avg_rating'] or 0.0),
                'total_reviews': rating_stats['total_reviews'],
            })
        except Exception as e:
            logger.error(f"AdminDashboardStatsView error: {e}", exc_info=True)
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
