import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authService = ref.read(authServiceProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () => context.go('/settings'), icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 44,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e'),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.verified, color: AppColors.primary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(user?.displayName ?? 'Siti Aisyah', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(user?.email ?? 'utm@utm.my', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 4),
                  Text('4.9'),
                  SizedBox(width: 6),
                  Text('(12 reviews)'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StatCard(label: 'Sold', value: '24'),
              _StatCard(label: 'Swapped', value: '8'),
              _StatCard(label: 'Active', value: '3'),
            ],
          ),
          const SizedBox(height: 18),
          DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TabBar(
                  labelColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Active Listings'),
                    Tab(text: 'Sold'),
                    Tab(text: 'Reviews'),
                  ],
                ),
                const SizedBox(
                  height: 240,
                  child: TabBarView(
                    children: [
                      _ProfileListingsGrid(),
                      Center(child: Text('No sold items yet.')),
                      Center(child: Text('No reviews yet.')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.bookmark_border,
            label: 'Saved listings',
            onTap: () => context.go('/saved'),
          ),
          _ActionTile(
            icon: Icons.report_gmailerrorred_outlined,
            label: 'Report an issue',
            onTap: () => context.go('/report/app/support'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await authService.signOut();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ProfileListingsGrid extends StatelessWidget {
  const _ProfileListingsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.78,
      padding: const EdgeInsets.only(top: 12),
      children: const [
        _MiniListingCard(title: 'Calculus Textbook', price: 'RM 45', tag: 'Good'),
        _MiniListingCard(title: 'Vintage Denim Jacket', price: 'RM 55', tag: 'Swap'),
        _MiniListingCard(title: 'Desk Lamp', price: 'RM 20', tag: 'Good'),
        _MiniListingCard(title: 'Headphones', price: 'RM 120', tag: 'Swap'),
      ],
    );
  }
}

class _MiniListingCard extends StatelessWidget {
  const _MiniListingCard({required this.title, required this.price, required this.tag});

  final String title;
  final String price;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.grey.withAlpha(30),
              ),
              child: const Center(child: Icon(Icons.photo, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Chip(label: Text(tag, style: const TextStyle(fontSize: 11))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
