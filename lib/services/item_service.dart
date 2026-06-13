import 'package:image_picker/image_picker.dart' show XFile;
import 'package:uniswap/services/api_client.dart';

/// Service for item listing CRUD operations and search/filter.
///
/// Communicates with the Django items API endpoints.
class ItemService {
  ItemService(this._apiClient);

  final ApiClient _apiClient;

  /// Fetch paginated list of items with optional filters.
  ///
  /// [page] - Page number for pagination (default: 1).
  /// [category] - Filter by category ID.
  /// [condition] - Filter by condition (new/like_new/good/fair).
  /// [minPrice] / [maxPrice] - Price range filter.
  /// [search] - Search query for title/description.
  Future<ApiResponse> fetchItems({
    int page = 1,
    int? category,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
    };

    if (category != null) params['category'] = category.toString();
    if (condition != null) params['condition'] = condition;
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;

    return _apiClient.get('/items/', queryParams: params, requiresAuth: false);
  }

  /// Fetch a single item by its ID.
  Future<ApiResponse> fetchItem(int itemId) async {
    return _apiClient.get('/items/$itemId/', requiresAuth: false);
  }

  /// Create a new item listing.
  ///
  /// [images] - Optional list of image files to upload.
  Future<ApiResponse> createItem({
    required String title,
    required String description,
    required double price,
    required String condition,
    required int category,
    List<XFile>? images,
  }) async {
    // Map display condition names to backend enum values
    final conditionMap = {
      'new': 'new',
      'like new': 'like_new',
      'good': 'good',
      'fair': 'fair',
      'used': 'fair', // 'Used' in dropdown maps to 'fair'
    };

    final normalizedCondition =
        (conditionMap[condition.trim().toLowerCase()] ?? 'good');

    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'price': price, // Send as number, not string
      'condition': normalizedCondition,
      'category': category,
    };

    return _apiClient.post('/items/', body: body);
  }

  /// Update an existing item listing.
  ///
  /// Sends text fields as JSON PATCH. If [newImages] is provided, sends
  /// a multipart PATCH with the first image attached as `image` field.
  Future<ApiResponse> updateItem(
    int itemId, {
    String? title,
    String? description,
    double? price,
    String? condition,
    int? category,
    List<XFile>? newImages,
  }) async {
    // If there are new images, send as multipart PATCH
    if (newImages != null && newImages.isNotEmpty) {
      final fields = <String, String>{};
      if (title != null) fields['title'] = title;
      if (description != null) fields['description'] = description;
      if (price != null) fields['price'] = price.toString();
      if (condition != null) {
        final conditionMap = {
          'new': 'new',
          'like new': 'like_new',
          'good': 'good',
          'fair': 'fair',
          'used': 'fair',
        };
        fields['condition'] =
            conditionMap[condition.trim().toLowerCase()] ?? condition;
      }
      if (category != null) fields['category'] = category.toString();

      return _apiClient.patchMultipart(
        '/items/$itemId/',
        fieldName: 'image',
        file: newImages.first,
        fields: fields.isNotEmpty ? fields : null,
      );
    }

    // No images - send as JSON PATCH
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price; // Send as number, not string
    if (condition != null) {
      // Map display condition names to backend enum values
      final conditionMap = {
        'new': 'new',
        'like new': 'like_new',
        'good': 'good',
        'fair': 'fair',
        'used': 'fair',
      };
      body['condition'] =
          conditionMap[condition.trim().toLowerCase()] ?? condition;
    }
    if (category != null) body['category'] = category;

    return _apiClient.patch('/items/$itemId/', body: body);
  }

  /// Delete an item listing (seller only).
  Future<ApiResponse> deleteItem(int itemId) async {
    return _apiClient.delete('/items/$itemId/');
  }

  /// Mark an item as sold (seller only).
  Future<ApiResponse> markAsSold(int itemId) async {
    return _apiClient.post('/items/$itemId/mark_sold/');
  }

  /// Mark an item as available again (seller only).
  Future<ApiResponse> markAsAvailable(int itemId) async {
    return _apiClient.post('/items/$itemId/mark_available/');
  }

  /// Fetch all categories.
  Future<ApiResponse> fetchCategories() async {
    return _apiClient.get('/categories/', requiresAuth: false);
  }

  // ──────────────────────────────────────────────
  // Wishlist
  // ──────────────────────────────────────────────

  /// Fetch the current user's wishlist.
  Future<ApiResponse> fetchWishlist({int page = 1}) async {
    return _apiClient.get('/wishlist/', queryParams: {'page': page.toString()});
  }

  /// Add an item to the current user's wishlist.
  Future<ApiResponse> addToWishlist(int itemId) async {
    return _apiClient.post('/wishlist/', body: {'item': itemId});
  }

  /// Remove an item from the wishlist.
  Future<ApiResponse> removeFromWishlist(int wishlistItemId) async {
    return _apiClient.delete('/wishlist/$wishlistItemId/');
  }
}
