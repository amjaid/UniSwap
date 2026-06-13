#!/usr/bin/env python
"""
Data migration script: Firebase Firestore -> Django ORM.

Exports all Firestore collections to JSON, then loads them into
Django models while preserving relationships.

Usage:
    # Export Firestore data to JSON
    python scripts/migrate_from_firebase.py export --project=unswap-app

    # Import JSON data into Django
    python scripts/migrate_from_firebase.py import --json-dir=./firebase_export

    # Full migration (export + import)
    python scripts/migrate_from_firebase.py migrate --project=unswap-app

Requirements:
    pip install firebase-admin google-cloud-firestore
"""

import argparse
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

# Add backend directory to Python path for Django imports
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'unswap_backend.settings')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)
logger = logging.getLogger(__name__)


# =============================================================================
# PHASE 1: Export Firestore Data to JSON
# =============================================================================

def export_firestore_data(project_id, output_dir):
    """
    Export all Firestore collections to JSON files.

    Collections exported:
    - users
    - items
    - transactions
    - reviews
    - chats
    - chat_messages
    - notifications
    - wishlist_items
    """
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        logger.error(
            'firebase-admin is required for export. '
            'Install with: pip install firebase-admin google-cloud-firestore'
        )
        sys.exit(1)

    logger.info(f'Connecting to Firebase project: {project_id}')

    # Initialize Firebase (uses default credentials or GOOGLE_APPLICATION_CREDENTIALS)
    try:
        firebase_admin.initialize_app()
    except ValueError:
        # Already initialized
        pass

    db = firestore.client()
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    collections = [
        'users', 'items', 'transactions', 'reviews',
        'chats', 'chat_messages', 'notifications', 'wishlist_items',
    ]

    for collection_name in collections:
        logger.info(f'Exporting collection: {collection_name}')
        docs = db.collection(collection_name).stream()

        data = []
        for doc in docs:
            doc_data = doc.to_dict()
            doc_data['_firebase_id'] = doc.id
            # Convert datetime objects to ISO strings
            for key, value in doc_data.items():
                if isinstance(value, datetime):
                    doc_data[key] = value.isoformat()
                elif hasattr(value, 'isoformat'):
                    doc_data[key] = value.isoformat()
            data.append(doc_data)

        output_file = output_dir / f'{collection_name}.json'
        with open(output_file, 'w') as f:
            json.dump(data, f, indent=2, default=str)

        logger.info(f'  -> Exported {len(data)} documents to {output_file}')

    logger.info(f'Export complete. Files saved to {output_dir}')


# =============================================================================
# PHASE 2: Import JSON Data into Django
# =============================================================================

