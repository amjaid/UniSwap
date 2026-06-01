import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/services/auth_service.dart';
import 'package:uniswap/services/firestore_service.dart';
import 'package:uniswap/services/storage_service.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _promptedForUsername = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final storageService = ref.read(storageServiceProvider);
    final user = authState.valueOrNull;
    final profileAsync = user == null ? null : ref.watch(userProfileProvider(user.uid));

    if (user != null && profileAsync?.valueOrNull != null && !_promptedForUsername) {
      final profile = profileAsync!.valueOrNull ?? {};
      final username = (profile['username'] as String?)?.trim();
      if (username == null || username.isEmpty) {
        _promptedForUsername = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSetUsernameDialog(
            context,
            user.uid,
            authService,
            firestoreService,
          );
        });
      }
    }

    final profileData = profileAsync?.valueOrNull ?? {};
    final fullName = (profileData['full_name'] as String?)?.trim();
    final username = (profileData['username'] as String?)?.trim() ?? user?.displayName;
    final photoUrl = (profileData['photo_url'] as String?)?.trim();

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
                    backgroundImage: photoUrl == null || photoUrl.isEmpty
                        ? null
                        : NetworkImage(photoUrl) as ImageProvider,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: user == null
                          ? null
                          : () => _changeProfilePhoto(
                                context,
                                user.uid,
                                storageService,
                                firestoreService,
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
                    onPressed: user == null
                        ? null
                        : () => _showEditUsernameDialog(
                              context,
                              username ?? '',
                              user.uid,
                              authService,
                              firestoreService,
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
                  height: 260,
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

Future<void> _showEditUsernameDialog(
  BuildContext context,
  String currentUsername,
  String userId,
  AuthService authService,
  FirestoreService firestoreService,
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
                          final normalized = nextUsername.toLowerCase();
                          if (normalized != currentUsername.toLowerCase()) {
                            final available = await firestoreService.isUsernameAvailable(
                              normalized,
                              currentUserId: userId,
                            );
                            if (!available) {
                              setState(() {
                                isSaving = false;
                                errorMessage = 'That username is already taken.';
                              });
                              return;
                            }
                          }

                          await firestoreService.updateUsername(userId: userId, username: normalized);
                          await authService.updateDisplayName(displayName: normalized);
                          if (context.mounted) Navigator.of(context).pop();
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
  String userId,
  StorageService storageService,
  FirestoreService firestoreService,
) async {
  final picker = ImagePicker();

  try {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final extension = image.name.split('.').last;
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final contentType = _contentTypeForExtension(extension);

    final url = await storageService.uploadProfileImage(
      userId: userId,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );

    await firestoreService.updateProfilePhoto(userId: userId, photoUrl: url);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update profile photo.')),
      );
    }
  }
}

String _contentTypeForExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    default:
      return 'image/jpeg';
  }
}

Future<void> _showSetUsernameDialog(
  BuildContext context,
  String userId,
  AuthService authService,
  FirestoreService firestoreService,
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
                          final normalized = nextUsername.toLowerCase();
                          final available = await firestoreService.isUsernameAvailable(
                            normalized,
                            currentUserId: userId,
                          );
                          if (!available) {
                            setState(() {
                              isSaving = false;
                              errorMessage = 'That username is already taken.';
                            });
                            return;
                          }

                          await firestoreService.updateUsername(userId: userId, username: normalized);
                          await authService.updateDisplayName(displayName: normalized);
                          if (context.mounted) Navigator.of(context).pop();
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
  const _ProfileListingsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.6,
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
