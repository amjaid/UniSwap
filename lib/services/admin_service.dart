import 'package:uniswap/services/api_client.dart';

/// Service for admin-only API endpoints.
///
/// All methods require the current user to have `is_staff=True`.
/// The backend enforces this via `IsAdminUser` permission class.
class AdminService {
  AdminService(this._apiClient);

  final ApiClient _apiClient;

  // ──────────────────────────────────────────────
  // Dashboard Stats
  // ──────────────────────────────────────────────

  /// Fetch enhanced dashboard statistics.
  ///
  /// Returns: total_users, active_users, inactive_users, monthly_active_users,
  /// total_listings, active_listings, sold_listings, pending_listings,
  /// total_transactions, pending_transactions, completed_transactions,
  /// cancelled_transactions, avg_rating, total_reviews.
  Future<ApiResponse> getDashboardStats() {
    return _apiClient.get('/admin/stats/dashboard/');
  }

  // ──────────────────────────────────────────────
  // User Management
  // ──────────────────────────────────────────────

  /// List all users (paginated, searchable).
  ///
  /// [page] - Page number (1-based, default 1).
  /// [search] - Optional search query (matches email or name).
  Future<ApiResponse> getUsers({int page = 1, String? search}) {
    final params = <String, String>{
      'page': page.toString(),
    };
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    return _apiClient.get('/admin/users/', queryParams: params);
  }

  /// Soft-delete a user by ID.
  ///
  /// Sets `is_active=False` on the user. Returns 204 on success.
  Future<ApiResponse> deleteUser(int userId) {
    return _apiClient.delete('/admin/users/$userId/');
  }

  // ──────────────────────────────────────────────
  // Item Management
  // ──────────────────────────────────────────────

  /// List all items (paginated, filterable, searchable).
  ///
  /// [page] - Page number (1-based, default 1).
  /// [status] - Optional filter by status (available/sold/pending).
  /// [search] - Optional search query (matches title).
  Future<ApiResponse> getItems({
    int page = 1,
    String? status,
    String? search,
  }) {
    final params = <String, String>{
      'page': page.toString(),
    };
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    return _apiClient.get('/admin/items/', queryParams: params);
  }

  /// Soft-delete an item by ID.
  ///
  /// Sets `is_deleted=True` on the item. Returns 204 on success.
  Future<ApiResponse> deleteItem(int itemId) {
    return _apiClient.delete('/admin/items/$itemId/');
  }
}
