import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/n8n/prompt_api_service.dart';

class WebChatService {
  static final WebChatService _instance = WebChatService._internal();
  factory WebChatService() => _instance;
  WebChatService._internal();

  final PromptApiService _n8nAPI = PromptApiService();

  // Keys for SharedPreferences
  static const String _conversationsKey = 'n8n_conversations';
  static const String _messagesPrefix = 'n8n_messages_';
  static const String _currentConversationKey = 'n8n_current_conversation';

  int? _currentConversationId;
  int? get currentConversationId => _currentConversationId;

  // ==========================================
  // CONVERSATION MANAGEMENT (Web-compatible)
  // ==========================================

  Future<int> startNewConversation({required int userId, String? title}) async {
    final prefs = await SharedPreferences.getInstance();
    final conversationTitle =
        title ?? 'N8N Chat ${DateTime.now().toString().split(' ')[0]}';

    // Generate conversation ID
    final conversationId = DateTime.now().millisecondsSinceEpoch;

    // Get existing conversations
    final conversations = await _getStoredConversations();

    // Add new conversation
    final newConversation = {
      'id': conversationId,
      'user_id': userId,
      'conversation_title': conversationTitle,
      'external_conversation_id': 'n8n_$conversationId',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    conversations.add(newConversation);

    // Save to SharedPreferences
    await prefs.setString(_conversationsKey, jsonEncode(conversations));
    await prefs.setInt(_currentConversationKey, conversationId);

    _currentConversationId = conversationId;

    print('✅ Started new conversation: $conversationId');
    return conversationId;
  }

  Future<List<Map<String, dynamic>>> getConversationHistory(int userId) async {
    final conversations = await _getStoredConversations();
    return conversations.where((conv) => conv['user_id'] == userId).toList();
  }

  Future<List<Map<String, dynamic>>> _getStoredConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString(_conversationsKey);

    if (conversationsJson == null) return [];

    try {
      final List<dynamic> conversationsList = jsonDecode(conversationsJson);
      return conversationsList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error parsing conversations: $e');
      return [];
    }
  }

  // ==========================================
  // MESSAGE HANDLING (Web-compatible)
  // ==========================================

  Future<ChatMessage> sendMessage({
    required String message,
    required int userId,
    int? conversationId,
  }) async {
    // Ensure we have a conversation
    conversationId ??= _currentConversationId;
    if (conversationId == null) {
      conversationId = await startNewConversation(userId: userId);
    }

    final prefs = await SharedPreferences.getInstance();

    // Save user message
    await _saveMessageToStorage(
      conversationId: conversationId,
      messageType: 'user',
      content: message,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        'character_count': message.length,
      },
    );

    print('💬 User message saved: $message');

    // Send to N8N and get response
    try {
      final startTime = DateTime.now();
      final n8nResponse = await _n8nAPI.postPrompt(message: message);
      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      if (n8nResponse != null && n8nResponse.response.isNotEmpty) {
        final botResponse = n8nResponse.response;

        // Save bot response
        await _saveMessageToStorage(
          conversationId: conversationId,
          messageType: 'assistant',
          content: botResponse,
          metadata: {
            'response_time_ms': executionTime,
            'workflow_used': 'n8n_chat_workflow',
            'success': n8nResponse.succes,
          },
        );

        print('🤖 Bot response saved: $botResponse');

        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('N8N API returned empty response');
      }
    } catch (e) {
      print('❌ Error sending message to N8N: $e');

      // Save error message
      await _saveMessageToStorage(
        conversationId: conversationId,
        messageType: 'system',
        content:
            'Maaf, terjadi kesalahan saat memproses pesan Anda. Silakan coba lagi.',
        metadata: {
          'error': e.toString(),
          'error_time': DateTime.now().toIso8601String(),
        },
      );

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'Maaf, terjadi kesalahan saat memproses pesan Anda. Silakan coba lagi.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<void> _saveMessageToStorage({
    required int conversationId,
    required String messageType,
    required String content,
    required Map<String, dynamic> metadata,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesKey = '$_messagesPrefix$conversationId';

    // Get existing messages
    final messages = await _getStoredMessages(conversationId);

    // Add new message
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'conversation_id': conversationId,
      'message_type': messageType,
      'content': content,
      'metadata': jsonEncode(metadata),
      'created_at': DateTime.now().toIso8601String(),
    };

    messages.add(newMessage);

    // Save back to SharedPreferences
    await prefs.setString(messagesKey, jsonEncode(messages));

    // Update conversation updated_at
    await _updateConversationTimestamp(conversationId);
  }

  Future<List<Map<String, dynamic>>> _getStoredMessages(
    int conversationId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesKey = '$_messagesPrefix$conversationId';
    final messagesJson = prefs.getString(messagesKey);

    if (messagesJson == null) return [];

    try {
      final List<dynamic> messagesList = jsonDecode(messagesJson);
      return messagesList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error parsing messages: $e');
      return [];
    }
  }

  Future<void> _updateConversationTimestamp(int conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final conversations = await _getStoredConversations();

    final conversationIndex = conversations.indexWhere(
      (conv) => conv['id'] == conversationId,
    );
    if (conversationIndex != -1) {
      conversations[conversationIndex]['updated_at'] =
          DateTime.now().toIso8601String();
      await prefs.setString(_conversationsKey, jsonEncode(conversations));
    }
  }

  Future<List<ChatMessage>> getChatHistory(int conversationId) async {
    final messages = await _getStoredMessages(conversationId);

    return messages.map((messageData) {
      return ChatMessage(
        id: messageData['id'].toString(),
        text: messageData['content'],
        isUser: messageData['message_type'] == 'user',
        timestamp: DateTime.parse(messageData['created_at']),
      );
    }).toList();
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  Future<Map<String, dynamic>> getChatAnalytics(int userId) async {
    final conversations = await getConversationHistory(userId);
    int totalMessages = 0;

    for (var conversation in conversations) {
      final messages = await _getStoredMessages(conversation['id']);
      totalMessages += messages.length;
    }

    return {
      'total_conversations': conversations.length,
      'total_messages': totalMessages,
      'last_activity':
          conversations.isNotEmpty ? conversations.first['updated_at'] : null,
      'avg_messages_per_conversation':
          conversations.isNotEmpty
              ? (totalMessages / conversations.length).round()
              : 0,
      'storage_type': 'SharedPreferences (Web)',
    };
  }

  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();

    // Get all conversation IDs first
    final conversations = await _getStoredConversations();

    // Remove all messages
    for (var conversation in conversations) {
      final messagesKey = '$_messagesPrefix${conversation['id']}';
      await prefs.remove(messagesKey);
    }

    // Remove conversations and current conversation
    await prefs.remove(_conversationsKey);
    await prefs.remove(_currentConversationKey);

    _currentConversationId = null;
    print('🗑️ All chat history cleared');
  }

  Future<bool> isOfflineMode() async {
    try {
      await _n8nAPI.postPrompt(message: "test");
      return false;
    } catch (e) {
      return true;
    }
  }

  Future<void> setCurrentConversation(int conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentConversationKey, conversationId);
    _currentConversationId = conversationId;
  }

  Future<void> loadCurrentConversation() async {
    final prefs = await SharedPreferences.getInstance();
    _currentConversationId = prefs.getInt(_currentConversationKey);
  }
}
