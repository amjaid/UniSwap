import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/models/chat_message.dart';
import 'package:uniswap/services/chat_service.dart';
import 'package:uniswap/services/providers.dart';

/// Persistent store for chat messages, keyed by chat ID.
///
/// This provider survives screen navigation — messages are NOT cleared
/// when the user leaves a chat screen. This prevents the "messages vanish"
/// bug where a freshly created ChatViewModel would fetch an empty list
/// from the API before the backend had indexed the new message.
///
/// Messages are only replaced on:
/// 1. First load (if no messages exist for that chatId)
/// 2. Manual pull-to-refresh (merge by ID)
/// 3. Sending a new message (append locally)
///
/// Polling merges new messages by ID — never replaces the entire list.
final chatMessageStoreProvider =
    StateNotifierProvider<ChatMessageStore, Map<int, List<ChatMessage>>>((ref) {
  return ChatMessageStore(ref.read(chatServiceProvider));
});

/// Store managing chat messages per chat ID.
class ChatMessageStore extends StateNotifier<Map<int, List<ChatMessage>>> {
  ChatMessageStore(this._chatService) : super({});

  final ChatService _chatService;

  /// Active polling timers, keyed by chat ID.
  final Map<int, Timer> _pollTimers = {};

  /// Whether the first load has completed for each chat ID.
  final Set<int> _loadedChats = {};

  /// Get messages for a specific chat. Returns empty list if not loaded.
  List<ChatMessage> getMessages(int chatId) {
    return state[chatId] ?? [];
  }

  /// Load messages for a chat from the API.
  ///
  /// On first load, replaces the message list entirely.
  /// On subsequent loads (polling/refresh), merges by ID to avoid duplicates.
  Future<void> loadMessages(int chatId, {bool forceRefresh = false}) async {
    try {
      final response = await _chatService.fetchMessages(chatId);
      if (response.isSuccess && response.data != null) {
        final messagesList = response.data!['results'] as List<dynamic>? ?? [];
        final fetchedMessages = messagesList
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();

        final existingMessages = state[chatId] ?? [];

        if (kDebugMode) {
          debugPrint('[ChatStore] loadMessages(chatId=$chatId): '
              'fetched=${fetchedMessages.length}, '
              'existing=${existingMessages.length}, '
              'firstLoad=${!_loadedChats.contains(chatId)}');
        }

        if (!_loadedChats.contains(chatId) || forceRefresh) {
          // First load or forced refresh: replace the list entirely
          state = {
            ...state,
            chatId: fetchedMessages,
          };
          _loadedChats.add(chatId);
          if (kDebugMode) {
            debugPrint('[ChatStore] First load: set ${fetchedMessages.length} messages for chat $chatId');
          }
        } else {
          // Merge: only append messages with new IDs
          final existingIds = existingMessages.map((m) => m.id).toSet();
          final newMessages = fetchedMessages
              .where((m) => !existingIds.contains(m.id))
              .toList();

          if (newMessages.isNotEmpty) {
            state = {
              ...state,
              chatId: [...existingMessages, ...newMessages],
            };
            if (kDebugMode) {
              debugPrint('[ChatStore] Merged ${newMessages.length} new messages for chat $chatId');
            }
          } else {
            if (kDebugMode) {
              debugPrint('[ChatStore] No new messages for chat $chatId');
            }
          }
        }

        // Mark messages as read
        await _chatService.markAsRead(chatId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ChatStore] Error loading messages for chat $chatId: $e');
      }
    }
  }

  /// Append a newly sent message to the store for the given chat.
  ///
  /// Called after a successful sendMessage() API call.
  /// Does NOT refetch from the API — appends locally to avoid race conditions.
  void appendMessage(int chatId, ChatMessage message) {
    final existingMessages = state[chatId] ?? [];
    state = {
      ...state,
      chatId: [...existingMessages, message],
    };
    _loadedChats.add(chatId);
    if (kDebugMode) {
      debugPrint('[ChatStore] Appended message ${message.id} to chat $chatId, '
          'total: ${state[chatId]?.length}');
    }
  }

  /// Start polling for new messages in a chat.
  void startPolling(int chatId) {
    if (_pollTimers.containsKey(chatId)) return;

    _pollTimers[chatId] = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadMessages(chatId),
    );
  }

  /// Stop polling for a specific chat.
  void stopPolling(int chatId) {
    _pollTimers[chatId]?.cancel();
    _pollTimers.remove(chatId);
  }

  /// Clear stored messages for a chat (e.g., on logout).
  void clearChat(int chatId) {
    stopPolling(chatId);
    _loadedChats.remove(chatId);
    state = {
      ...state,
      chatId: [],
    };
  }

  /// Clear all stored messages and stop all timers.
  void clearAll() {
    for (final timer in _pollTimers.values) {
      timer.cancel();
    }
    _pollTimers.clear();
    _loadedChats.clear();
    state = {};
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}
