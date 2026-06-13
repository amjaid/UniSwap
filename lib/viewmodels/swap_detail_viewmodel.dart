import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/swap.dart';
import 'package:uniswap/repositories/swap_repository.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/viewmodels/swap_hub_viewmodel.dart';

final swapDetailViewModelProvider =
    StateNotifierProvider.family<SwapDetailViewModel, SwapDetailState, String>((ref, swapId) {
  return SwapDetailViewModel(ref.read(swapRepositoryProvider), ref, swapId);
});

class SwapDetailState extends Equatable {
  const SwapDetailState({
    required this.isLoading,
    required this.swap,
    required this.errorMessage,
  });

  final bool isLoading;
  final Swap? swap;
  final String? errorMessage;

  factory SwapDetailState.initial() {
    return const SwapDetailState(isLoading: true, swap: null, errorMessage: null);
  }

  SwapDetailState copyWith({
    bool? isLoading,
    Swap? swap,
    String? errorMessage,
  }) {
    return SwapDetailState(
      isLoading: isLoading ?? this.isLoading,
      swap: swap ?? this.swap,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, swap, errorMessage];
}

class SwapDetailViewModel extends StateNotifier<SwapDetailState> {
  SwapDetailViewModel(this._repository, this._ref, this._swapId)
      : super(SwapDetailState.initial()) {
    _load();
  }

  final SwapRepository _repository;
  final Ref _ref;
  final String _swapId;

  void _load() {
    final swap = _repository.getById(_swapId);
    state = state.copyWith(isLoading: false, swap: swap);
  }

  void acceptSwap() {
    _updateStatus(SwapStatus.accepted);
  }

  void cancelSwap() {
    _updateStatus(SwapStatus.cancelled);
  }

  void arrangeMeetup(String location) {
    if (location.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Meetup location is required.');
      return;
    }
    _repository.updateMeetupLocation(_swapId, location.trim());
    _updateStatus(SwapStatus.meetupArranged);
  }

  void markCompleted() {
    _updateStatus(SwapStatus.completed);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void _updateStatus(SwapStatus status) {
    _repository.updateStatus(_swapId, status);
    _load();
    _ref.read(swapHubViewModelProvider.notifier).refresh();
  }
}
