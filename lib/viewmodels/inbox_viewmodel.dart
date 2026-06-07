import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/conversation_thread.dart';
import 'package:uniswap/services/firestore_service.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

final inboxViewModelProvider = StateNotifierProvider<InboxViewModel, InboxState>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final viewModel = InboxViewModel(ref.read(firestoreServiceProvider), user?.uid);
  return viewModel;
});

class InboxState extends Equatable {
  const InboxState({
    required this.isLoading,
    required this.threads,
    required this.activeFilter,
    required this.errorMessage,
  });

  final bool isLoading;
  final List<ConversationThread> threads;
  final ThreadCategory activeFilter;
  final String? errorMessage;

  factory InboxState.initial() {
    return const InboxState(
      isLoading: true,
      threads: [],
      activeFilter: ThreadCategory.all,
      errorMessage: null,
    );
  }

  InboxState copyWith({
    bool? isLoading,
    List<ConversationThread>? threads,
    ThreadCategory? activeFilter,
    String? errorMessage,
  }) {
    return InboxState(
      isLoading: isLoading ?? this.isLoading,
      threads: threads ?? this.threads,
      activeFilter: activeFilter ?? this.activeFilter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, threads, activeFilter, errorMessage];
}

class InboxViewModel extends StateNotifier<InboxState> {
  InboxViewModel(this._firestoreService, this._userId) : super(InboxState.initial()) {
    _subscribe();
  }

  final FirestoreService _firestoreService;
  final String? _userId;
  StreamSubscription<List<ConversationThread>>? _subscription;

  void _subscribe() {
    if (_userId == null) {
      state = state.copyWith(isLoading: false, threads: []);
      return;
    }

    _subscription = _firestoreService.streamThreads(_userId).listen(
      (threads) {
        state = state.copyWith(isLoading: false, threads: threads, errorMessage: null);
      },
      onError: (_) {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load conversations.');
      },
    );
  }

  void setFilter(ThreadCategory filter) {
    state = state.copyWith(activeFilter: filter);
  }

  List<ConversationThread> filteredThreads() {
    if (state.activeFilter == ThreadCategory.all) {
      return state.threads;
    }
    return state.threads.where((thread) => thread.role == state.activeFilter).toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
