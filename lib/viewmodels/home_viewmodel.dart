import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/repositories/listing_repository.dart';
import 'package:uniswap/services/providers.dart';

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref.read(listingRepositoryProvider));
});

class HomeState extends Equatable {
  const HomeState({
    required this.allListings,
    required this.featuredListings,
    required this.nearbyListings,
    required this.selectedCategory,
    required this.isLoading,
    required this.searchQuery,
  });

  final List<Listing> allListings;
  final List<Listing> featuredListings;
  final List<Listing> nearbyListings;
  final String selectedCategory;
  final bool isLoading;
  final String searchQuery;

  factory HomeState.initial() {
    return const HomeState(
      allListings: [],
      featuredListings: [],
      nearbyListings: [],
      selectedCategory: 'All',
      isLoading: true,
      searchQuery: '',
    );
  }

  HomeState copyWith({
    List<Listing>? allListings,
    List<Listing>? featuredListings,
    List<Listing>? nearbyListings,
    String? selectedCategory,
    bool? isLoading,
    String? searchQuery,
  }) {
    return HomeState(
      allListings: allListings ?? this.allListings,
      featuredListings: featuredListings ?? this.featuredListings,
      nearbyListings: nearbyListings ?? this.nearbyListings,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        allListings,
        featuredListings,
        nearbyListings,
        selectedCategory,
        isLoading,
        searchQuery,
      ];
}

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._repository) : super(HomeState.initial()) {
    _load();
  }

  final ListingRepository _repository;

  Future<void> _load() async {
    final all = _repository.getAll();
    final featured = await _repository.fetchFeatured(
      category: state.selectedCategory,
      query: state.searchQuery,
    );
    final nearby = await _repository.fetchNearby(
      category: state.selectedCategory,
      query: state.searchQuery,
    );
    state = state.copyWith(
      allListings: all,
      featuredListings: featured,
      nearbyListings: nearby,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _repository.refresh();
    await _load();
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _load();
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _load();
  }
}
