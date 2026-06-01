class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  bool isMine(String? userId) => userId != null && senderId == userId;
}
