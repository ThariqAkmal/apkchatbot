class ChatMessage {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
