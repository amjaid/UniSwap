import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/repositories/listing_repository.dart';

final exploreViewModelProvider = StateNotifierProvider<ExploreViewModel, ExploreState>((ref) {
  return ExploreViewModel(ref.read(listingRepositoryProvider));
});

class ExploreState extends Equatable {
  const ExploreState({
    required this.trendingSearches,
    required this.searchResults,
    required this.sortBy,
    required this.filterCategory,
    required this.isLoading,
    required this.hasMore,
  });

  final List<String> trendingSearches;
  final List<Listing> searchResults;
  final String sortBy;
  final String filterCategory;
  final bool isLoading;
  final bool hasMore;

  factory ExploreState.initial() {
    return const ExploreState(
      trendingSearches: ['Textbooks', 'Headphones', 'Jackets', 'Laptops'],
      searchResults: [],
      sortBy: 'Popular',
      filterCategory: 'All',
      isLoading: true,
      hasMore: true,
    );
  }

  ExploreState copyWith({
    List<String>? trendingSearches,
    List<Listing>? searchResults,
    String? sortBy,
    String? filterCategory,
    bool? isLoading,
    bool? hasMore,
  }) {
    return ExploreState(
      trendingSearches: trendingSearches ?? this.trendingSearches,
      searchResults: searchResults ?? this.searchResults,
      sortBy: sortBy ?? this.sortBy,
      filterCategory: filterCategory ?? this.filterCategory,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [trendingSearches, searchResults, sortBy, filterCategory, isLoading, hasMore];
}

class ExploreViewModel extends StateNotifier<ExploreState> {
  ExploreViewModel(this._repository) : super(ExploreState.initial()) {
    _load();
  }

  final ListingRepository _repository;

  Future<void> _load() async {
    final results = await _repository.search();
    state = state.copyWith(searchResults: results, isLoading: false);
  }

  void setFilter(String category) {
    state = state.copyWith(filterCategory: category);
  }
}
