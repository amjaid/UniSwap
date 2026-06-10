import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/chat_message.dart';
import 'package:uniswap/services/chat_service.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

final chatViewModelProvider =
    StateNotifierProvider.family<ChatViewModel, ChatState, String>((ref, conversationId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final viewModel = ChatViewModel(
    ref.read(chatServiceProvider),
    conversationId,
    user?['id']?.toString(),
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
  ChatViewModel(this._chatService, this._conversationId, this._userId)
      : super(ChatState.initial()) {
    _loadMessages();
  }

  final ChatService _chatService;
  final String _conversationId;
  final String? _userId;
  Timer? _pollTimer;

  int get _chatId => int.tryParse(_conversationId) ?? 0;

  void _loadMessages() {
    _fetchMessages();
    // Poll for new messages every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchMessages();
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await _chatService.fetchMessages(_chatId);
      if (response.isSuccess && response.data != null) {
        final messagesList = response.data!['results'] as List<dynamic>? ??
            [response.data!];
        final messages = messagesList.map((m) => ChatMessage(
          id: m['id']?.toString() ?? '',
          senderId: m['sender']?.toString() ?? m['sender_id']?.toString() ?? '',
          text: m['content'] as String? ?? m['text'] as String? ?? '',
          timestamp: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
        )).toList();
        state = state.copyWith(isLoading: false, messages: messages, errorMessage: null);

        // Mark messages as read
        if (_userId != null) {
          await _chatService.markAsRead(_chatId);
        }
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load messages.');
    }
  }

  Future<void> setTyping(bool isTyping) async {
    // Typing indicator not yet supported via REST API
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _userId == null) return false;

    try {
      final response = await _chatService.sendMessage(_chatId, trimmed);
      if (response.isSuccess) {
        await _fetchMessages();
        return true;
      }
      return false;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to send message.');
      return false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
