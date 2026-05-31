import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';
import 'package:uniswap/viewmodels/home_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final profileAsync = user == null ? null : ref.watch(userProfileProvider(user.uid));
    final profileData = profileAsync?.valueOrNull ?? {};
    final username = (profileData['username'] as String?)?.trim();
    final fullName = (profileData['full_name'] as String?)?.trim();
    final greetingName = username?.isNotEmpty == true
        ? username!
        : (fullName?.isNotEmpty == true ? fullName! : (user?.displayName ?? 'there'));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-listing'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UniSwap', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('Hey, $greetingName', style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
                const CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: viewModel.updateSearch,
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(label: 'All', selected: state.selectedCategory == 'All', onTap: () => viewModel.selectCategory('All')),
                  _CategoryChip(label: 'Textbooks', selected: state.selectedCategory == 'Textbooks', onTap: () => viewModel.selectCategory('Textbooks')),
                  _CategoryChip(label: 'Electronics', selected: state.selectedCategory == 'Electronics', onTap: () => viewModel.selectCategory('Electronics')),
                  _CategoryChip(label: 'Clothing', selected: state.selectedCategory == 'Clothing', onTap: () => viewModel.selectCategory('Clothing')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Featured Listings', action: 'See all', onTap: () {}),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final listing = state.featuredListings.isEmpty ? null : state.featuredListings[index];
                  return _ListingCard(
                    listing: listing,
                    onTap: listing == null ? null : () => context.go('/listing/${listing.id}'),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: state.featuredListings.isEmpty ? 2 : state.featuredListings.length,
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Swap Offers Near You', action: 'See all', onTap: () {}),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.nearbyListings.isEmpty ? 4 : state.nearbyListings.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final listing = state.nearbyListings.isEmpty ? null : state.nearbyListings[index];
                return _ListingGridCard(
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, required this.onTap});

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, this.onTap});

  final Listing? listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (listing == null) {
      return _LoadingCard(width: 170);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(listing!.imageUrl, height: 110, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(listing!.price, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _ConditionChip(label: listing!.condition),
                      const SizedBox(width: 6),
                      Text(listing!.sellerName, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingGridCard extends StatelessWidget {
  const _ListingGridCard({required this.listing, this.onTap});

  final Listing? listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (listing == null) {
      return const _LoadingCard(width: double.infinity);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 6))],
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
                  const SizedBox(height: 4),
                  _ConditionChip(label: listing!.condition),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.swapOrange.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
