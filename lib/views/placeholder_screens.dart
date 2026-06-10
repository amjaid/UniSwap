import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/utils/image_utils.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.swapOrange,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('UniSwap', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}


class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('User #$userId', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              user?['email'] as String? ?? 'university.edu',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class SavedListingsScreen extends ConsumerWidget {
  const SavedListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingRepo = ref.read(listingRepositoryProvider);
    final listings = listingRepo.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved listings')),
      body: listings.isEmpty
          ? const Center(child: Text('No saved listings yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      getFullImageUrl(listing.imageUrl),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.photo),
                    ),
                  ),
                  title: Text(listing.title),
                  subtitle: Text(listing.price),
                );
              },
            ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final email = (user?['email'] as String?)?.trim() ?? 'university.edu';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Push notifications'),
            subtitle: const Text('Receive alerts for messages and offers'),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Use dark theme'),
            value: false,
            onChanged: (_) {},
          ),
          const Divider(),
          const SizedBox(height: 12),
          const Text('About', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.targetType, required this.targetId});

  final String targetType;
  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report $targetType',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text('Describe the issue you encountered:'),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tell us what happened...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted. Thank you.')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Submit report'),
            ),
          ],
        ),
      ),
    );
  }
}