def import_data_to_django(json_dir):
    """
    Import JSON data files into Django models.

    Handles:
    - User creation with proper password hashing
    - Foreign key mapping between Firestore IDs and Django PKs
    - Relationship preservation across collections
    - Error handling and progress logging
    """
    import django
    django.setup()

    from django.contrib.auth import get_user_model
    from django.db import transaction as db_transaction

    from chat.models import Chat, ChatMessage
    from items.models import Category, Item, WishlistItem
    from notifications.models import Notification
    from transactions.models import Review, Transaction

    User = get_user_model()

    json_dir = Path(json_dir)

    # Track Firestore ID -> Django PK mappings
    id_map = {
        'users': {},
        'items': {},
        'transactions': {},
        'chats': {},
    }

    # ======================================================================
    # 1. Import Users
    # ======================================================================
    logger.info('Importing users...')
    users_file = json_dir / 'users.json'
    if users_file.exists():
        with open(users_file) as f:
            users_data = json.load(f)

        for user_data in users_data:
            firebase_id = user_data.pop('_firebase_id', None)
            email = user_data.get('email', '').lower().strip()

            if not email:
                logger.warning(f'Skipping user without email: {firebase_id}')
                continue

            # Check if user already exists
            if User.objects.filter(email=email).exists():
                user = User.objects.get(email=email)
                logger.info(f'  User already exists: {email}')
            else:
                password = user_data.pop('password', None) or 'temporarypass123'
                name = user_data.pop('name', 'Unknown User')
                university_domain = user_data.pop('university_domain', '')
                bio = user_data.pop('bio', '')
                avatar_url = user_data.pop('avatar_url', '')

                user = User.objects.create_user(
                    email=email,
                    password=password,
                    name=name,
                    university_domain=university_domain,
                    bio=bio,
                    avatar_url=avatar_url,
                )
                logger.info(f'  Created user: {email}')

            if firebase_id:
                id_map['users'][firebase_id] = user.id

        logger.info(f'  Total users: {User.objects.count()}')

    # ======================================================================
    # 2. Import Categories (if present)
    # ======================================================================
    logger.info('Importing categories...')
    categories_file = json_dir / 'categories.json'
    if categories_file.exists():
        with open(categories_file) as f:
            categories_data = json.load(f)

        for cat_data in categories_data:
            name = cat_data.get('name', '').strip()
            if name and not Category.objects.filter(name=name).exists():
                Category.objects.create(
                    name=name,
                    slug=cat_data.get('slug', name.lower().replace(' ', '-')),
                )
                logger.info(f'  Created category: {name}')

    # Create default categories if none exist
    if Category.objects.count() == 0:
        default_categories = [
            'Textbooks', 'Electronics', 'Furniture', 'Clothing',
            'School Supplies', 'Sports Equipment', 'Other',
        ]
        for cat_name in default_categories:
            Category.objects.create(
                name=cat_name,
                slug=cat_name.lower().replace(' ', '-'),
            )
        logger.info(f'  Created {len(default_categories)} default categories')

    # ======================================================================
    # 3. Import Items
    # ======================================================================
    logger.info('Importing items...')
    items_file = json_dir / 'items.json'
    if items_file.exists():
        with open(items_file) as f:
            items_data = json.load(f)

        for item_data in items_data:
            firebase_id = item_data.pop('_firebase_id', None)
            seller_firebase_id = item_data.pop('seller_id', None)

            # Map seller
            seller_id = id_map['users'].get(seller_firebase_id)
            if not seller_id:
                logger.warning(
                    f'Skipping item - seller not found: {seller_firebase_id}'
                )
                continue

            title = item_data.get('title', 'Untitled')
            if Item.objects.filter(
                title=title, seller_id=seller_id
            ).exists():
                logger.info(f'  Item already exists: {title}')
                item = Item.objects.get(title=title, seller_id=seller_id)
            else:
                # Map category
                category_name = item_data.pop('category_name', None)
                category = None
                if category_name:
                    category = Category.objects.filter(
                        name__iexact=category_name
                    ).first()

                item = Item.objects.create(
                    title=title,
                    description=item_data.get('description', ''),
                    price=item_data.get('price', 0),
                    condition=item_data.get('condition', 'good'),
                    category=category,
                    images=item_data.get('images', []),
                    seller_id=seller_id,
                    status=item_data.get('status', 'available'),
                )
                logger.info(f'  Created item: {title}')

            if firebase_id:
                id_map['items'][firebase_id] = item.id

        logger.info(f'  Total items: {Item.objects.count()}')

    # ======================================================================
    # 4. Import Transactions
    # ======================================================================
    logger.info('Importing transactions...')
    transactions_file = json_dir / 'transactions.json'
    if transactions_file.exists():
        with open(transactions_file) as f:
            transactions_data = json.load(f)

        for txn_data in transactions_data:
            firebase_id = txn_data.pop('_firebase_id', None)
            buyer_id = id_map['users'].get(txn_data.pop('buyer_id', None))
            seller_id = id_map['users'].get(txn_data.pop('seller_id', None))
            item_id = id_map['items'].get(txn_data.pop('item_id', None))

            if not all([buyer_id, seller_id, item_id]):
                logger.warning(
                    f'Skipping transaction - missing references: {firebase_id}'
                )
                continue

            if Transaction.objects.filter(
                buyer_id=buyer_id, item_id=item_id
            ).exists():
                logger.info(f'  Transaction already exists for item {item_id}')
                continue

            transaction = Transaction.objects.create(
                buyer_id=buyer_id,
                seller_id=seller_id,
                item_id=item_id,
                status=txn_data.get('status', 'pending'),
            )
            logger.info(
                f'  Created transaction: {transaction.id}'
            )

            if firebase_id:
                id_map['transactions'][firebase_id] = transaction.id

        logger.info(f'  Total transactions: {Transaction.objects.count()}')

    # ======================================================================
    # 5. Import Reviews
    # ======================================================================
    logger.info('Importing reviews...')
    reviews_file = json_dir / 'reviews.json'
    if reviews_file.exists():
        with open(reviews_file) as f:
            reviews_data = json.load(f)

        for review_data in reviews_data:
            reviewer_id = id_map['users'].get(
                review_data.pop('reviewer_id', None)
            )
            reviewee_id = id_map['users'].get(
                review_data.pop('reviewee_id', None)
            )

            if not all([reviewer_id, reviewee_id]):
                logger.warning('Skipping review - missing user references')
                continue

            if Review.objects.filter(
                reviewer_id=reviewer_id, reviewee_id=reviewee_id
            ).exists():
                continue

            Review.objects.create(
                reviewer_id=reviewer_id,
                reviewee_id=reviewee_id,
                rating=review_data.get('rating', 5),
                comment=review_data.get('comment', ''),
            )
            logger.info('  Created review')

        logger.info(f'  Total reviews: {Review.objects.count()}')

    # ======================================================================
    # 6. Import Chats and Messages
    # ======================================================================
    logger.info('Importing chats...')
    chats_file = json_dir / 'chats.json'
    if chats_file.exists():
        with open(chats_file) as f:
            chats_data = json.load(f)

        for chat_data in chats_data:
            firebase_id = chat_data.pop('_firebase_id', None)
            item_id = id_map['items'].get(chat_data.pop('item_id', None))
            participant_ids = [
                id_map['users'].get(pid)
                for pid in chat_data.pop('participant_ids', [])
            ]
            participant_ids = [pid for pid in participant_ids if pid]

            if not participant_ids:
                logger.warning(
                    f'Skipping chat - no valid participants: {firebase_id}'
                )
                continue

            chat = Chat.objects.create(item_id=item_id)
            chat.participants.add(*participant_ids)
            logger.info(
                f'  Created chat with {len(participant_ids)} participants'
            )

            if firebase_id:
                id_map['chats'][firebase_id] = chat.id

        logger.info(f'  Total chats: {Chat.objects.count()}')

    # Import Chat Messages
    logger.info('Importing chat messages...')
    messages_file = json_dir / 'chat_messages.json'
    if messages_file.exists():
        with open(messages_file) as f:
            messages_data = json.load(f)

        for msg_data in messages_data:
            chat_id = id_map['chats'].get(msg_data.pop('chat_id', None))
            sender_id = id_map['users'].get(msg_data.pop('sender_id', None))

            if not all([chat_id, sender_id]):
                logger.warning('Skipping message - missing references')
                continue

            ChatMessage.objects.create(
                chat_id=chat_id,
                sender_id=sender_id,
                content=msg_data.get('content', ''),
                is_read=msg_data.get('is_read', False),
            )

        logger.info(f'  Total messages: {ChatMessage.objects.count()}')

    # ======================================================================
    # 7. Import Notifications
    # ======================================================================
    logger.info('Importing notifications...')
    notifications_file = json_dir / 'notifications.json'
    if notifications_file.exists():
        with open(notifications_file) as f:
            notifications_data = json.load(f)

        for notif_data in notifications_data:
            recipient_id = id_map['users'].get(
                notif_data.pop('recipient_id', None)
            )

            if not recipient_id:
                logger.warning('Skipping notification - no recipient')
                continue

            Notification.objects.create(
                recipient_id=recipient_id,
                type=notif_data.get('type', 'new_message'),
                content=notif_data.get('content', ''),
                is_read=notif_data.get('is_read', False),
            )

        logger.info(f'  Total notifications: {Notification.objects.count()}')

    # ======================================================================
    # 8. Import Wishlist Items
    # ======================================================================
    logger.info('Importing wishlist items...')
    wishlist_file = json_dir / 'wishlist_items.json'
    if wishlist_file.exists():
        with open(wishlist_file) as f:
            wishlist_data = json.load(f)

        for wl_data in wishlist_data:
            user_id = id_map['users'].get(wl_data.pop('user_id', None))
            item_id = id_map['items'].get(wl_data.pop('item_id', None))

            if not all([user_id, item_id]):
                logger.warning('Skipping wishlist item - missing references')
                continue

            if WishlistItem.objects.filter(
                user_id=user_id, item_id=item_id
            ).exists():
                continue

            WishlistItem.objects.create(
                user_id=user_id, item_id=item_id
            )

        logger.info(f'  Total wishlist items: {WishlistItem.objects.count()}')

    logger.info('=' * 60)
    logger.info('Import complete!')
    logger.info(f'  Users:         {User.objects.count()}')
    logger.info(f'  Items:         {Item.objects.count()}')
    logger.info(f'  Transactions:  {Transaction.objects.count()}')
    logger.info(f'  Reviews:       {Review.objects.count()}')
    logger.info(f'  Chats:         {Chat.objects.count()}')
    logger.info(f'  Messages:      {ChatMessage.objects.count()}')
    logger.info(f'  Notifications: {Notification.objects.count()}')
    logger.info(f'  Wishlist:      {WishlistItem.objects.count()}')
    logger.info('=' * 60)


