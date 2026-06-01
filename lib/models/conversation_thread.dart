enum ThreadCategory {
  all,
  buying,
  selling,
}

class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.swapId,
    required this.contactName,
    required this.contactAvatarUrl,
    required this.isVerified,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
    required this.role,
  });

  final String id;
  final String swapId;
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
