import 'package:uniswap/models/listing.dart';

class ListingRepository {
  ListingRepository() : _listings = List<Listing>.from(_seedListings());

  final List<Listing> _listings;

  Future<List<Listing>> fetchFeatured({String category = 'All', String query = ''}) async {
    final filtered = _applyFilters(_listings, category: category, query: query);
    return filtered.take(3).toList();
  }

  Future<List<Listing>> fetchNearby({String category = 'All', String query = ''}) async {
    final filtered = _applyFilters(_listings, category: category, query: query);
    return filtered.reversed.take(4).toList();
  }

  Future<List<Listing>> search({
    String query = '',
    String category = 'All',
    String sortBy = 'Popular',
  }) async {
    final filtered = _applyFilters(_listings, category: category, query: query);
    final sorted = _applySort(filtered, sortBy);
    return sorted;
  }

  List<Listing> getAll() {
    return List<Listing>.from(_listings);
  }

  Listing? getById(String id) {
    try {
      return _listings.firstWhere((listing) => listing.id == id);
    } catch (_) {
      return null;
    }
  }

  Listing createListing({
    required String title,
    required String price,
    required String condition,
    required String category,
    required String description,
    required String imageUrl,
    required String sellerName,
  }) {
    final listing = Listing(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      price: price,
      condition: condition,
      category: category,
      description: description,
      imageUrl: imageUrl,
      sellerName: sellerName,
    );
    _listings.insert(0, listing);
    return listing;
  }

  static List<Listing> _seedListings() {
    return const [
      Listing(
        id: '1',
        title: 'Calculus Textbook',
        price: 'RM 45',
        condition: 'Good',
        category: 'Textbooks',
        description: 'Well-kept calculus textbook with highlights and notes.',
        imageUrl: 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f',
        sellerName: 'utm_student',
      ),
      Listing(
        id: '2',
        title: 'Sony WH-1000XM5',
        price: 'RM 320',
        condition: 'Like New',
        category: 'Electronics',
        description: 'Noise-cancelling headphones with case and cable.',
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
        sellerName: 'Ahmad Razif',
      ),
      Listing(
        id: '3',
        title: 'Vintage Denim Jacket',
        price: 'RM 55',
        condition: 'Good',
        category: 'Clothing',
        description: 'Classic denim jacket, size M, lightly worn.',
        imageUrl: 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f',
        sellerName: 'utm_trader',
      ),
      Listing(
        id: '4',
        title: 'Dell XPS 13',
        price: 'RM 1500',
        condition: 'Like New',
        category: 'Electronics',
        description: '13-inch ultrabook, 16GB RAM, 512GB SSD.',
        imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
        sellerName: 'Ahmad Rafli',
      ),
    ];
  }

  List<Listing> _applyFilters(
    List<Listing> listings, {
    required String category,
    required String query,
  }) {
    final lowerQuery = query.trim().toLowerCase();
    return listings.where((listing) {
      final matchesCategory = category == 'All' || listing.category == category;
      if (!matchesCategory) return false;
      if (lowerQuery.isEmpty) return true;
      return listing.title.toLowerCase().contains(lowerQuery) ||
          listing.description.toLowerCase().contains(lowerQuery) ||
          listing.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Listing> _applySort(List<Listing> listings, String sortBy) {
    if (sortBy == 'Newest') {
      return listings;
    }
    if (sortBy == 'Price: Low to High') {
      final sorted = List<Listing>.from(listings);
      sorted.sort((a, b) => _priceValue(a.price).compareTo(_priceValue(b.price)));
      return sorted;
    }
    if (sortBy == 'Price: High to Low') {
      final sorted = List<Listing>.from(listings);
      sorted.sort((a, b) => _priceValue(b.price).compareTo(_priceValue(a.price)));
      return sorted;
    }
    return listings;
  }

  double _priceValue(String price) {
    final cleaned = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
