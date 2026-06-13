"""
Signal handlers for creating notifications.

Automatically creates notifications when relevant events occur:
- New chat messages
- Transaction status updates
- Item status changes
"""

from django.db.models.signals import post_save
from django.dispatch import receiver

from chat.models import ChatMessage
from transactions.models import Transaction


@receiver(post_save, sender=ChatMessage)
def create_message_notification(sender, instance, created, **kwargs):
    """
    Create a notification for chat participants when a new message is sent.

    Notifies all participants except the sender that a new message
    has been posted in the chat.
    """
    if not created:
        return

    from .models import Notification

    chat = instance.chat
    sender_user = instance.sender

    # Notify all other participants
    for participant in chat.participants.all():
        if participant != sender_user:
            item_context = f' about "{chat.item.title}"' if chat.item else ''
            Notification.objects.create(
                recipient=participant,
                type=Notification.Type.NEW_MESSAGE,
                content=(
                    f'{sender_user.name} sent a message{item_context}: '
                    f'{instance.content[:100]}'
                ),
            )


@receiver(post_save, sender=Transaction)
def create_transaction_notification(sender, instance, created, **kwargs):
    """
    Create a notification when a transaction is created or updated.

    Notifies both buyer and seller about transaction status changes.
    """
    from .models import Notification

    if created:
        # Notify seller that someone wants to buy their item
        Notification.objects.create(
            recipient=instance.seller,
            type=Notification.Type.TRANSACTION_UPDATE,
            content=(
                f'{instance.buyer.name} wants to buy your item '
                f'"{instance.item.title}".'
            ),
        )
    else:
        # Notify about status changes
        status_messages = {
            'completed': (
                f'Transaction for "{instance.item.title}" has been completed.'
            ),
            'cancelled': (
                f'Transaction for "{instance.item.title}" has been cancelled.'
            ),
        }

        message = status_messages.get(instance.status)
        if message:
            # Notify both parties
            for user in [instance.buyer, instance.seller]:
                Notification.objects.create(
                    recipient=user,
                    type=Notification.Type.TRANSACTION_UPDATE,
                    content=message,
                )
