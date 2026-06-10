import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/swap.dart';
import 'package:uniswap/repositories/swap_repository.dart';
import 'package:uniswap/services/providers.dart';

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

  Future<void> _load() async {
    final swaps = await _repository.fetchSwaps();
    state = state.copyWith(isLoading: false, swaps: swaps);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _repository.refresh();
    await _load();
  }
}
