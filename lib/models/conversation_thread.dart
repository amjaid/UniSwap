/// Categorises a conversation thread by the current user's role.
enum ThreadCategory {
  all,
  buying,
  selling,
}

/// Represents a chat conversation thread fetched from the Django backend.
///
/// Parses the JSON response from `GET /api/chats/`.
class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.swapId,
    required this.contactId,
    required this.contactName,
    required this.contactAvatarUrl,
    required this.isVerified,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
    required this.role,
  });

  /// Parse a single chat thread from the Django API response.
  ///
  /// Expected JSON shape (from ChatListSerializer):
  /// ```json
  /// {
  ///   "id": 1,
  ///   "participant_names": [{"id": 2, "name": "Ahmad", "avatar_url": "..."}],
  ///   "item": 5,
  ///   "item_title": "Textbook",
  ///   "last_message": {"content": "Still available?", "sender_name": "Ahmad", "created_at": "..."},
  ///   "unread_count": 2,
  ///   "created_at": "2026-01-15T10:00:00Z",
  ///   "updated_at": "2026-01-15T12:00:00Z"
  /// }
  /// ```
  factory ConversationThread.fromJson(
    Map<String, dynamic> json, {
    required int currentUserId,
  }) {
    // Backend ChatListSerializer returns 'participant_names' (not 'participants')
    // in GET responses. 'participants' is write_only for creation.
    final participants = (json['participant_names'] as List<dynamic>?)
            ?.map((p) => p is Map<String, dynamic> ? p : <String, dynamic>{})
            .toList() ??
        [];

    // Find the other participant (not the current user)
    Map<String, dynamic> otherUser = {};
    for (final p in participants) {
      final pid = p['id'] as int?;
      if (pid != null && pid != currentUserId) {
        otherUser = p;
        break;
      }
    }

    final contactId = (otherUser['id'] as int?) ?? 0;
    final contactName =
        (otherUser['name'] as String?)?.trim() ?? 'User';
    final contactAvatarUrl =
        (otherUser['avatar_url'] as String?)?.trim() ?? '';

    // Determine role based on whether the current user is the seller.
    // Backend ChatListSerializer returns 'item' as a simple FK (int) and
    // 'item_title' as a string. We can't determine role from item alone,
    // so default to 'all' unless we have more info.
    ThreadCategory role = ThreadCategory.all;

    // Parse last_message - it's a nested object from get_last_message()
    String lastMessageText = 'Start chatting';
    final lastMessageRaw = json['last_message'];
    if (lastMessageRaw is Map<String, dynamic>) {
      lastMessageText =
          (lastMessageRaw['content'] as String?)?.trim() ?? 'Start chatting';
    } else if (lastMessageRaw is String) {
      lastMessageText = lastMessageRaw.trim();
    }

    return ConversationThread(
      id: (json['id'] as int?)?.toString() ?? '',
      swapId: (json['id'] as int?)?.toString() ?? '',
      contactId: contactId,
      contactName: contactName,
      contactAvatarUrl: contactAvatarUrl,
      isVerified: false, // Verification not yet supported by backend
      lastMessage: lastMessageText,
      lastTimestamp:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      unreadCount: json['unread_count'] as int? ?? 0,
      role: role,
    );
  }

  /// Parse a list of chat threads from a paginated API response.
  static List<ConversationThread> listFromJson(
    Map<String, dynamic> json, {
    required int currentUserId,
  }) {
    final raw = json['results'] as List<dynamic>? ?? [];
    return raw
        .map((e) => ConversationThread.fromJson(
              e as Map<String, dynamic>,
              currentUserId: currentUserId,
            ))
        .toList();
  }

  /// Deduplicate a list of chat threads so that only the most recent
  /// thread per contact (other participant) is kept.
  ///
  /// Chats with no valid contact (contactId == 0) are filtered out.
  /// For each contact, the thread with the latest [lastTimestamp] is kept.
  static List<ConversationThread> deduplicateByContact(
    List<ConversationThread> threads,
  ) {
    final Map<int, ConversationThread> latestByContact = {};

    for (final thread in threads) {
      // Skip stale/invalid chats with no valid contact
      if (thread.contactId <= 0) continue;

      final existing = latestByContact[thread.contactId];
      if (existing == null || thread.lastTimestamp.isAfter(existing.lastTimestamp)) {
        latestByContact[thread.contactId] = thread;
      }
    }

    final result = latestByContact.values.toList();
    result.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
    return result;
  }

  final String id;
  final String swapId;

  /// The other participant's user ID (0 if unknown/invalid).
  final int contactId;

  final String contactName;
  final String contactAvatarUrl;
  final bool isVerified;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;
  final ThreadCategory role;

  ConversationThread copyWith({
    String? lastMessage,
    DateTime? lastTimestamp,
    int? unreadCount,
  }) {
    return ConversationThread(
      id: id,
      swapId: swapId,
      contactId: contactId,
      contactName: contactName,
      contactAvatarUrl: contactAvatarUrl,
      isVerified: isVerified,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      role: role,
    );
  }
}

ThreadCategory threadCategoryFromString(String? value) {
  switch (value) {
    case 'buying':
      return ThreadCategory.buying;
    case 'selling':
      return ThreadCategory.selling;
    default:
      return ThreadCategory.all;
  }
}

String threadCategoryLabel(ThreadCategory category) {
  switch (category) {
    case ThreadCategory.buying:
      return 'Buying';
    case ThreadCategory.selling:
      return 'Selling';
    case ThreadCategory.all:
      return 'All';
  }
}
