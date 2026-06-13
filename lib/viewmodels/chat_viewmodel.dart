import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/chat_message.dart';
import 'package:uniswap/services/chat_service.dart';
import 'package:uniswap/services/providers.dart';
import 'package:uniswap/viewmodels/auth_viewmodel.dart';

final chatViewModelProvider =
    StateNotifierProvider.family<ChatViewModel, ChatState, String>((ref, chatId) {
  final user = ref.watch(authStateProvider);
  final viewModel = ChatViewModel(
    ref.read(chatServiceProvider),
    chatId,
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
        final messagesList = response.data!['results'] as List<dynamic>? ?? [];
        final fetchedMessages = messagesList.map((m) =>
          ChatMessage.fromJson(m as Map<String, dynamic>)
        ).toList();

        if (kDebugMode) {
          debugPrint('[ChatVM] _fetchMessages: chatId=$_chatId, '
              'fetched=${fetchedMessages.length} messages, '
              'existing=${state.messages.length} messages, '
              'isLoading=${state.isLoading}');
          if (fetchedMessages.isNotEmpty) {
            debugPrint('[ChatVM] fetched IDs: ${fetchedMessages.map((m) => m.id).toList()}');
          }
          if (state.messages.isNotEmpty) {
            debugPrint('[ChatVM] existing IDs: ${state.messages.map((m) => m.id).toList()}');
          }
        }

        // Merge fetched messages into the existing list instead of replacing.
        // This prevents a race condition where the API temporarily returns an
        // incomplete list (e.g., before a newly sent message is indexed),
        // which would otherwise wipe the entire chat history.
        //
        // Strategy: build a set of existing message IDs, then append any
        // fetched messages whose IDs are not already in the list.
        final existingIds = state.messages.map((m) => m.id).toSet();
        final newMessages = fetchedMessages
            .where((m) => !existingIds.contains(m.id))
            .toList();

        if (kDebugMode) {
          debugPrint('[ChatVM] new message IDs to add: ${newMessages.map((m) => m.id).toList()}');
        }

        if (newMessages.isNotEmpty) {
          state = state.copyWith(
            isLoading: false,
            messages: [...state.messages, ...newMessages],
            errorMessage: null,
          );
          if (kDebugMode) {
            debugPrint('[ChatVM] Appended ${newMessages.length} new messages, '
                'total now: ${state.messages.length}');
          }
        } else if (state.isLoading) {
          // First load: use the fetched list even if empty
          state = state.copyWith(
            isLoading: false,
            messages: fetchedMessages,
            errorMessage: null,
          );
          if (kDebugMode) {
            debugPrint('[ChatVM] First load: set ${fetchedMessages.length} messages');
          }
        } else {
          if (kDebugMode) {
            debugPrint('[ChatVM] No new messages, keeping existing ${state.messages.length} messages');
          }
        }

        // Mark messages as read
        if (_userId != null) {
          await _chatService.markAsRead(_chatId);
        }
      } else {
        if (kDebugMode) {
          debugPrint('[ChatVM] _fetchMessages: response failed or data is null. '
              'isSuccess=${response.isSuccess}, data is null=${response.data == null}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChatVM] _fetchMessages error: $e');
      }
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
      if (response.isSuccess && response.data != null) {
        // Append the new message locally instead of refetching all messages.
        // This avoids a race condition where _fetchMessages() might return
        // an empty/incomplete list if the backend hasn't fully indexed the
        // new message yet, which would wipe the entire chat history.
        final newMessage = ChatMessage.fromJson(
          response.data as Map<String, dynamic>,
        );
        state = state.copyWith(
          messages: [...state.messages, newMessage],
          errorMessage: null,
        );
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
