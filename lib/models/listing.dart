/// Represents an item listing fetched from the Django backend.
///
/// Parses the JSON response from `GET /api/items/`.
class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.condition,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.sellerName,
    this.sellerId,
    this.sellerAvatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse a single listing from the Django API response.
  ///
  /// Expected JSON shape (flat format from DRF serializers):
  /// ```json
  /// {
  ///   "id": 1,
  ///   "title": "Calculus Textbook",
  ///   "description": "...",
  ///   "price": "45.00",
  ///   "condition": "good",
  ///   "category": 3,
  ///   "category_name": "Textbooks",
  ///   "images": ["https://..."],
  ///   "seller_id": 5,
  ///   "seller_name": "Ahmad",
  ///   "seller_avatar_url": "https://...",
  ///   "status": "available",
  ///   "created_at": "2026-01-15T10:00:00Z",
  ///   "updated_at": "2026-01-15T10:00:00Z"
  /// }
  /// ```
  factory Listing.fromJson(Map<String, dynamic> json) {
    // Parse price – DRF DecimalField returns a string
    final rawPrice = json['price'];
    final priceStr = rawPrice?.toString() ?? '0.00';

    // Parse category – could be an object {id, name}, a raw id, or have category_name
    String categoryName = 'General';
    final rawCategory = json['category'];
    if (rawCategory is Map<String, dynamic>) {
      categoryName = (rawCategory['name'] as String?) ?? 'General';
    } else if (rawCategory is String) {
      categoryName = rawCategory;
    }
    // Also check for flat category_name field
    final flatCategoryName = json['category_name'] as String?;
    if (flatCategoryName != null && flatCategoryName.isNotEmpty) {
      categoryName = flatCategoryName;
    }

    // Parse condition – DRF stores lowercase; display as title case
    final condition = (json['condition'] as String?) ?? 'good';
    final displayCondition = condition[0].toUpperCase() + condition.substring(1);

    // Parse images – list of strings (URLs) or list of objects with 'image' key
    String imageUrl = '';
    final rawImages = json['images'];
    if (rawImages is List && rawImages.isNotEmpty) {
      final first = rawImages.first;
      if (first is Map<String, dynamic>) {
        imageUrl = (first['image'] as String?) ?? '';
      } else if (first is String) {
        imageUrl = first;
      }
    }
    // Also check for first_image (from ItemListSerializer)
    final firstImage = json['first_image'] as String?;
    if (imageUrl.isEmpty && firstImage != null) {
      imageUrl = firstImage;
    }

    // Parse seller – flat fields (seller_id, seller_name, seller_avatar_url)
    // or nested object {id, name, avatar_url}
    int? sellerId;
    String sellerName = 'Seller';
    String? sellerAvatarUrl;

    // Try flat format first
    sellerId = json['seller_id'] as int?;
    sellerName = (json['seller_name'] as String?)?.trim() ?? 'Seller';
    sellerAvatarUrl = json['seller_avatar_url'] as String?;

    // Fall back to nested format
    if (sellerId == null) {
      final rawSeller = json['seller'];
      if (rawSeller is Map<String, dynamic>) {
        sellerId = rawSeller['id'] as int?;
        sellerName = (rawSeller['name'] as String?)?.trim() ?? 'Seller';
        sellerAvatarUrl = rawSeller['avatar_url'] as String?;
      } else if (rawSeller is int) {
        sellerId = rawSeller;
      }
    }

    return Listing(
      id: (json['id'] as int?)?.toString() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      price: priceStr.startsWith('RM') ? priceStr : 'RM $priceStr',
      condition: displayCondition,
      category: categoryName,
      description: (json['description'] as String?)?.trim() ?? '',
      imageUrl: imageUrl,
      sellerName: sellerName,
      sellerId: sellerId,
      sellerAvatarUrl: sellerAvatarUrl,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  /// Parse a list of listings from a paginated API response.
  ///
  /// Handles both `{"results": [...]}` (paginated) and `[...]` (list) formats.
  static List<Listing> listFromJson(Map<String, dynamic> json) {
    final raw = json['results'] as List<dynamic>? ?? [];
    return raw
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  final String id;
  final String title;
  final String price;
  final String condition;
  final String category;
  final String description;
  final String imageUrl;
  final String sellerName;

  /// The Django user ID of the seller.
  final int? sellerId;

  /// URL of the seller's avatar/profile picture.
  final String? sellerAvatarUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;
}
