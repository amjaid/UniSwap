import 'dart:io' as io;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniswap/viewmodels/create_listing_viewmodel.dart';

class CreateListingScreen extends ConsumerWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createListingViewModelProvider);
    final viewModel = ref.read(createListingViewModelProvider.notifier);

    ref.listen<CreateListingState>(createListingViewModelProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        viewModel.clearStatus();
      }

      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing published.')),
        );
        viewModel.clearStatus();
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create listing')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('Add photos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                // Show the selected image in the first slot, or empty slots
                if (index == 0 && state.imageFile != null) {
                  return GestureDetector(
                    onTap: () => _pickImage(viewModel),
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: _resolveImageProvider(state.imageFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: viewModel.clearImage,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Empty slot - tap to pick image
                return GestureDetector(
                  onTap: () => _pickImage(viewModel),
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: 3,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: viewModel.updateTitle,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: viewModel.updatePrice,
            decoration: const InputDecoration(labelText: 'Price (RM)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: state.condition,
            items: const [
              DropdownMenuItem(value: 'Like New', child: Text('Like New')),
              DropdownMenuItem(value: 'Good', child: Text('Good')),
              DropdownMenuItem(value: 'Used', child: Text('Used')),
            ],
            onChanged: (value) => viewModel.updateCondition(value ?? 'Good'),
            decoration: const InputDecoration(labelText: 'Condition'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: state.category,
            items: const [
              DropdownMenuItem(value: 'General', child: Text('General')),
              DropdownMenuItem(value: 'Textbooks', child: Text('Textbooks')),
              DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
              DropdownMenuItem(value: 'Clothing', child: Text('Clothing')),
            ],
            onChanged: (value) => viewModel.updateCategory(value ?? 'General'),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: viewModel.updateDescription,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: state.isSubmitting ? null : viewModel.submit,
            child: state.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publish listing'),
          ),
        ],
      ),
    );
  }

  /// Resolve an [ImageProvider] from an [XFile].
  ///
  /// On web, [XFile.path] is a blob URL that can be used directly.
  /// On native platforms, [XFile.path] is a file system path.
  ImageProvider _resolveImageProvider(XFile file) {
    if (kIsWeb) {
      // On web, the path is a blob URL that NetworkImage can load
      return NetworkImage(file.path);
    }
    // On native, use FileImage for local file system access
    return FileImage(io.File(file.path));
  }

  Future<void> _pickImage(CreateListingViewModel viewModel) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      // Use the XFile directly (works on all platforms including web)
      viewModel.setImageFile(pickedFile, pickedFile.path);
    }
  }
}
