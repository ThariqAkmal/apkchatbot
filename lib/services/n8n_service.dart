import 'dart:convert';
import 'package:http/http.dart' as http;

class N8nService {
  // URL n8n instance yang akan diberikan oleh teman Anda
  static const String baseUrl =
      'https://your-n8n-instance.com'; // Ganti dengan URL n8n yang sebenarnya
  static const String apiKey =
      'YOUR_N8N_API_KEY'; // API Key n8n (jika diperlukan)

  // Webhook URLs untuk berbagai keperluan
  static const String chatWebhookUrl = '$baseUrl/webhook/chat';
  static const String userActivityWebhookUrl = '$baseUrl/webhook/user-activity';
  static const String feedbackWebhookUrl = '$baseUrl/webhook/feedback';

  // Headers untuk request
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
  };

  // 1. Trigger workflow ketika user mengirim pesan
  static Future<Map<String, dynamic>?> triggerChatWorkflow({
    required String userId,
    required String message,
    required String conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(chatWebhookUrl),
        headers: headers,
        body: jsonEncode({
          'trigger': 'chat_message',
          'user_id': userId,
          'message': message,
          'conversation_id': conversationId,
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error triggering chat workflow: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error triggering chat workflow: $e');
      return null;
    }
  }

  // 2. Trigger workflow untuk user activity (login, logout, dll)
  static Future<Map<String, dynamic>?> triggerUserActivityWorkflow({
    required String userId,
    required String
    activity, // 'login', 'logout', 'register', 'chat_start', 'chat_end'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(userActivityWebhookUrl),
        headers: headers,
        body: jsonEncode({
          'trigger': 'user_activity',
          'user_id': userId,
          'activity': activity,
          'timestamp': DateTime.now().toIso8601String(),
          'data': additionalData ?? {},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
          'Error triggering user activity workflow: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('Error triggering user activity workflow: $e');
      return null;
    }
  }

  // 3. Trigger workflow untuk feedback
  static Future<Map<String, dynamic>?> triggerFeedbackWorkflow({
    required String userId,
    required String messageId,
    required String feedbackType, // 'like', 'dislike', 'report'
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(feedbackWebhookUrl),
        headers: headers,
        body: jsonEncode({
          'trigger': 'feedback',
          'user_id': userId,
          'message_id': messageId,
          'feedback_type': feedbackType,
          'comment': comment,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error triggering feedback workflow: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error triggering feedback workflow: $e');
      return null;
    }
  }

  // 4. Webhook untuk menerima data dari n8n (jika ada response balik)
  static Future<Map<String, dynamic>?> handleN8nCallback({
    required Map<String, dynamic> callbackData,
  }) async {
    try {
      // Process callback data dari n8n
      final workflowId = callbackData['workflow_id'];
      final executionId = callbackData['execution_id'];
      final result = callbackData['result'];

      print('N8n callback received: $workflowId - $executionId');

      return {
        'status': 'success',
        'workflow_id': workflowId,
        'execution_id': executionId,
        'processed_at': DateTime.now().toIso8601String(),
        'result': result,
      };
    } catch (e) {
      print('Error handling n8n callback: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'processed_at': DateTime.now().toIso8601String(),
      };
    }
  }

  // 5. Get workflow execution status
  static Future<Map<String, dynamic>?> getWorkflowStatus({
    required String executionId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/executions/$executionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error getting workflow status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting workflow status: $e');
      return null;
    }
  }

  // 6. Test connection ke n8n
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/healthz'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error testing n8n connection: $e');
      return false;
    }
  }
}
