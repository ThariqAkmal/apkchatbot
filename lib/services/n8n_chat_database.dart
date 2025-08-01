import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class N8nChatDatabase {
  static final N8nChatDatabase _instance = N8nChatDatabase._internal();
  factory N8nChatDatabase() => _instance;
  N8nChatDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite is not supported on Web. Use SharedPreferences or Web SQL instead.',
      );
    }

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'n8n_chat_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Table untuk conversations
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        conversation_title TEXT,
        external_conversation_id TEXT,
        status TEXT DEFAULT 'active',
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Table untuk messages
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        message_type TEXT NOT NULL,
        content TEXT NOT NULL,
        external_message_id TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    // Table untuk n8n workflow executions
    await db.execute('''
      CREATE TABLE n8n_workflows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        workflow_id TEXT NOT NULL,
        workflow_name TEXT,
        execution_id TEXT,
        workflow_type TEXT DEFAULT 'chat',
        status TEXT DEFAULT 'running',
        input_data TEXT,
        output_data TEXT,
        execution_time_ms INTEGER,
        error_message TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    // Table untuk user activities
    await db.execute('''
      CREATE TABLE user_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        activity_type TEXT NOT NULL,
        activity_description TEXT,
        session_id TEXT,
        additional_data TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes untuk performa
    await db.execute(
      'CREATE INDEX idx_conversations_user_id ON conversations(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_conversation_id ON messages(conversation_id)',
    );
    await db.execute(
      'CREATE INDEX idx_workflows_conversation_id ON n8n_workflows(conversation_id)',
    );
    await db.execute(
      'CREATE INDEX idx_activities_user_id ON user_activities(user_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades jika diperlukan
    if (oldVersion < 2) {
      // Tambahan upgrade logic di sini jika perlu
    }
  }

  // ==========================================
  // CONVERSATION METHODS
  // ==========================================

  Future<int> createConversation({
    required int userId,
    required String title,
    String? externalConversationId,
    String status = 'active',
    String? metadata,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('conversations', {
      'user_id': userId,
      'conversation_title': title,
      'external_conversation_id': externalConversationId,
      'status': status,
      'metadata': metadata,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    final db = await database;
    return await db.query(
      'conversations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getConversation(int conversationId) async {
    final db = await database;
    final result = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateConversationStatus(
    int conversationId,
    String status,
  ) async {
    final db = await database;
    await db.update(
      'conversations',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // ==========================================
  // MESSAGE METHODS
  // ==========================================

  Future<int> saveMessage({
    required int conversationId,
    required String messageType,
    required String content,
    String? externalMessageId,
    String? metadata,
  }) async {
    final db = await database;

    final messageId = await db.insert('messages', {
      'conversation_id': conversationId,
      'message_type': messageType,
      'content': content,
      'external_message_id': externalMessageId,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Update conversation updated_at
    await db.update(
      'conversations',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return messageId;
  }

  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentMessages(
    int conversationId, {
    int limit = 50,
  }) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // ==========================================
  // N8N WORKFLOW METHODS
  // ==========================================

  Future<int> saveWorkflowExecution({
    required int conversationId,
    required int userId,
    required String workflowId,
    String? workflowName,
    String? executionId,
    String workflowType = 'chat',
    String status = 'running',
    String? inputData,
    String? outputData,
    int? executionTimeMs,
    String? errorMessage,
  }) async {
    final db = await database;

    return await db.insert('n8n_workflows', {
      'conversation_id': conversationId,
      'user_id': userId,
      'workflow_id': workflowId,
      'workflow_name': workflowName,
      'execution_id': executionId,
      'workflow_type': workflowType,
      'status': status,
      'input_data': inputData,
      'output_data': outputData,
      'execution_time_ms': executionTimeMs,
      'error_message': errorMessage,
      'created_at': DateTime.now().toIso8601String(),
      'completed_at':
          status != 'running' ? DateTime.now().toIso8601String() : null,
    });
  }

  Future<void> updateWorkflowExecution({
    required int workflowExecutionId,
    String? status,
    String? outputData,
    int? executionTimeMs,
    String? errorMessage,
  }) async {
    final db = await database;

    Map<String, dynamic> updateData = {};
    if (status != null) updateData['status'] = status;
    if (outputData != null) updateData['output_data'] = outputData;
    if (executionTimeMs != null)
      updateData['execution_time_ms'] = executionTimeMs;
    if (errorMessage != null) updateData['error_message'] = errorMessage;

    if (status != null && status != 'running') {
      updateData['completed_at'] = DateTime.now().toIso8601String();
    }

    await db.update(
      'n8n_workflows',
      updateData,
      where: 'id = ?',
      whereArgs: [workflowExecutionId],
    );
  }

  Future<List<Map<String, dynamic>>> getWorkflowExecutions(
    int conversationId,
  ) async {
    final db = await database;
    return await db.query(
      'n8n_workflows',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
    );
  }

  // ==========================================
  // USER ACTIVITY METHODS
  // ==========================================

  Future<int> logUserActivity({
    required int userId,
    required String activityType,
    String? activityDescription,
    String? sessionId,
    String? additionalData,
  }) async {
    final db = await database;

    return await db.insert('user_activities', {
      'user_id': userId,
      'activity_type': activityType,
      'activity_description': activityDescription,
      'session_id': sessionId,
      'additional_data': additionalData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserActivities(
    int userId, {
    int limit = 100,
  }) async {
    final db = await database;
    return await db.query(
      'user_activities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_activities');
    await db.delete('n8n_workflows');
    await db.delete('messages');
    await db.delete('conversations');
  }

  Future<void> deleteConversation(int conversationId) async {
    final db = await database;
    // CASCADE akan otomatis delete messages dan workflows
    await db.delete(
      'conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final conversationCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM conversations'),
        ) ??
        0;

    final messageCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM messages'),
        ) ??
        0;

    final workflowCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM n8n_workflows'),
        ) ??
        0;

    final activityCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM user_activities'),
        ) ??
        0;

    return {
      'conversations': conversationCount,
      'messages': messageCount,
      'workflows': workflowCount,
      'activities': activityCount,
    };
  }
}
