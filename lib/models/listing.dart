class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.condition,
    required this.imageUrl,
    required this.sellerName,
  });

  final String id;
  final String title;
  final String price;
  final String condition;
  final String imageUrl;
  final String sellerName;
}
