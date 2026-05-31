import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/repositories/listing_repository.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';
import 'package:uniswap/viewmodels/explore_viewmodel.dart';
import 'package:uniswap/viewmodels/home_viewmodel.dart';

final createListingViewModelProvider =
    StateNotifierProvider<CreateListingViewModel, CreateListingState>((ref) {
  return CreateListingViewModel(ref.read(listingRepositoryProvider), ref);
});

class CreateListingState extends Equatable {
  const CreateListingState({
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.category,
    required this.images,
    required this.isSubmitting,
    required this.errorMessage,
    required this.isSuccess,
  });

  final String title;
  final String description;
  final String price;
  final String condition;
  final String category;
  final List<String> images;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  factory CreateListingState.initial() {
    return const CreateListingState(
      title: '',
      description: '',
      price: '',
      condition: 'Good',
      category: 'General',
      images: [],
      isSubmitting: false,
      errorMessage: null,
      isSuccess: false,
    );
  }

  CreateListingState copyWith({
    String? title,
    String? description,
    String? price,
    String? condition,
    String? category,
    List<String>? images,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return CreateListingState(
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      images: images ?? this.images,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        price,
        condition,
        category,
        images,
        isSubmitting,
        errorMessage,
        isSuccess,
      ];
}

class CreateListingViewModel extends StateNotifier<CreateListingState> {
  CreateListingViewModel(this._repository, this._ref) : super(CreateListingState.initial());

  final ListingRepository _repository;
  final Ref _ref;

  void updateTitle(String value) => state = state.copyWith(title: value);

  void updateDescription(String value) => state = state.copyWith(description: value);

  void updatePrice(String value) => state = state.copyWith(price: value);

  void updateCondition(String value) => state = state.copyWith(condition: value);

  void updateCategory(String value) => state = state.copyWith(category: value);

  void clearStatus() => state = state.copyWith(errorMessage: null, isSuccess: false);

  Future<void> submit() async {
    final title = state.title.trim();
    final price = state.price.trim();
    final description = state.description.trim();

    if (title.isEmpty || price.isEmpty || description.isEmpty) {
      state = state.copyWith(errorMessage: 'Title, price, and description are required.');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null, isSuccess: false);

    try {
      final user = _ref.read(authStateProvider).valueOrNull;
      final sellerName = user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!.trim()
          : (user?.email ?? 'UTM Student');
      final imageUrl = state.images.isNotEmpty
          ? state.images.first
          : 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f';

      _repository.createListing(
        title: title,
        price: price.startsWith('RM') ? price : 'RM $price',
        condition: state.condition,
        category: state.category,
        description: description,
        imageUrl: imageUrl,
        sellerName: sellerName,
      );

      await _ref.read(homeViewModelProvider.notifier).refresh();
      await _ref.read(exploreViewModelProvider.notifier).refresh();

      state = CreateListingState.initial().copyWith(isSuccess: true);
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to publish listing.');
    }
  }
}
