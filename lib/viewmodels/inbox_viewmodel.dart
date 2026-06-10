import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/conversation_thread.dart';
import 'package:uniswap/services/chat_service.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

final inboxViewModelProvider = StateNotifierProvider<InboxViewModel, InboxState>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final viewModel = InboxViewModel(ref.read(chatServiceProvider), user?['id']?.toString());
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
  InboxViewModel(this._chatService, this._userId) : super(InboxState.initial()) {
    _loadChats();
  }

  final ChatService _chatService;
  final String? _userId;
  Timer? _pollTimer;

  void _loadChats() {
    _fetchChats();
    // Poll for new chats every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchChats();
    });
  }

  Future<void> _fetchChats() async {
    if (_userId == null) {
      state = state.copyWith(isLoading: false, threads: []);
      return;
    }

    try {
      final response = await _chatService.fetchChats();
      if (response.isSuccess && response.data != null) {
        final chatsList = response.data!['results'] as List<dynamic>? ?? [];
        final threads = chatsList.map((chat) {
          final chatMap = chat as Map<String, dynamic>;
          final participants = (chatMap['participants'] as List<dynamic>?)
                  ?.map((p) => p.toString())
                  .toList() ??
              [];
          final otherUserName = participants
              .where((p) => p != _userId)
              .firstOrNull;
          return ConversationThread(
            id: chatMap['id']?.toString() ?? '',
            swapId: chatMap['id']?.toString() ?? '',
            contactName: otherUserName ?? 'User',
            contactAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
            isVerified: false,
            lastMessage: chatMap['last_message'] as String? ?? 'Start chatting',
            lastTimestamp: DateTime.tryParse(chatMap['updated_at'] as String? ?? '') ?? DateTime.now(),
            unreadCount: chatMap['unread_count'] as int? ?? 0,
            role: ThreadCategory.all,
          );
        }).toList();

        threads.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
        state = state.copyWith(isLoading: false, threads: threads, errorMessage: null);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load conversations.');
    }
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
    _pollTimer?.cancel();
    super.dispose();
  }
}
