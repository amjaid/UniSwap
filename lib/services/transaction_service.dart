import 'package:uniswap/services/api_client.dart';

/// Service for transaction and review operations.
///
/// Communicates with the Django transactions API endpoints.
class TransactionService {
  TransactionService(this._apiClient);

  final ApiClient _apiClient;

  // ──────────────────────────────────────────────
  // Transactions
  // ──────────────────────────────────────────────

  /// Fetch the current user's transactions (both buying and selling).
  Future<ApiResponse> fetchTransactions({int page = 1}) async {
    return _apiClient.get(
      '/transactions/',
      queryParams: {'page': page.toString()},
    );
  }

  /// Create a new transaction (buyer expresses intent to purchase).
  Future<ApiResponse> createTransaction(int itemId) async {
    return _apiClient.post('/transactions/', body: {'item': itemId});
  }

  /// Complete a transaction (seller confirms completion).
  Future<ApiResponse> completeTransaction(int transactionId) async {
    return _apiClient.post('/transactions/$transactionId/complete/');
  }

  /// Cancel a transaction (either party).
  Future<ApiResponse> cancelTransaction(int transactionId) async {
    return _apiClient.post('/transactions/$transactionId/cancel/');
  }

  // ──────────────────────────────────────────────
  // Reviews
  // ──────────────────────────────────────────────

  /// Create a review for a user after a transaction.
  Future<ApiResponse> createReview({
    required int revieweeId,
    required int rating,
    String? comment,
    int? transactionId,
  }) async {
    final body = <String, dynamic>{
      'reviewee': revieweeId,
      'rating': rating,
    };
    if (comment != null) body['comment'] = comment;
    if (transactionId != null) body['transaction'] = transactionId;

    return _apiClient.post('/reviews/', body: body);
  }
}
