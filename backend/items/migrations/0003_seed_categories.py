"""
Data migration to seed default categories for item listings.

Creates the standard categories used by the Flutter frontend:
General, Textbooks, Electronics, Clothing.
"""

from django.db import migrations


def seed_categories(apps, schema_editor):
    """Create default categories if they don't already exist."""
    Category = apps.get_model('items', 'Category')
    categories = [
        {'name': 'General', 'slug': 'general'},
        {'name': 'Textbooks', 'slug': 'textbooks'},
        {'name': 'Electronics', 'slug': 'electronics'},
        {'name': 'Clothing', 'slug': 'clothing'},
        {'name': 'Furniture', 'slug': 'furniture'},
        {'name': 'Sports', 'slug': 'sports'},
        {'name': 'Other', 'slug': 'other'},
    ]
    for cat in categories:
        Category.objects.get_or_create(
            name=cat['name'],
            defaults={'slug': cat['slug']},
        )


def reverse_seed(apps, schema_editor):
    """Remove seeded categories (no-op to avoid data loss)."""
    pass


class Migration(migrations.Migration):
    """Seed default categories."""

    dependencies = [
        ('items', '0002_initial'),
    ]

    operations = [
        migrations.RunPython(seed_categories, reverse_seed),
    ]
