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
  });

  final String id;
  final String title;
  final String price;
  final String condition;
  final String category;
  final String description;
  final String imageUrl;
  final String sellerName;

  /// The Django user ID of the seller (null for seed/local data).
  final int? sellerId;
}
