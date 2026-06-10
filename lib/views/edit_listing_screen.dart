import 'dart:io' as io;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/services/item_service.dart';
import 'package:uniswap/services/providers.dart';

/// Screen for editing an existing item listing.
///
/// Pre-populates all fields with the existing listing data.
/// Supports updating text fields, changing category/condition,
/// and adding new images.
class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late String _condition;
  late String _category;
  XFile? _newImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Map display names to backend values
  static const _conditionOptions = ['Like New', 'Good', 'Used'];
  static const _categoryOptions = ['General', 'Textbooks', 'Electronics', 'Clothing'];

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    _titleController = TextEditingController(text: listing.title);
    _priceController = TextEditingController(
      text: listing.price.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    _descriptionController = TextEditingController(text: listing.description);
    _condition = listing.condition;
    _category = listing.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemService = ref.read(itemServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit listing')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ── Image section ──
          Text('Photo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                // Slot 0: existing image or new image
                if (index == 0) {
                  if (_newImage != null) {
                    // Show newly picked image
                    return GestureDetector(
                      onTap: () => _pickImage(),
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: _resolveImageProvider(_newImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _newImage = null),
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

                  // Show existing image from listing
                  if (widget.listing.imageUrl.isNotEmpty) {
                    return GestureDetector(
                      onTap: () => _pickImage(),
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(widget.listing.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // No image - show add button
                  return GestureDetector(
                    onTap: () => _pickImage(),
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
                }

                // Empty slot
                return GestureDetector(
                  onTap: () => _pickImage(),
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
              itemCount: 2,
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),

          // ── Price ──
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price (RM)'),
          ),
          const SizedBox(height: 12),

          // ── Condition ──
          DropdownButtonFormField<String>(
            initialValue: _condition,
            items: _conditionOptions
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) => setState(() => _condition = value ?? 'Good'),
            decoration: const InputDecoration(labelText: 'Condition'),
          ),
          const SizedBox(height: 12),

          // ── Category ──
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: _categoryOptions
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) => setState(() => _category = value ?? 'General'),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),

          // ── Description ──
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 20),

          // ── Error message ──
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],

          // ── Save button ──
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () => _save(itemService),
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  /// Resolve an [ImageProvider] from an [XFile].
  ImageProvider _resolveImageProvider(XFile file) {
    if (kIsWeb) {
      return NetworkImage(file.path);
    }
    return FileImage(io.File(file.path));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _newImage = pickedFile);
    }
  }

  Future<void> _save(ItemService itemService) async {
    final title = _titleController.text.trim();
    final priceStr = _priceController.text.trim();
    final description = _descriptionController.text.trim();

    // Validate
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Title is required.');
      return;
    }
    final price = double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (price == null || price <= 0) {
      setState(() => _errorMessage = 'Please enter a valid price.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final itemId = int.tryParse(widget.listing.id);
      if (itemId == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Invalid listing ID.';
        });
        return;
      }

      final response = await itemService.updateItem(
        itemId,
        title: title,
        description: description,
        price: price,
        condition: _condition,
        category: _categoryNameToId(_category),
        newImages: _newImage != null ? [_newImage!] : null,
      );

      if (response.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing updated.')),
        );
        context.pop(true); // pop with result = true to signal refresh
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = response.error ?? 'Failed to update listing.';
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'An unexpected error occurred.';
      });
    }
  }

  int _categoryNameToId(String name) {
    const categories = {
      'General': 1,
      'Textbooks': 2,
      'Electronics': 3,
      'Clothing': 4,
    };
    return categories[name] ?? 1;
  }
}
