"""
URL configuration for the transactions app.

Maps transaction and review API endpoints.
"""

from rest_framework.routers import DefaultRouter

from .views import ReviewViewSet, TransactionViewSet

router = DefaultRouter()
router.register(r'transactions', TransactionViewSet, basename='transaction')
router.register(r'reviews', ReviewViewSet, basename='review')

urlpatterns = []

urlpatterns += router.urls
