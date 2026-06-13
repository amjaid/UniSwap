import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/services/item_service.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/utils/image_utils.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(listingRepositoryProvider);
    final chatService = ref.read(chatServiceProvider);
    final transactionService = ref.read(transactionServiceProvider);
    final itemService = ref.read(itemServiceProvider);
    final user = ref.watch(authStateProvider);
    final listing = repository.getById(listingId);

    // Check if the current user is the seller
    final currentUserId = user?['id'] as int?;
    final isSeller = currentUserId != null &&
        listing != null &&
        listing.sellerId != null &&
        currentUserId == listing.sellerId;

    // Check if item is available for purchase
    final isAvailable = listing != null;

    // Local non-null listing reference for use inside callbacks
    final currentListing = listing;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (isSeller && currentListing != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  // Navigate to edit screen; refresh listing on return
                  final result = await context.push<Listing>(
                    '/listing/${currentListing.id}/edit',
                    extra: currentListing,
                  );
                  if (result != null && context.mounted) {
                    // Refresh the listing data
                    final itemId = int.tryParse(listingId);
                    if (itemId != null) {
                      await itemService.fetchItem(itemId);
                    }
                  }
                } else if (value == 'delete') {
                  await _confirmDelete(context, currentListing, itemService);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.redAccent),
                    title: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              getFullImageUrl(listing?.imageUrl),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.photo, size: 64),
            ),
          ),
          const SizedBox(height: 16),
          Text(listing?.title ?? 'Listing',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(listing?.price ?? 'RM --',
              style: Theme.of(context).textTheme.titleMedium),
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
              CircleAvatar(
                backgroundImage: listing?.sellerAvatarUrl != null
                    ? NetworkImage(listing!.sellerAvatarUrl!)
                    : null,
                child: listing?.sellerAvatarUrl == null
                    ? Text((listing!.sellerName.isNotEmpty == true
                            ? listing.sellerName[0]
                            : 'S')
                        .toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing?.sellerName ?? 'Seller'),
                    const SizedBox(height: 4),
                    const Text('University Member'),
                  ],
                ),
              ),
              if (!isSeller) ...[
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
                                  const SnackBar(
                                      content: Text('Please sign in to chat.')),
                                );
                                context.go('/sign-in');
                              }
                              return;
                            }

                            final sellerId = listing.sellerId;
                            if (sellerId == null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Cannot start chat: seller not found.')),
                                );
                              }
                              return;
                            }

                            try {
                              final chatId = await chatService.getOrCreateChatId(
                                participantId: sellerId,
                              );
                              if (chatId != null && context.mounted) {
                                context.pushNamed(
                                  'chat',
                                  pathParameters: {'chatId': chatId.toString()},
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to open chat.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open chat. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Chat'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            listing?.description ??
                'Includes notes and highlights. Pickup at UTM library or COD nearby campus.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          // Buy Now button (only for non-sellers when item is available)
          if (!isSeller && isAvailable)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (user == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please sign in to make a purchase.')),
                      );
                      context.go('/sign-in');
                    }
                    return;
                  }

                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Purchase'),
                      content: Text(
                        'Are you sure you want to purchase "${listing.title}" for ${listing.price}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  final itemId = int.tryParse(listingId);
                  if (itemId == null) return;

                  try {
                    final response =
                        await transactionService.createTransaction(itemId);
                    if (context.mounted) {
                      if (response.isSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Purchase initiated! Check your transaction history.'),
                          ),
                        );
                        // Navigate to transaction history
                        context.go('/swap-hub');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                response.error ?? 'Failed to create transaction.'),
                          ),
                        );
                      }
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to create transaction.'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Buy Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog and delete the listing if confirmed.
  Future<void> _confirmDelete(
    BuildContext context,
    Listing listing,
    ItemService itemService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing'),
        content: const Text(
          'Are you sure you want to delete this listing? '
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

    final itemId = int.tryParse(listing.id);
    if (itemId == null) return;

    final response = await itemService.deleteItem(itemId);

    if (context.mounted) {
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted.')),
        );
        // Navigate to home instead of pop, since the listing detail
        // may have been navigated to via go() (no route to pop to).
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to delete listing.'),
          ),
        );
      }
    }
  }
}
