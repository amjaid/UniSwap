/// Represents a single chat message fetched from the Django backend.
///
/// Parses the JSON response from `GET /api/chats/{id}/messages/`
/// or `POST /api/chats/{id}/send_message/`.
///
/// Expected JSON shape:
/// ```json
/// {
///   "id": 1,
///   "sender": 2,
///   "sender_name": "Ahmad",
///   "sender_email": "ahmad@utm.my",
///   "content": "Still available?",
///   "is_read": false,
///   "created_at": "2026-01-15T10:30:00Z"
/// }
/// ```
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.senderName,
    this.senderAvatarUrl,
    this.isRead = false,
  });

  /// Parse a single message from the Django API response.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Parse sender – could be an object {id, name} or a raw id
    int senderId = 0;
    String? senderName;
    String? senderAvatarUrl;
    final rawSender = json['sender'];
    if (rawSender is Map<String, dynamic>) {
      senderId = rawSender['id'] as int? ?? 0;
      senderName = rawSender['name'] as String?;
      senderAvatarUrl = rawSender['avatar_url'] as String?;
    } else if (rawSender is int) {
      senderId = rawSender;
    }

    // Use sender_name field as fallback
    senderName ??= json['sender_name'] as String?;

    return ChatMessage(
      id: (json['id'] as int?)?.toString() ?? '',
      senderId: senderId.toString(),
      text: (json['content'] as String?)?.trim() ?? '',
      timestamp:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  /// Parse a list of messages from a paginated API response.
  static List<ChatMessage> listFromJson(Map<String, dynamic> json) {
    final raw = json['results'] as List<dynamic>? ?? [];
    return raw
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? senderName;
  final String? senderAvatarUrl;
  final bool isRead;

  bool isMine(String? userId) => userId != null && senderId == userId;
}
