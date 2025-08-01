import 'dart:convert';
import '../models/chat_message.dart';
import '../services/n8n_chat_database.dart';
import '../services/n8n/prompt_api_service.dart';

class N8nChatService {
  static final N8nChatService _instance = N8nChatService._internal();
  factory N8nChatService() => _instance;
  N8nChatService._internal();

  final N8nChatDatabase _database = N8nChatDatabase();
  final PromptApiService _n8nAPI = PromptApiService();

  // Current conversation ID
  int? _currentConversationId;
  int? get currentConversationId => _currentConversationId;

  // ==========================================
  // CONVERSATION MANAGEMENT
  // ==========================================

  Future<int> startNewConversation({required int userId, String? title}) async {
    final conversationTitle =
        title ?? 'N8N Chat ${DateTime.now().toString().split(' ')[0]}';

    final conversationId = await _database.createConversation(
      userId: userId,
      title: conversationTitle,
      externalConversationId: 'n8n_${DateTime.now().millisecondsSinceEpoch}',
    );

    _currentConversationId = conversationId;

    // Log activity
    await _database.logUserActivity(
      userId: userId,
      activityType: 'conversation_started',
      activityDescription: 'Started new N8N conversation',
      additionalData: jsonEncode({
        'conversation_id': conversationId,
        'title': conversationTitle,
      }),
    );

    return conversationId;
  }

  Future<void> setCurrentConversation(int conversationId) async {
    _currentConversationId = conversationId;
  }

  Future<List<Map<String, dynamic>>> getConversationHistory(int userId) async {
    return await _database.getConversations(userId);
  }

