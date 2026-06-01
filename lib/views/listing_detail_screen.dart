import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';
import 'package:uniswap/viewmodels/home_viewmodel.dart';
import 'package:uniswap/viewmodels/swap_hub_viewmodel.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(listingRepositoryProvider);
    final swapRepository = ref.read(swapRepositoryProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
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
          Row(
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing?.sellerName ?? 'Seller'),
                    const SizedBox(height: 4),
                    const Text('UTM Johor'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: listing == null
                      ? null
                      : () async {
                          if (user == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please sign in to chat.')),
                              );
                              context.go('/sign-in');
                            }
                            return;
                          }

                          final conversationId = 'listing_$listingId';
                          final otherUserId = 'seller_$listingId';
                          final otherUserName = listing.sellerName;
                          String id = conversationId;

                          try {
                            id = await firestoreService.ensureListingConversation(
                              conversationId: conversationId,
                              userId: user.uid,
                              otherUserId: otherUserId,
                              otherUserName: otherUserName,
                            );
                          } catch (_) {
                            id = conversationId;
                          }

                          if (context.mounted) {
                            context.pushNamed(
                              'chat',
                              pathParameters: {'swapId': id},
                            );
                          }
                        },
                  child: const Text('Chat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            listing?.description ??
                'Includes notes and highlights. Pickup at UTM library or COD nearby campus.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: listing == null
                ? null
                : () {
                    final swap = swapRepository.createSwap(
                      title: listing.title,
                      imageUrl: listing.imageUrl,
                      otherUserName: listing.sellerName,
                      otherUserContact: 'seller@utm.my',
                    );
                    context.go('/swap-hub/${swap.id}');
                  },
            child: const Text('Start swap'),
          ),
        ],
      ),
    );
  }
}
