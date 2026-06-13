import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/utils/image_utils.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';
import 'package:uniswap/widgets/rating_dialog.dart';

/// Transaction Detail screen showing full details of a single transaction.
///
/// Fetches transaction from `GET /api/transactions/{id}/` and allows:
/// - Seller: Complete or Cancel the transaction
/// - Buyer: Cancel the transaction, Leave a review after completion
class SwapDetailScreen extends ConsumerStatefulWidget {
  const SwapDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<SwapDetailScreen> createState() => _SwapDetailScreenState();
}

class _SwapDetailScreenState extends ConsumerState<SwapDetailScreen> {
  Map<String, dynamic>? _transaction;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTransaction();
  }

  Future<void> _fetchTransaction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final txnId = int.tryParse(widget.transactionId);
      if (txnId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid transaction ID.';
        });
        return;
      }

      final transactionService = ref.read(transactionServiceProvider);
      final response = await transactionService.fetchTransaction(txnId);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _transaction = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.error ?? 'Failed to load transaction.';
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load transaction.';
      });
    }
  }

  Future<void> _completeTransaction() async {
    final txnId = int.tryParse(widget.transactionId);
    if (txnId == null) return;

    setState(() => _isActionLoading = true);

    try {
      final transactionService = ref.read(transactionServiceProvider);
      final response = await transactionService.completeTransaction(txnId);
      if (response.isSuccess) {
        await _fetchTransaction();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction completed!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to complete.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete transaction.')),
        );
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _cancelTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transaction'),
        content: const Text('Are you sure you want to cancel this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final txnId = int.tryParse(widget.transactionId);
    if (txnId == null) return;

    setState(() => _isActionLoading = true);

    try {
      final transactionService = ref.read(transactionServiceProvider);
      final response = await transactionService.cancelTransaction(txnId);
      if (response.isSuccess) {
        await _fetchTransaction();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction cancelled.')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to cancel.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel transaction.')),
        );
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _leaveReview() async {
    final txn = _transaction;
    if (txn == null) return;

    final user = ref.watch(authStateProvider);
    final currentUserId = user?['id'] as int?;

    // Determine the reviewee (the other party)
    // buyer/seller can be nested objects {"id": 1, ...} or plain ints
    final buyerRaw = txn['buyer'];
    final sellerRaw = txn['seller'];
    final buyerId = buyerRaw is int ? buyerRaw : (buyerRaw is Map<String, dynamic> ? buyerRaw['id'] as int? : null);
    final sellerId = sellerRaw is int ? sellerRaw : (sellerRaw is Map<String, dynamic> ? sellerRaw['id'] as int? : null);
    final revieweeId = buyerId == currentUserId ? sellerId : buyerId;
    final revieweeName = buyerId == currentUserId
        ? (txn['seller_name'] as String? ?? 'Seller')
        : (txn['buyer_name'] as String? ?? 'Buyer');

    if (revieweeId == null) return;

    final result = await RatingDialog.show(
      context,
      revieweeName: revieweeName,
    );

    if (result == null) return;

    final txnId = int.tryParse(widget.transactionId);

    try {
      final transactionService = ref.read(transactionServiceProvider);
      final response = await transactionService.createReview(
        revieweeId: revieweeId,
        rating: result['rating'] as int,
        comment: result['comment'] as String?,
        transactionId: txnId,
      );

      if (context.mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to submit review.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final currentUserId = user?['id'] as int?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTransaction,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchTransaction,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(context, currentUserId),
    );
  }

  Widget _buildContent(BuildContext context, int? currentUserId) {
    final txn = _transaction!;
    // 'item' can be a plain FK integer (e.g., 1) from TransactionSerializer,
    // or a nested Map from other serializers. Use flat fields when available.
    final itemRaw = txn['item'];
    final itemTitle = txn['item_title'] as String? ?? 'Item';
    final itemPrice = txn['item_price'] as String? ?? '0.00';
    final itemDescription = itemRaw is Map<String, dynamic>
        ? (itemRaw['description'] as String? ?? '')
        : '';
    final status = txn['status'] as String? ?? 'pending';
    final buyerName = txn['buyer_name'] as String? ?? 'Buyer';
    final sellerName = txn['seller_name'] as String? ?? 'Seller';
    // buyer/seller can be nested objects {"id": 1, ...} or plain ints
    final buyerRaw = txn['buyer'];
    final sellerRaw = txn['seller'];
    final buyerId = buyerRaw is int ? buyerRaw : (buyerRaw is Map<String, dynamic> ? buyerRaw['id'] as int? : null);
    final sellerId = sellerRaw is int ? sellerRaw : (sellerRaw is Map<String, dynamic> ? sellerRaw['id'] as int? : null);
    final transactionDate = txn['transaction_date'] as String? ?? '';
    final completionDate = txn['completion_date'] as String?;

    final isBuyer = currentUserId == buyerId;
    final isSeller = currentUserId == sellerId;
    final isPending = status == 'pending';
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';

    // Get item image - only from nested item map if available
    String imageUrl = '';
    if (itemRaw is Map<String, dynamic>) {
      final images = itemRaw['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        final first = images.first;
        if (first is Map<String, dynamic>) {
          imageUrl = first['image'] as String? ?? '';
        } else if (first is String) {
          imageUrl = first;
        }
      }
    }

    // Status display
    final statusColor = isCompleted
        ? Colors.green
        : isCancelled
            ? Colors.red
            : Colors.orange;
    final statusLabel = status[0].toUpperCase() + status.substring(1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // Item image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            getFullImageUrl(imageUrl),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey.withAlpha(30),
              child: const Center(child: Icon(Icons.photo, size: 64, color: Colors.grey)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Item details
        Text(itemTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('RM $itemPrice', style: Theme.of(context).textTheme.titleMedium),
        if (itemDescription.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(itemDescription, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(20),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Transaction info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction Info',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _InfoRow(label: 'Buyer', value: buyerName),
                _InfoRow(label: 'Seller', value: sellerName),
                if (transactionDate.isNotEmpty)
                  _InfoRow(
                    label: 'Date',
                    value: _formatDate(transactionDate),
                  ),
                if (completionDate != null)
                  _InfoRow(
                    label: 'Completed',
                    value: _formatDate(completionDate),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action buttons
        if (isPending && isSeller)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActionLoading ? null : _completeTransaction,
              icon: _isActionLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('Mark as Completed'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        if (isPending && (isBuyer || isSeller)) ...[
          if (isPending && isSeller) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isActionLoading ? null : _cancelTransaction,
              icon: _isActionLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel),
              label: const Text('Cancel Transaction'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ],

        // Leave a review (after completion)
        if (isCompleted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _leaveReview,
              icon: const Icon(Icons.star),
              label: const Text('Leave a Review'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

        // Chat button
        if (!isCancelled) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openChat(context, currentUserId, buyerId, sellerId),
              icon: const Icon(Icons.chat),
              label: const Text('Open Chat'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Find or create a chat with the other transaction party and navigate to it.
  ///
  /// The transaction's `buyer`/`seller` fields can be plain ints or nested
  /// objects. We determine the other party's ID, then call
  /// `chatService.createChat()` to get or create a chat, and navigate
  /// to the chat screen with the correct chat ID.
  Future<void> _openChat(
    BuildContext context,
    int? currentUserId,
    int? buyerId,
    int? sellerId,
  ) async {
    // Determine the other party's user ID
    final otherUserId = currentUserId == buyerId ? sellerId : buyerId;
    if (otherUserId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not identify the other party.')),
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[SwapDetail] Opening chat with user $otherUserId (current user: $currentUserId)');
    }

    try {
      final chatService = ref.read(chatServiceProvider);
      final chatId = await chatService.getOrCreateChatId(
        participantId: otherUserId,
      );

      if (chatId != null && context.mounted) {
        if (kDebugMode) {
          debugPrint('[SwapDetail] Navigating to chat $chatId');
        }
        context.pushNamed('chat', pathParameters: {'chatId': chatId.toString()});
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open chat.')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SwapDetail] Error opening chat: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open chat.')),
        );
      }
    }
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              )),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
