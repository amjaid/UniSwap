import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/services/api_client.dart';
import 'package:uniswap/services/django_auth_service.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/utils/image_utils.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _promptedForUsername = false;
  List<Listing> _userListings = [];
  bool _listingsLoaded = false;

  /// Resolve an avatar URL, prepending the base URL if it's a relative path.
  ///
  /// The Django backend may return a relative URL like `/media/avatars/foo.jpg`
  /// instead of a full URL. This method ensures the URL is absolute so that
  /// `NetworkImage` can load it correctly.
  String _resolveAvatarUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Prepend the API base URL (strip the /api suffix)
    final base = ApiClient.defaultBaseUrl;
    final baseUrl = base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
    return '$baseUrl${url.startsWith('/') ? url : '/$url'}';
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(djangoAuthServiceProvider);
    final listingRepo = ref.read(listingRepositoryProvider);
    final user = ref.watch(authStateProvider);
    final userId = user?['id']?.toString();

    // Fetch user's listings once
    if (!_listingsLoaded) {
      _listingsLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final all = listingRepo.getAll();
        setState(() => _userListings = all);
      });
    }

    if (user != null && !_promptedForUsername) {
      final name = (user['name'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        _promptedForUsername = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSetUsernameDialog(context, userId ?? '', authService);
        });
      }
    }

    final fullName = (user?['name'] as String?)?.trim();
    final username = (user?['username'] as String?)?.trim() ?? (user?['name'] as String?);
    final rawPhotoUrl = (user?['avatar_url'] as String?)?.trim() ?? '';
    final photoUrl = _resolveAvatarUrl(rawPhotoUrl);
    final email = (user?['email'] as String?)?.trim();

    // Compute stats from user's listings
    final activeCount = _userListings.length;
    final soldCount = 0; // Backend doesn't expose this yet; placeholder

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
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.grey.withAlpha(30),
                    backgroundImage: photoUrl.isEmpty
                        ? null
                        : NetworkImage(photoUrl) as ImageProvider,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: userId == null
                          ? null
                          : () => _changeProfilePhoto(
                                context,
                                authService,
                              ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(fullName ?? 'UTM Student', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: userId == null
                        ? null
                        : () => _showEditUsernameDialog(
                              context,
                              username ?? '',
                              userId,
                              authService,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                username == null || username.isEmpty ? 'Set a username' : '@$username',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(email ?? 'utm@utm.my', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 4),
                  Text('--'),
                  SizedBox(width: 6),
                  Text('(no ratings yet)'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCard(label: 'Listings', value: activeCount.toString()),
              _StatCard(label: 'Sold', value: soldCount.toString()),
              _StatCard(label: 'Active', value: activeCount.toString()),
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
                SizedBox(
                  height: 260,
                  child: TabBarView(
                    children: [
                      _ProfileListingsGrid(listings: _userListings),
                      const Center(child: Text('No sold items yet.')),
                      const Center(child: Text('No reviews yet.')),
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
              await authService.logout();
              // Clear auth state so the router redirects to /sign-in
              clearAuthState(ref);
              if (context.mounted) {
                context.go('/sign-in');
              }
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

Future<void> _showEditUsernameDialog(
  BuildContext context,
  String currentUsername,
  String userId,
  DjangoAuthService authService,
) async {
  final controller = TextEditingController(text: currentUsername);

  await showDialog<void>(
    context: context,
    builder: (context) {
      var isSaving = false;
      String? errorMessage;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit username'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    helperText: '3-20 characters, letters, numbers, or _.',
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final nextUsername = controller.text.trim();
                        if (!_isValidUsername(nextUsername)) {
                          setState(() => errorMessage =
                              'Username must be 3-20 characters, letters, numbers, or _.');
                          return;
                        }

                        setState(() {
                          isSaving = true;
                          errorMessage = null;
                        });

                        try {
                          final response = await authService.updateProfile(
                            name: nextUsername,
                          );
                          if (response.isSuccess) {
                            if (context.mounted) Navigator.of(context).pop();
                          } else {
                            setState(() {
                              isSaving = false;
                              errorMessage = response.error ?? 'Could not update username.';
                            });
                          }
                        } catch (_) {
                          setState(() {
                            isSaving = false;
                            errorMessage = 'Could not update username.';
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _changeProfilePhoto(
  BuildContext context,
  DjangoAuthService authService,
) async {
  final picker = ImagePicker();

  try {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image == null) return;

    // Send the avatar file directly as a multipart PATCH to /users/me/
    // The backend UserDetailSerializer handles saving to the avatar ImageField
    // and updating avatar_url accordingly.
    final response = await authService.updateProfile(avatarFile: image);

    if (response.isSuccess) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated.')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Could not update profile photo.')),
        );
      }
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update profile photo.')),
      );
    }
  }
}

Future<void> _showSetUsernameDialog(
  BuildContext context,
  String userId,
  DjangoAuthService authService,
) async {
  final controller = TextEditingController();

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      var isSaving = false;
      String? errorMessage;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Choose a username'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create a unique username so others can find you.'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    helperText: '3-20 characters, letters, numbers, or _.',
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final nextUsername = controller.text.trim();
                        if (!_isValidUsername(nextUsername)) {
                          setState(() => errorMessage =
                              'Username must be 3-20 characters, letters, numbers, or _.');
                          return;
                        }

                        setState(() {
                          isSaving = true;
                          errorMessage = null;
                        });

                        try {
                          final response = await authService.updateProfile(
                            name: nextUsername,
                          );
                          if (response.isSuccess) {
                            if (context.mounted) Navigator.of(context).pop();
                          } else {
                            setState(() {
                              isSaving = false;
                              errorMessage = response.error ?? 'Could not update username.';
                            });
                          }
                        } catch (_) {
                          setState(() {
                            isSaving = false;
                            errorMessage = 'Could not update username.';
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

bool _isValidUsername(String username) {
  final trimmed = username.trim();
  return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(trimmed);
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
  const _ProfileListingsGrid({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const Center(child: Text('No listings yet.'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      padding: const EdgeInsets.only(top: 12),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return _MiniListingCard(
          title: listing.title,
          price: listing.price,
          tag: listing.condition,
          listing: listing,
        );
      },
    );
  }
}

class _MiniListingCard extends ConsumerWidget {
  const _MiniListingCard({
    required this.title,
    required this.price,
    required this.tag,
    this.listing,
  });

  final String title;
  final String price;
  final String tag;
  final Listing? listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemService = ref.read(itemServiceProvider);

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
            child: Stack(
              children: [
                // Show the listing image if available, otherwise a placeholder
                if (listing?.imageUrl.isNotEmpty == true)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: NetworkImage(getFullImageUrl(listing!.imageUrl)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.grey.withAlpha(30),
                    ),
                    child: const Center(child: Icon(Icons.photo, color: Colors.grey)),
                  ),
                // Three-dot menu for edit/delete
                if (listing != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.more_vert, size: 18, color: Colors.white),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          if (context.mounted) {
                            await context.push<Listing>(
                              '/listing/${listing!.id}/edit',
                              extra: listing,
                            );
                          }
                        } else if (value == 'delete') {
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

                          if (confirmed == true) {
                            final itemId = int.tryParse(listing!.id);
                            if (itemId != null) {
                              final response = await itemService.deleteItem(itemId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response.isSuccess
                                          ? 'Listing deleted.'
                                          : (response.error ?? 'Failed to delete listing.'),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, size: 18),
                            title: Text('Edit', style: TextStyle(fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            title: Text('Delete', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
