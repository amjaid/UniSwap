import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/chat_message.dart';
import 'package:uniswap/services/firestore_service.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

final chatViewModelProvider =
    StateNotifierProvider.family<ChatViewModel, ChatState, String>((ref, conversationId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final viewModel = ChatViewModel(
    ref.read(firestoreServiceProvider),
    conversationId,
    user?.uid,
  );
  return viewModel;
});

class ChatState extends Equatable {
  const ChatState({
    required this.isLoading,
    required this.messages,
    required this.isOtherTyping,
    required this.isOtherOnline,
    required this.errorMessage,
  });

  final bool isLoading;
  final List<ChatMessage> messages;
  final bool isOtherTyping;
  final bool isOtherOnline;
  final String? errorMessage;

  factory ChatState.initial() {
    return const ChatState(
      isLoading: true,
      messages: [],
      isOtherTyping: false,
      isOtherOnline: false,
      errorMessage: null,
    );
  }

  ChatState copyWith({
    bool? isLoading,
    List<ChatMessage>? messages,
    bool? isOtherTyping,
    bool? isOtherOnline,
    String? errorMessage,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      isOtherTyping: isOtherTyping ?? this.isOtherTyping,
      isOtherOnline: isOtherOnline ?? this.isOtherOnline,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, messages, isOtherTyping, isOtherOnline, errorMessage];
}

class ChatViewModel extends StateNotifier<ChatState> {
  ChatViewModel(this._firestoreService, this._conversationId, this._userId)
      : super(ChatState.initial()) {
    _subscribe();
  }

  final FirestoreService _firestoreService;
  final String _conversationId;
  final String? _userId;
  StreamSubscription<List<ChatMessage>>? _subscription;
  StreamSubscription<Map<String, dynamic>>? _metaSubscription;
  String? _otherUserId;

  void _subscribe() {
    _subscription = _firestoreService.streamMessages(_conversationId).listen(
      (messages) {
        state = state.copyWith(isLoading: false, messages: messages, errorMessage: null);
        if (_userId != null) {
          _firestoreService.markConversationRead(
            conversationId: _conversationId,
            userId: _userId,
          );
        }
      },
      onError: (_) {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load messages.');
      },
    );

    _metaSubscription = _firestoreService.streamConversationMeta(_conversationId).listen(
      (data) {
        final participants = (data['participants'] as List?)?.whereType<String>().toList() ?? [];
        if (_userId != null && participants.isNotEmpty) {
          _otherUserId = participants.firstWhere(
            (id) => id != _userId,
            orElse: () => participants.first,
          );
        }

        final typing = (data['typing'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
        final presence = (data['presence'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {};

        final otherTyping = _otherUserId != null ? (typing[_otherUserId] == true) : false;
        final otherOnline = _otherUserId != null ? (presence[_otherUserId] == true) : false;

        state = state.copyWith(isOtherTyping: otherTyping, isOtherOnline: otherOnline);
      },
      onError: (_) {},
    );

    if (_userId != null) {
      _firestoreService.setPresenceStatus(
        conversationId: _conversationId,
        userId: _userId,
        isOnline: true,
      );
    }
  }

  Future<void> setTyping(bool isTyping) async {
    if (_userId == null) return;
    await _firestoreService.setTypingStatus(
      conversationId: _conversationId,
      userId: _userId,
      isTyping: isTyping,
    );
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _userId == null) return false;

    try {
      await _firestoreService.sendMessage(
        conversationId: _conversationId,
        senderId: _userId,
        text: trimmed,
      );
      await _firestoreService.markConversationRead(
        conversationId: _conversationId,
        userId: _userId,
      );
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to send message.');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _metaSubscription?.cancel();
    if (_userId != null) {
      _firestoreService.setTypingStatus(
        conversationId: _conversationId,
        userId: _userId,
        isTyping: false,
      );
      _firestoreService.setPresenceStatus(
        conversationId: _conversationId,
        userId: _userId,
        isOnline: false,
      );
    }
    super.dispose();
  }
}