  Future<void> endConversation(int conversationId, int userId) async {
    await _database.updateConversationStatus(conversationId, 'ended');

    // Log activity
    await _database.logUserActivity(
      userId: userId,
      activityType: 'conversation_ended',
      activityDescription: 'Ended N8N conversation',
      additionalData: jsonEncode({'conversation_id': conversationId}),
    );

    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
    }
  }

  // ==========================================
  // MESSAGE HANDLING
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

    // Save user message to database
    final userMessageId = await _database.saveMessage(
      conversationId: conversationId,
      messageType: 'user',
      content: message,
      metadata: jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'character_count': message.length,
      }),
    );

    // Create user message object
    // (not used for return, just for local reference if needed)

    // Log user activity
    await _database.logUserActivity(
      userId: userId,
      activityType: 'message_sent',
      activityDescription: 'User sent message to N8N',
      additionalData: jsonEncode({
        'conversation_id': conversationId,
        'message_length': message.length,
        'message_id': userMessageId,
      }),
    );

    // Send to N8N and get response
    try {
      final workflowExecutionId = await _database.saveWorkflowExecution(
        conversationId: conversationId,
        userId: userId,
        workflowId: 'n8n_chat_workflow',
        workflowName: 'N8N Chat Workflow',
        executionId: 'exec_${DateTime.now().millisecondsSinceEpoch}',
        workflowType: 'chat',
        status: 'running',
        inputData: jsonEncode({
          'user_message': message,
          'user_id': userId,
          'conversation_id': conversationId,
        }),
      );

      final startTime = DateTime.now();

      // Call N8N API
      final n8nResponse = await _n8nAPI.postPrompt(message: message);

      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      if (n8nResponse != null && n8nResponse.response.isNotEmpty) {
        final botResponse = n8nResponse.response;

        // Update workflow execution
        await _database.updateWorkflowExecution(
          workflowExecutionId: workflowExecutionId,
          status: 'success',
          outputData: jsonEncode({
            'response': botResponse,
            'success': n8nResponse.succes,
            'processing_time': executionTime,
          }),
          executionTimeMs: executionTime,
        );

        // Save bot response to database
        final botMessageId = await _database.saveMessage(
          conversationId: conversationId,
          messageType: 'assistant',
          content: botResponse,
          metadata: jsonEncode({
            'response_time_ms': executionTime,
            'workflow_used': 'n8n_chat_workflow',
            'execution_id': workflowExecutionId,
            'success': n8nResponse.succes,
          }),
        );

        // Log successful response
        await _database.logUserActivity(
          userId: userId,
          activityType: 'message_received',
          activityDescription: 'Received response from N8N',
          additionalData: jsonEncode({
            'conversation_id': conversationId,
            'response_time_ms': executionTime,
            'bot_message_id': botMessageId,
            'workflow_execution_id': workflowExecutionId,
          }),
        );

        return ChatMessage(
          id: botMessageId.toString(),
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('N8N API returned empty response');
      }
    } catch (e) {
      // Log error
      await _database.logUserActivity(
        userId: userId,
        activityType: 'error',
        activityDescription: 'Error sending message to N8N: $e',
        additionalData: jsonEncode({
          'conversation_id': conversationId,
          'error': e.toString(),
          'user_message': message,
        }),
      );

      // Return error message
      final errorMessageId = await _database.saveMessage(
        conversationId: conversationId,
        messageType: 'system',
        content:
            'Maaf, terjadi kesalahan saat memproses pesan Anda. Silakan coba lagi.',
        metadata: jsonEncode({
          'error': e.toString(),
          'error_time': DateTime.now().toIso8601String(),
        }),
      );

      return ChatMessage(
        id: errorMessageId.toString(),
        text:
            'Maaf, terjadi kesalahan saat memproses pesan Anda. Silakan coba lagi.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<List<ChatMessage>> getChatHistory(int conversationId) async {
    final messages = await _database.getMessages(conversationId);

    return messages.map((messageData) {
      return ChatMessage(
        id: messageData['id'].toString(),
        text: messageData['content'],
        isUser: messageData['message_type'] == 'user',
        timestamp: DateTime.parse(messageData['created_at']),
      );
    }).toList();
  }

  Future<List<ChatMessage>> getRecentChatHistory(
    int conversationId, {
    int limit = 50,
  }) async {
    final messages = await _database.getRecentMessages(
      conversationId,
      limit: limit,
    );

    return messages
        .map((messageData) {
          return ChatMessage(
            id: messageData['id'].toString(),
            text: messageData['content'],
            isUser: messageData['message_type'] == 'user',
            timestamp: DateTime.parse(messageData['created_at']),
          );
        })
        .toList()
        .reversed
        .toList(); // Reverse karena query DESC
  }

  // ==========================================
  // ANALYTICS & UTILITIES
  // ==========================================

  Future<Map<String, dynamic>> getChatAnalytics(int userId) async {
    final conversations = await _database.getConversations(userId);
    final activities = await _database.getUserActivities(userId);
    final dbStats = await _database.getDatabaseStats();

    int totalMessages = 0;
    int totalConversations = conversations.length;
    DateTime? lastActivity;

    for (var conversation in conversations) {
      final messages = await _database.getMessages(conversation['id']);
      totalMessages += messages.length;
    }

    if (activities.isNotEmpty) {
      lastActivity = DateTime.parse(activities.first['created_at']);
    }

    return {
      'total_conversations': totalConversations,
      'total_messages': totalMessages,
      'last_activity': lastActivity?.toIso8601String(),
      'database_stats': dbStats,
      'avg_messages_per_conversation':
          totalConversations > 0
              ? (totalMessages / totalConversations).round()
              : 0,
    };
  }

  Future<void> clearChatHistory() async {
    await _database.clearAllData();
    _currentConversationId = null;
  }

  Future<void> deleteConversation(int conversationId) async {
    await _database.deleteConversation(conversationId);
    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
    }
  }

  // ==========================================
  // OFFLINE SUPPORT
  // ==========================================

  Future<bool> isOfflineMode() async {
    // Simple check - bisa diperluas dengan connectivity check
    try {
      await _n8nAPI.postPrompt(message: "test");
      return false;
    } catch (e) {
      return true;
    }
  }

  Future<List<ChatMessage>> getOfflineChatHistory(int conversationId) async {
    // Return local chat history untuk offline mode
    return await getChatHistory(conversationId);
  }
}
