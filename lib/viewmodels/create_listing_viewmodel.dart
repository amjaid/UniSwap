import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final createListingViewModelProvider =
    StateNotifierProvider<CreateListingViewModel, CreateListingState>((ref) {
  return CreateListingViewModel();
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
  });

  final String title;
  final String description;
  final String price;
  final String condition;
  final String category;
  final List<String> images;
  final bool isSubmitting;

  factory CreateListingState.initial() {
    return const CreateListingState(
      title: '',
      description: '',
      price: '',
      condition: 'Good',
      category: 'General',
      images: [],
      isSubmitting: false,
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
  }) {
    return CreateListingState(
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      images: images ?? this.images,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [title, description, price, condition, category, images, isSubmitting];
}

class CreateListingViewModel extends StateNotifier<CreateListingState> {
  CreateListingViewModel() : super(CreateListingState.initial());

  void updateTitle(String value) => state = state.copyWith(title: value);

  void updateDescription(String value) => state = state.copyWith(description: value);

  void updatePrice(String value) => state = state.copyWith(price: value);

  void updateCondition(String value) => state = state.copyWith(condition: value);

  void updateCategory(String value) => state = state.copyWith(category: value);
}
