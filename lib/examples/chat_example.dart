import '../services/n8n_chat_service.dart';

class ChatExample {
  final N8nChatService _chatService = N8nChatService();

  // Example: Start a new conversation and send messages
  Future<void> exampleChatFlow() async {
    try {
      // 1. Start new conversation
      final conversationId = await _chatService.startNewConversation(
        userId: 1, // Replace with actual user ID
        title: 'Test Conversation N8N',
      );

      print('Started conversation: $conversationId');

      // 2. Send a message
      final response1 = await _chatService.sendMessage(
        message: 'Halo, saya ingin tanya tentang paket internet TSEL',
        userId: 1,
        conversationId: conversationId,
      );

      print('Bot Response 1: ${response1.text}');

      // 3. Send another message
      final response2 = await _chatService.sendMessage(
        message: 'Berapa harga paket paling murah?',
        userId: 1,
        conversationId: conversationId,
      );

      print('Bot Response 2: ${response2.text}');

      // 4. Get chat history
      final chatHistory = await _chatService.getChatHistory(conversationId);
      print('Total messages in conversation: ${chatHistory.length}');

      // 5. Print all messages
      for (var message in chatHistory) {
        final sender = message.isUser ? 'User' : 'Bot';
        print('[$sender]: ${message.text}');
      }

      // 6. Get analytics
      final analytics = await _chatService.getChatAnalytics(1);
      print('Chat Analytics: $analytics');
    } catch (e) {
      print('Error in chat flow: $e');
    }
  }

  // Example: Load conversation history
  Future<void> exampleLoadHistory(int userId) async {
    try {
      // Get all conversations for user
      final conversations = await _chatService.getConversationHistory(userId);

      print('User has ${conversations.length} conversations:');
      for (var conv in conversations) {
        print('- ${conv['conversation_title']} (${conv['status']})');

        // Get messages for this conversation
        final messages = await _chatService.getChatHistory(conv['id']);
        print('  Messages: ${messages.length}');
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  // Example: Offline mode check
  Future<void> exampleOfflineMode() async {
    final isOffline = await _chatService.isOfflineMode();

    if (isOffline) {
      print('App is in offline mode');

      // Load local chat history
      if (_chatService.currentConversationId != null) {
        final localHistory = await _chatService.getOfflineChatHistory(
          _chatService.currentConversationId!,
        );
        print('Local history has ${localHistory.length} messages');
      }
    } else {
      print('App is online');
    }
  }

  // Example: Database stats
  Future<void> showDatabaseStats() async {
    final analytics = await _chatService.getChatAnalytics(1);
    print('=== N8N Chat Database Stats ===');
    print('Total Conversations: ${analytics['total_conversations']}');
    print('Total Messages: ${analytics['total_messages']}');
    print('Last Activity: ${analytics['last_activity']}');
    print(
      'Avg Messages per Conversation: ${analytics['avg_messages_per_conversation']}',
    );
    print('Database Stats: ${analytics['database_stats']}');
  }
}

// How to use in your Flutter app:
/*
  In your chat screen or wherever you handle chat:

  final chatExample = ChatExample();
  
  // Start new conversation
  await chatExample.exampleChatFlow();
  
  // Or send individual message
  final chatService = N8nChatService();
  final response = await chatService.sendMessage(
    message: userInputText,
    userId: currentUserId,
  );
  
  // Update UI with response
  setState(() {
    messages.add(response);
  });
*/
