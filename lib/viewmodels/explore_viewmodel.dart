import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/listing.dart';
import 'package:uniswap/repositories/listing_repository.dart';
import 'package:uniswap/services/providers.dart';

final exploreViewModelProvider = StateNotifierProvider<ExploreViewModel, ExploreState>((ref) {
  return ExploreViewModel(ref.read(listingRepositoryProvider));
});

class ExploreState extends Equatable {
  const ExploreState({
    required this.trendingSearches,
    required this.searchResults,
    required this.query,
    required this.sortBy,
    required this.filterCategory,
    required this.isLoading,
    required this.hasMore,
  });

  final List<String> trendingSearches;
  final List<Listing> searchResults;
  final String query;
  final String sortBy;
  final String filterCategory;
  final bool isLoading;
  final bool hasMore;

  factory ExploreState.initial() {
    return const ExploreState(
      trendingSearches: ['Textbooks', 'Headphones', 'Jackets', 'Laptops'],
      searchResults: [],
      query: '',
      sortBy: 'Popular',
      filterCategory: 'All',
      isLoading: true,
      hasMore: true,
    );
  }

  ExploreState copyWith({
    List<String>? trendingSearches,
    List<Listing>? searchResults,
    String? query,
    String? sortBy,
    String? filterCategory,
    bool? isLoading,
    bool? hasMore,
  }) {
    return ExploreState(
      trendingSearches: trendingSearches ?? this.trendingSearches,
      searchResults: searchResults ?? this.searchResults,
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      filterCategory: filterCategory ?? this.filterCategory,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
        trendingSearches,
        searchResults,
        query,
        sortBy,
        filterCategory,
        isLoading,
        hasMore,
      ];
}

class ExploreViewModel extends StateNotifier<ExploreState> {
  ExploreViewModel(this._repository) : super(ExploreState.initial()) {
    _load();
  }

  final ListingRepository _repository;

  Future<void> _load() async {
    final results = await _repository.search(
      query: state.query,
      category: state.filterCategory,
      sortBy: state.sortBy,
    );
    state = state.copyWith(searchResults: results, isLoading: false, hasMore: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _repository.refresh();
    await _load();
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    _load();
  }

  void setFilter(String category) {
    state = state.copyWith(filterCategory: category);
    _load();
  }

  void setSort(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _load();
  }

  void applyTrending(String tag) {
    state = state.copyWith(query: tag);
    _load();
  }
}
