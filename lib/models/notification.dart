/// Represents an in-app notification fetched from the Django backend.
///
/// Parses the JSON response from `GET /api/notifications/`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  /// Parse a single notification from the Django API response.
  ///
  /// Expected JSON shape:
  /// ```json
  /// {
  ///   "id": 1,
  ///   "type": "new_message",
  ///   "content": "Ahmad sent you a message",
  ///   "is_read": false,
  ///   "created_at": "2026-01-15T10:30:00Z"
  /// }
  /// ```
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as int?)?.toString() ?? '',
      type: (json['type'] as String?) ?? '',
      content: (json['content'] as String?)?.trim() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Parse a list of notifications from a paginated API response.
  static List<AppNotification> listFromJson(Map<String, dynamic> json) {
    final raw = json['results'] as List<dynamic>? ?? [];
    return raw
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  final String id;
  final String type;
  final String content;
  final bool isRead;
  final DateTime createdAt;
}
