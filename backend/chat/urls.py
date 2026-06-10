"""
URL configuration for the chat app.

Maps chat and message API endpoints.
"""

from rest_framework.routers import DefaultRouter

from .views import ChatMessageViewSet, ChatViewSet

router = DefaultRouter()
router.register(r'chats', ChatViewSet, basename='chat')
router.register(r'messages', ChatMessageViewSet, basename='message')

urlpatterns = []

urlpatterns += router.urls
