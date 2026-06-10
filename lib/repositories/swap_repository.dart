import 'package:uniswap/models/swap.dart';
import 'package:uniswap/services/transaction_service.dart';

/// Repository for swap/transaction data that fetches from the Django backend.
///
/// Wraps [TransactionService] and provides the same interface as the old
/// seed-data repository so existing viewmodels continue to work.
class SwapRepository {
  SwapRepository(this._transactionService);

  final TransactionService _transactionService;

  List<Swap> _cache = [];
  bool _loaded = false;

  /// Fetch all swaps (transactions) from the API.
  Future<List<Swap>> fetchSwaps() async {
    await _ensureLoaded();
    return List<Swap>.from(_cache)
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  /// Get a single swap by ID.
  Swap? getById(String id) {
    try {
      return _cache.firstWhere((swap) => swap.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Update the status of a swap.
  void updateStatus(String id, SwapStatus status) {
    final index = _cache.indexWhere((swap) => swap.id == id);
    if (index == -1) return;
    _cache[index] = _cache[index].copyWith(
      status: status,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update the meetup location of a swap.
  void updateMeetupLocation(String id, String location) {
    final index = _cache.indexWhere((swap) => swap.id == id);
    if (index == -1) return;
    _cache[index] = _cache[index].copyWith(
      meetupLocation: location,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a new swap (transaction) via the API.
  Future<Swap?> createSwap({
    required String title,
    required String imageUrl,
    required String otherUserName,
    required String otherUserContact,
    SwapRole role = SwapRole.buying,
  }) async {
    // Transaction creation requires an item ID; for now we return null
    // since the old UI flow creates swaps from listing detail screen.
    // The actual transaction is created via TransactionService.createTransaction().
    return null;
  }

  /// Refresh the cache by re-fetching from the API.
  Future<void> refresh() async {
    _loaded = false;
    await _ensureLoaded();
  }

  // ──────────────────────────────────────────────
  // Internal helpers
  // ──────────────────────────────────────────────

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final response = await _transactionService.fetchTransactions(page: 1);
      if (response.isSuccess && response.data != null) {
        final raw = response.data!['results'] as List<dynamic>? ?? [];
        _cache = raw.map((e) => _swapFromJson(e as Map<String, dynamic>)).toList();
        _loaded = true;
      }
    } catch (_) {
      // Keep existing cache on error
    }
  }

  Swap _swapFromJson(Map<String, dynamic> json) {
    // 'item' and 'seller' can be plain FK integers from TransactionSerializer,
    // or nested Maps from other serializers. Handle both.
    final itemRaw = json['item'];
    final item = itemRaw is Map<String, dynamic> ? itemRaw : <String, dynamic>{};
    final sellerRaw = json['seller'];
    final seller = sellerRaw is Map<String, dynamic> ? sellerRaw : <String, dynamic>{};

    // Determine role based on current user (simplified – viewmodel will override)
    final statusStr = (json['status'] as String?) ?? 'pending';
    final swapStatus = _parseStatus(statusStr);

    return Swap(
      id: (json['id'] as int?)?.toString() ?? '',
      title: (item['title'] as String?)?.trim() ?? 'Item',
      imageUrl: _firstImage(item),
      otherUserName: (seller['name'] as String?)?.trim() ?? 'User',
      otherUserAvatarUrl: (seller['avatar_url'] as String?)?.trim() ?? '',
      otherUserContact: (seller['email'] as String?)?.trim() ?? '',
      role: SwapRole.buying,
      status: swapStatus,
      meetupLocation: null,
      lastUpdated:
          DateTime.tryParse(json['transaction_date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String _firstImage(Map<String, dynamic> item) {
    final images = item['images'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) {
      final first = images.first;
      if (first is Map<String, dynamic>) {
        return (first['image'] as String?) ?? '';
      }
      return first.toString();
    }
    return '';
  }

  SwapStatus _parseStatus(String status) {
    switch (status) {
      case 'completed':
        return SwapStatus.completed;
      case 'cancelled':
        return SwapStatus.cancelled;
      case 'pending':
        return SwapStatus.proposalSent;
      default:
        return SwapStatus.proposalSent;
    }
  }
}
