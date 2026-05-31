import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/viewmodels/home_viewmodel.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(listingRepositoryProvider);
    final listing = repository.getById(listingId);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              listing?.imageUrl ?? 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(listing?.title ?? 'Listing', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(listing?.price ?? 'RM --', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(listing?.condition ?? 'Good')),
              Chip(label: Text(listing?.category ?? 'General')),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e'),
            ),
            title: Text(listing?.sellerName ?? 'Seller'),
            subtitle: const Text('UTM Johor'),
            trailing: ElevatedButton(
              onPressed: () {},
              child: const Text('Chat'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            listing?.description ??
                'Includes notes and highlights. Pickup at UTM library or COD nearby campus.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Start swap'),
          ),
        ],
      ),
    );
  }
}
