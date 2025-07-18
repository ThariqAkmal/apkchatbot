class DifyResponse {
  final String answer;
  final String conversationId;
  final String messageId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  DifyResponse({
    required this.answer,
    required this.conversationId,
    required this.messageId,
    required this.createdAt,
    this.metadata,
  });

  factory DifyResponse.fromJson(Map<String, dynamic> json) {
    return DifyResponse(
      answer: json['answer'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      messageId: json['message_id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'conversation_id': conversationId,
      'message_id': messageId,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class ConversationSession {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;

  ConversationSession({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
  });

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastMessageAt: DateTime.parse(
        json['last_message_at'] ?? DateTime.now().toIso8601String(),
      ),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((msg) => ChatMessage.fromJson(msg))
              .toList() ??
          [],
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? conversationId;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.conversationId,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      text: json['text'] ?? json['query'] ?? json['answer'] ?? '',
      isUser: json['is_user'] ?? json['role'] == 'user',
      timestamp: DateTime.parse(
        json['timestamp'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      conversationId: json['conversation_id'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'conversation_id': conversationId,
      'metadata': metadata,
    };
  }
}
