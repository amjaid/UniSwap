"""
URL configuration for the items app.

Maps item and wishlist API endpoints.
"""

from rest_framework.routers import DefaultRouter

from .views import CategoryViewSet, ItemViewSet, WishlistItemViewSet

router = DefaultRouter()
router.register(r'items', ItemViewSet, basename='item')
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'wishlist', WishlistItemViewSet, basename='wishlist')

urlpatterns = []

urlpatterns += router.urls
