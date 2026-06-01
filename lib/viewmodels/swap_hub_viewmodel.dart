import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/swap.dart';
import 'package:uniswap/repositories/swap_repository.dart';

final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  return SwapRepository();
});

final swapHubViewModelProvider = StateNotifierProvider<SwapHubViewModel, SwapHubState>((ref) {
  return SwapHubViewModel(ref.read(swapRepositoryProvider));
});

class SwapHubState extends Equatable {
  const SwapHubState({
    required this.isLoading,
    required this.swaps,
  });

  final bool isLoading;
  final List<Swap> swaps;

  factory SwapHubState.initial() {
    return const SwapHubState(isLoading: true, swaps: []);
  }

  SwapHubState copyWith({
    bool? isLoading,
    List<Swap>? swaps,
  }) {
    return SwapHubState(
      isLoading: isLoading ?? this.isLoading,
      swaps: swaps ?? this.swaps,
    );
  }

  @override
  List<Object?> get props => [isLoading, swaps];
}

class SwapHubViewModel extends StateNotifier<SwapHubState> {
  SwapHubViewModel(this._repository) : super(SwapHubState.initial()) {
    _load();
  }

  final SwapRepository _repository;

  void _load() {
    final swaps = _repository.fetchSwaps();
    state = state.copyWith(isLoading: false, swaps: swaps);
  }

  void refresh() {
    state = state.copyWith(isLoading: true);
    _load();
  }
}
