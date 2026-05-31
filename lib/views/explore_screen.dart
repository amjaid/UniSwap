import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/viewmodels/explore_viewmodel.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreViewModelProvider);
    final viewModel = ref.read(exploreViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Explore', style: Theme.of(context).textTheme.displaySmall),
                IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: viewModel.updateQuery,
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.sort, size: 18),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: state.sortBy,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'Popular', child: Text('Popular')),
                    DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
                    DropdownMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
                  ],
                  onChanged: (value) {
                    if (value != null) viewModel.setSort(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Trending', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final tag = state.trendingSearches[index];
                  return ActionChip(
                    label: Text(tag),
                    onPressed: () => viewModel.applyTrending(tag),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: state.trendingSearches.length,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: state.filterCategory == 'All',
                  onTap: () => viewModel.setFilter('All'),
                ),
                _FilterChip(
                  label: 'Textbooks',
                  selected: state.filterCategory == 'Textbooks',
                  onTap: () => viewModel.setFilter('Textbooks'),
                ),
                _FilterChip(
                  label: 'Electronics',
                  selected: state.filterCategory == 'Electronics',
                  onTap: () => viewModel.setFilter('Electronics'),
                ),
                _FilterChip(
                  label: 'Clothing',
                  selected: state.filterCategory == 'Clothing',
                  onTap: () => viewModel.setFilter('Clothing'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.searchResults.isEmpty ? 4 : state.searchResults.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final listing = state.searchResults.isEmpty ? null : state.searchResults[index];
                return _ExploreCard(
                  listing: listing,
                  onTap: listing == null ? null : () => context.go('/listing/${listing.id}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.listing, this.onTap});

  final Listing? listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (listing == null) {
      return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(listing!.imageUrl, height: 90, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(listing!.price, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
