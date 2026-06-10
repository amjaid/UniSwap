import 'package:uniswap/models/listing.dart';
import 'package:uniswap/services/item_service.dart';

/// Repository for item listings that fetches data from the Django backend.
///
/// Wraps [ItemService] and provides the same interface as the old
/// seed-data repository so existing viewmodels continue to work.
class ListingRepository {
  ListingRepository(this._itemService);

  final ItemService _itemService;

  List<Listing> _cache = [];

  /// Fetch featured listings (first page, limited to 3).
  Future<List<Listing>> fetchFeatured({
    String category = 'All',
    String query = '',
  }) async {
    await _ensureLoaded(category: category, query: query);
    return _cache.take(3).toList();
  }

  /// Fetch nearby listings (first page, limited to 4).
  Future<List<Listing>> fetchNearby({
    String category = 'All',
    String query = '',
  }) async {
    await _ensureLoaded(category: category, query: query);
    return _cache.reversed.take(4).toList();
  }

  /// Search listings with optional filters.
  Future<List<Listing>> search({
    String query = '',
    String category = 'All',
    String sortBy = 'Popular',
  }) async {
    await _ensureLoaded(category: category, query: query);
    final sorted = _applySort(_cache, sortBy);
    return sorted;
  }

  /// Get all cached listings.
  List<Listing> getAll() {
    return List<Listing>.from(_cache);
  }

  /// Get a single listing by ID.
  Listing? getById(String id) {
    try {
      return _cache.firstWhere((listing) => listing.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new listing via the Django API.
  Future<Listing?> createListing({
    required String title,
    required String price,
    required String condition,
    required String category,
    required String description,
    required String imageUrl,
    required String sellerName,
  }) async {
    // Map category name to ID (backend expects an integer)
    final categoryId = _categoryNameToId(category);

    final response = await _itemService.createItem(
      title: title,
      description: description,
      price: double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      condition: condition.toLowerCase(),
      category: categoryId,
    );

    if (response.isSuccess && response.data != null) {
      final listing = Listing.fromJson(response.data!);
      _cache.insert(0, listing);
      return listing;
    }
    return null;
  }

  /// Refresh the cache by re-fetching from the API.
  Future<void> refresh() async {
    _cache = [];
    await _ensureLoaded();
  }

  // ──────────────────────────────────────────────
  // Internal helpers
  // ──────────────────────────────────────────────

  Future<void> _ensureLoaded({
    String category = 'All',
    String query = '',
  }) async {
    try {
      final response = await _itemService.fetchItems(
        page: 1,
        search: query.isNotEmpty ? query : null,
      );
      if (response.isSuccess && response.data != null) {
        _cache = Listing.listFromJson(response.data!);
      }
    } catch (_) {
      // Keep existing cache on error
    }
  }

  List<Listing> _applySort(List<Listing> listings, String sortBy) {
    if (sortBy == 'Newest') {
      final sorted = List<Listing>.from(listings);
      sorted.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return sorted;
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

  int _categoryNameToId(String name) {
    // Map common category names to IDs (adjust based on your backend data)
    const categories = {
      'General': 1,
      'Textbooks': 2,
      'Electronics': 3,
      'Clothing': 4,
    };
    return categories[name] ?? 1;
  }
}
