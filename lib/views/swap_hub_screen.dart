import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/utils/image_utils.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

/// Transaction History screen showing buying and selling transactions.
///
/// Fetches transactions from `GET /api/transactions/` and displays them
/// in two tabs: Buying (user is buyer) and Selling (user is seller).
class SwapHubScreen extends ConsumerStatefulWidget {
  const SwapHubScreen({super.key});

  @override
  ConsumerState<SwapHubScreen> createState() => _SwapHubScreenState();
}

class _SwapHubScreenState extends ConsumerState<SwapHubScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionService = ref.read(transactionServiceProvider);
      final response = await transactionService.fetchTransactions();
      if (response.isSuccess && response.data != null) {
        final results = response.data!['results'] as List<dynamic>? ?? [];
        setState(() {
          _transactions = results.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.error ?? 'Failed to load transactions.';
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load transactions.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final currentUserId = user?['id'] as int?;

    // Split transactions by role.
    // Backend returns buyer/seller as nested objects: {"id": 1, "name": "..."}
    // Extract the id from the nested object.
    int? extractUserId(dynamic field) {
      if (field is int) return field;
      if (field is Map<String, dynamic>) return field['id'] as int?;
      return null;
    }

    final buying = _transactions.where((t) {
      final buyerId = extractUserId(t['buyer']);
      return buyerId == currentUserId;
    }).toList();

    final selling = _transactions.where((t) {
      final sellerId = extractUserId(t['seller']);
      return sellerId == currentUserId;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaction History'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            tabs: [
              Tab(text: 'Buying'),
              Tab(text: 'Selling'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchTransactions,
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
                          onPressed: _fetchTransactions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _TransactionList(
                        transactions: buying,
                        currentUserId: currentUserId,
                        onTap: (txn) => context.go('/swap-hub/${txn['id']}'),
                        emptyMessage: 'No purchases yet.',
                      ),
                      _TransactionList(
                        transactions: selling,
                        currentUserId: currentUserId,
                        onTap: (txn) => context.go('/swap-hub/${txn['id']}'),
                        emptyMessage: 'No sales yet.',
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.transactions,
    required this.currentUserId,
    required this.onTap,
    required this.emptyMessage,
  });

  final List<Map<String, dynamic>> transactions;
  final int? currentUserId;
  final void Function(Map<String, dynamic> txn) onTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Pull-to-refresh is handled by the parent
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final txn = transactions[index];
          return _TransactionCard(
            transaction: txn,
            currentUserId: currentUserId,
            onTap: () => onTap(txn),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.currentUserId,
    required this.onTap,
  });

  final Map<String, dynamic> transaction;
  final int? currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 'item' can be a plain FK integer (e.g., 1) from TransactionSerializer,
    // or a nested Map from other serializers. Use flat fields when available.
    final itemRaw = transaction['item'];
    final itemTitle = transaction['item_title'] as String? ?? 'Item';
    final itemPrice = transaction['item_price'] as String? ?? '0.00';
    final status = transaction['status'] as String? ?? 'pending';
    final buyerName = transaction['buyer_name'] as String? ?? 'Buyer';
    final sellerName = transaction['seller_name'] as String? ?? 'Seller';
    // buyer/seller can be nested objects {"id": 1, ...} or plain ints
    final buyerRaw = transaction['buyer'];
    final buyerId = buyerRaw is int ? buyerRaw : (buyerRaw is Map<String, dynamic> ? buyerRaw['id'] as int? : null);

    // Determine the other party's name
    final otherPartyName = buyerId == currentUserId ? sellerName : buyerName;

    // Get item image - only from flat fields since item is a FK int
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
    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'cancelled'
            ? Colors.red
            : Colors.orange;
    final statusLabel = status[0].toUpperCase() + status.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  getFullImageUrl(imageUrl),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.withAlpha(30),
                    child: const Icon(Icons.photo, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemTitle,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('RM $itemPrice',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    const SizedBox(height: 4),
                    Text('with $otherPartyName',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
