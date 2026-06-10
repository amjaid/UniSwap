import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uniswap/services/api_client.dart';

/// Service for chat and messaging operations.
///
/// Communicates with the Django chat API endpoints.
/// Note: This uses polling for message updates since DRF is REST-based.
/// For real-time messaging, consider adding WebSocket support later.
class ChatService {
  ChatService(this._apiClient);

  final ApiClient _apiClient;

  /// Polling interval for new messages (in seconds).
  static const int _pollIntervalSeconds = 5;

  /// Active polling timers, keyed by chat ID.
  final Map<int, Timer> _pollingTimers = {};

  /// Callbacks registered for message updates, keyed by chat ID.
  final Map<int, List<void Function(List<Map<String, dynamic>>)>> _listeners =
      {};

  // ──────────────────────────────────────────────
  // Chats
  // ──────────────────────────────────────────────

  /// Fetch the current user's chat conversations.
  Future<ApiResponse> fetchChats({int page = 1}) async {
    return _apiClient.get(
      '/chats/',
      queryParams: {'page': page.toString()},
    );
  }

  /// Create a new chat conversation with participants.
  Future<ApiResponse> createChat({
    required List<int> participantIds,
    int? itemId,
  }) async {
    final body = <String, dynamic>{
      'participants': participantIds,
    };
    if (itemId != null) body['item'] = itemId;

    return _apiClient.post('/chats/', body: body);
  }

  /// Fetch messages for a specific chat.
  Future<ApiResponse> fetchMessages(int chatId) async {
    return _apiClient.get('/chats/$chatId/messages/');
  }

  /// Send a message in a chat.
  Future<ApiResponse> sendMessage(int chatId, String content) async {
    return _apiClient.post(
      '/chats/$chatId/send_message/',
      body: {'content': content},
    );
  }

  /// Mark all messages in a chat as read for the current user.
  Future<ApiResponse> markAsRead(int chatId) async {
    return _apiClient.post('/chats/$chatId/mark_read/');
  }

  // ──────────────────────────────────────────────
  // Real-time Polling (simulates WebSocket)
  // ──────────────────────────────────────────────

  /// Start polling for new messages in a chat.
  ///
  /// [chatId] - The chat to poll.
  /// [onMessages] - Callback invoked with the latest messages list.
  void startPolling(
    int chatId,
    void Function(List<Map<String, dynamic>> messages) onMessages,
  ) {
    // Register listener
    _listeners.putIfAbsent(chatId, () => []);
    _listeners[chatId]!.add(onMessages);

    // Start timer if not already running
    if (!_pollingTimers.containsKey(chatId)) {
      _pollingTimers[chatId] = Timer.periodic(
        const Duration(seconds: _pollIntervalSeconds),
        (_) => _pollMessages(chatId),
      );
      // Immediate first fetch
      _pollMessages(chatId);
    }
  }

  /// Stop polling for a specific chat.
  void stopPolling(int chatId) {
    _pollingTimers[chatId]?.cancel();
    _pollingTimers.remove(chatId);
    _listeners.remove(chatId);
  }

  /// Internal: poll messages and notify listeners.
  Future<void> _pollMessages(int chatId) async {
    try {
      final response = await fetchMessages(chatId);
      if (response.isSuccess && response.data != null) {
        final messages = response.data!['results'] as List<dynamic>? ?? [];
        final messageList = messages.cast<Map<String, dynamic>>();

        final listeners = _listeners[chatId];
        if (listeners != null) {
          for (final listener in listeners) {
            listener(messageList);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Polling error for chat $chatId: $e');
      }
    }
  }

  /// Dispose all polling timers.
  void dispose() {
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
    _listeners.clear();
  }
}
