import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/repositories/listing_repository.dart';

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository();
});

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref.read(listingRepositoryProvider));
});

class HomeState extends Equatable {
  const HomeState({
    required this.featuredListings,
    required this.nearbyListings,
    required this.selectedCategory,
    required this.isLoading,
    required this.searchQuery,
  });

  final List<Listing> featuredListings;
  final List<Listing> nearbyListings;
  final String selectedCategory;
  final bool isLoading;
  final String searchQuery;

  factory HomeState.initial() {
    return const HomeState(
      featuredListings: [],
      nearbyListings: [],
      selectedCategory: 'All',
      isLoading: true,
      searchQuery: '',
    );
  }

  HomeState copyWith({
    List<Listing>? featuredListings,
    List<Listing>? nearbyListings,
    String? selectedCategory,
    bool? isLoading,
    String? searchQuery,
  }) {
    return HomeState(
      featuredListings: featuredListings ?? this.featuredListings,
      nearbyListings: nearbyListings ?? this.nearbyListings,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [featuredListings, nearbyListings, selectedCategory, isLoading, searchQuery];
}

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._repository) : super(HomeState.initial()) {
    _load();
  }

  final ListingRepository _repository;

  Future<void> _load() async {
    final featured = await _repository.fetchFeatured();
    final nearby = await _repository.fetchNearby();
    state = state.copyWith(
      featuredListings: featured,
      nearbyListings: nearby,
      isLoading: false,
    );
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
