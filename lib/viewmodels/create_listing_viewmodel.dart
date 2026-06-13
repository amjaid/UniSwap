import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:uniswap/repositories/listing_repository.dart';
import 'package:uniswap/services/django_storage_service.dart';
import 'package:uniswap/services/providers.dart';

final createListingViewModelProvider =
    StateNotifierProvider<CreateListingViewModel, CreateListingState>((ref) {
  return CreateListingViewModel(
    ref.read(listingRepositoryProvider),
    ref.read(storageServiceProvider),
  );
});

class CreateListingState extends Equatable {
  const CreateListingState({
    required this.title,
    required this.price,
    required this.condition,
    required this.category,
    required this.description,
    required this.imageFile,
    required this.imagePreviewUrl,
    required this.isSubmitting,
    required this.errorMessage,
    required this.isSuccess,
  });

  final String title;
  final String price;
  final String condition;
  final String category;
  final String description;
  final XFile? imageFile;
  final String imagePreviewUrl;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  factory CreateListingState.initial() {
    return const CreateListingState(
      title: '',
      price: '',
      condition: 'Good',
      category: 'General',
      description: '',
      imageFile: null,
      imagePreviewUrl: '',
      isSubmitting: false,
      errorMessage: null,
      isSuccess: false,
    );
  }

  CreateListingState copyWith({
    String? title,
    String? price,
    String? condition,
    String? category,
    String? description,
    XFile? imageFile,
    String? imagePreviewUrl,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return CreateListingState(
      title: title ?? this.title,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      description: description ?? this.description,
      imageFile: imageFile ?? this.imageFile,
      imagePreviewUrl: imagePreviewUrl ?? this.imagePreviewUrl,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        title,
        price,
        condition,
        category,
        description,
        imageFile,
        imagePreviewUrl,
        isSubmitting,
        errorMessage,
        isSuccess,
      ];
}

class CreateListingViewModel extends StateNotifier<CreateListingState> {
  CreateListingViewModel(this._repository, this._storageService)
      : super(CreateListingState.initial());

  final ListingRepository _repository;
  final DjangoStorageService _storageService;

  void updateTitle(String value) => state = state.copyWith(title: value);
  void updatePrice(String value) => state = state.copyWith(price: value);
  void updateCondition(String value) => state = state.copyWith(condition: value);
  void updateCategory(String value) => state = state.copyWith(category: value);
  void updateDescription(String value) => state = state.copyWith(description: value);

  /// Set the image file to upload with the listing.
  ///
  /// Accepts an [XFile] from `image_picker` which works on all platforms
  /// (web, Android, iOS).
  void setImageFile(XFile file, String previewUrl) {
    state = state.copyWith(imageFile: file, imagePreviewUrl: previewUrl);
  }

  /// Clear the selected image.
  void clearImage() {
    state = state.copyWith(imageFile: null, imagePreviewUrl: '');
  }

  Future<void> submit() async {
    if (state.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Title is required.');
      return;
    }
    if (state.price.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Price is required.');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    // Step 1: Create the item (text fields only)
    final listing = await _repository.createListing(
      title: state.title.trim(),
      price: state.price.trim(),
      condition: state.condition,
      category: state.category,
      description: state.description.trim(),
      imageUrl: state.imagePreviewUrl,
      sellerName: 'You',
    );

    if (listing == null) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to create listing. Please try again.',
      );
      return;
    }

    // Step 2: Upload the image if one was selected
    if (state.imageFile != null) {
      final itemId = int.tryParse(listing.id);
      if (itemId != null) {
        await _storageService.uploadItemImage(
          itemId: itemId,
          file: state.imageFile!,
        );
      }
    }

    state = state.copyWith(isSubmitting: false, isSuccess: true);
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  /// Clears both error and success flags (called by the screen after showing a snackbar).
  void clearStatus() {
    state = state.copyWith(errorMessage: null, isSuccess: false);
  }

  void reset() => state = CreateListingState.initial();
}
