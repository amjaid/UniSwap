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
    if (kDebugMode) {
      debugPrint('[ChatService] Fetching chats page $page...');
    }
    final response = await _apiClient.get(
      '/chats/',
      queryParams: {'page': page.toString()},
    );
    if (kDebugMode) {
      debugPrint('[ChatService] Response success=${response.isSuccess}, data=${response.data}');
      if (response.error != null) {
        debugPrint('[ChatService] Error: ${response.error}');
      }
    }
    return response;
  }

  /// Fetch a single chat by ID with full details.
  Future<ApiResponse> fetchChat(int chatId) async {
    return _apiClient.get('/chats/$chatId/');
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

  /// Find an existing chat with a participant, or create a new one.
  ///
  /// A pair of users must have only **one** chat ID — no more than one.
  /// This method ensures that by:
  /// 1. Iterating through all paginated chats (`GET /api/chats/`) looking for
  ///    any chat where `participant_names` contains a user with `id == participantId`.
  ///    The `itemId` is **ignored** during lookup — only the participant match matters.
  /// 2. If found, returns the existing chat's ID.
  /// 3. If not found, calls `POST /api/chats/` with `participant_ids` and
  ///    optionally `item_id`, then returns the new chat's ID.
  ///
  /// Returns `null` if both lookup and creation fail.
  Future<int?> getOrCreateChatId({
    required int participantId,
    int? itemId,
  }) async {
    if (kDebugMode) {
      debugPrint('[ChatService] getOrCreateChatId(participantId=$participantId, itemId=$itemId)');
    }

    // Step 1: Iterate through all paginated chats looking for a participant match
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final response = await fetchChats(page: page);
      if (!response.isSuccess || response.data == null) break;

      final data = response.data!;
      final chats = data['results'] as List<dynamic>? ?? [];

      // Look for a chat where the target participant is present
      for (final chat in chats) {
        if (chat is! Map<String, dynamic>) continue;

        final chatId = chat['id'] as int?;
        final participantNames = chat['participant_names'] as List<dynamic>? ?? [];

        final hasParticipant = participantNames.any((p) {
          if (p is Map<String, dynamic>) {
            return p['id'] == participantId;
          }
          return false;
        });

        if (hasParticipant && chatId != null) {
          if (kDebugMode) {
            debugPrint('[ChatService] Found existing chat $chatId with participant $participantId');
          }
          return chatId;
        }
      }

      // Check if there are more pages
      final next = data['next'];
      hasMore = next != null && next is String && next.isNotEmpty;
      page++;
    }

    // Step 2: No existing chat found — create a new one
    if (kDebugMode) {
      debugPrint('[ChatService] No existing chat found with participant $participantId, creating new one...');
    }

    final createResponse = await createChat(
      participantIds: [participantId],
      itemId: itemId,
    );

    if (createResponse.isSuccess && createResponse.data != null) {
      final newChatId = createResponse.data!['id'] as int?;
      if (kDebugMode) {
        debugPrint('[ChatService] Created new chat $newChatId');
      }
      return newChatId;
    }

    if (kDebugMode) {
      debugPrint('[ChatService] Failed to create chat: ${createResponse.error}');
    }
    return null;
  }

  /// Fetch messages for a specific chat.
  ///
  /// Uses the `/api/messages/` endpoint (ChatMessageViewSet) filtered by chat.
  Future<ApiResponse> fetchMessages(int chatId, {int page = 1}) async {
    if (kDebugMode) {
      debugPrint('[ChatService] fetchMessages(chatId=$chatId, page=$page)');
    }
    final response = await _apiClient.get(
      '/messages/',
      queryParams: {
        'chat': chatId.toString(),
        'page': page.toString(),
      },
    );
    if (kDebugMode) {
      debugPrint('[ChatService] fetchMessages response: success=${response.isSuccess}, data=${response.data}');
      if (response.error != null) {
        debugPrint('[ChatService] fetchMessages error: ${response.error}');
      }
    }
    return response;
  }

  /// Send a message in a chat.
  Future<ApiResponse> sendMessage(int chatId, String content) async {
    if (kDebugMode) {
      debugPrint('[ChatService] sendMessage(chatId=$chatId, content="$content")');
    }
    final response = await _apiClient.post(
      '/chats/$chatId/send_message/',
      body: {'content': content},
    );
    if (kDebugMode) {
      debugPrint('[ChatService] sendMessage response: success=${response.isSuccess}, data=${response.data}');
      if (response.error != null) {
        debugPrint('[ChatService] sendMessage error: ${response.error}');
      }
    }
    return response;
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