# =============================================================================
# CLI Entry Point
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Migrate data from Firebase Firestore to Django ORM',
    )
    subparsers = parser.add_subparsers(dest='command', required=True)

    # Export command
    export_parser = subparsers.add_parser(
        'export', help='Export Firestore data to JSON files'
    )
    export_parser.add_argument(
        '--project',
        required=True,
        help='Firebase project ID',
    )
    export_parser.add_argument(
        '--output-dir',
        default='./firebase_export',
        help='Output directory for JSON files (default: ./firebase_export)',
    )

    # Import command
    import_parser = subparsers.add_parser(
        'import', help='Import JSON data into Django models'
    )
    import_parser.add_argument(
        '--json-dir',
        default='./firebase_export',
        help='Directory containing JSON export files (default: ./firebase_export)',
    )

    # Migrate command (export + import)
    migrate_parser = subparsers.add_parser(
        'migrate', help='Full migration: export + import'
    )
    migrate_parser.add_argument(
        '--project',
        required=True,
        help='Firebase project ID',
    )
    migrate_parser.add_argument(
        '--data-dir',
        default='./firebase_export',
        help='Directory for intermediate JSON files (default: ./firebase_export)',
    )

    args = parser.parse_args()

    if args.command == 'export':
        export_firestore_data(args.project, args.output_dir)

    elif args.command == 'import':
        import_data_to_django(args.json_dir)

    elif args.command == 'migrate':
        logger.info('Starting full migration (export + import)...')
        export_firestore_data(args.project, args.data_dir)
        import_data_to_django(args.data_dir)
        logger.info('Full migration complete!')


if __name__ == '__main__':
    main()
