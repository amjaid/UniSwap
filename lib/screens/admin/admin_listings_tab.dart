import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/services/providers.dart';

/// Admin listings tab — list all items with search/filter and soft-delete.
///
/// Shows: title, seller, price, status, date.
/// Action: 🗑️ Delete (with confirmation dialog).
class AdminListingsTab extends ConsumerStatefulWidget {
  const AdminListingsTab({super.key});

  @override
  ConsumerState<AdminListingsTab> createState() => _AdminListingsTabState();
}

class _AdminListingsTabState extends ConsumerState<AdminListingsTab> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _items = [];
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final adminService = ref.read(adminServiceProvider);
    final response = await adminService.getItems(
      page: _currentPage,
      status: _statusFilter,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final data = response.data;
      final results = data?['results'] as List<dynamic>? ?? [];
      setState(() {
        _items = refresh ? results : [..._items, ...results];
        _isLoading = false;
        _hasMore = results.length >= 20;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Failed to load items.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    final adminService = ref.read(adminServiceProvider);
    final response = await adminService.getItems(
      page: _currentPage,
      status: _statusFilter,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final data = response.data;
      final results = data?['results'] as List<dynamic>? ?? [];
      setState(() {
        _items.addAll(results);
        _isLoadingMore = false;
        _hasMore = results.length >= 20;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

  Future<void> _deleteItem(int itemId, String itemTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete "$itemTitle"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final adminService = ref.read(adminServiceProvider);
    final response = await adminService.deleteItem(itemId);

    if (!mounted) return;

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted.')),
      );
      _loadItems(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Failed to delete listing.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _loadItems(refresh: true);
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _statusFilter = value;
    });
    _loadItems(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Status filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _statusFilter == null,
                onSelected: () => _onStatusFilterChanged(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Available',
                selected: _statusFilter == 'available',
                onSelected: () => _onStatusFilterChanged('available'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Sold',
                selected: _statusFilter == 'sold',
                onSelected: () => _onStatusFilterChanged('sold'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pending',
                selected: _statusFilter == 'pending',
                onSelected: () => _onStatusFilterChanged('pending'),
              ),
            ],
          ),
        ),

        // Item list
        Expanded(
          child: _buildItemList(),
        ),
      ],
    );
  }

  Widget _buildItemList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadItems(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text('No listings found.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification && _hasMore) {
          _loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _loadItems(refresh: true),
        child: ListView.separated(
          itemCount: _items.length + (_hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final item = _items[index] as Map<String, dynamic>;
            return _ItemListTile(
              item: item,
              onDelete: () => _deleteItem(
                item['id'] as int,
                item['title'] as String? ?? 'Unknown',
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ItemListTile extends StatelessWidget {
  const _ItemListTile({
    required this.item,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? 'No title';
    final price = item['price'] as String? ?? '0.00';
    final status = item['status'] as String? ?? 'unknown';
    final createdAt = item['created_at'] as String? ?? '';
    final seller = item['seller'] as Map<String, dynamic>?;
    final sellerName = seller?['name'] as String? ?? seller?['email'] as String? ?? 'Unknown';

    final statusColor = switch (status) {
      'available' => Colors.green,
      'sold' => Colors.grey,
      'pending' => Colors.orange,
      _ => Colors.grey,
    };

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.inventory_2, color: Colors.grey),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seller: $sellerName',
              style: Theme.of(context).textTheme.bodySmall),
          if (createdAt.isNotEmpty)
            Text(
              'Created: ${_formatDate(createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$$price',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete listing',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
