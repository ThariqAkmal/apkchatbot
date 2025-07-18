import 'dart:convert';
import 'package:http/http.dart' as http;

class DifyService {
  // URL endpoint yang akan diberikan oleh teman Anda
  static const String baseUrl =
      'https://api.dify.ai/v1'; // Ganti dengan URL Dify yang sebenarnya
  static const String apiKey = 'YOUR_DIFY_API_KEY'; // API Key dari Dify

  // Untuk n8n webhook (jika diperlukan)
  static const String n8nWebhookUrl =
      'https://your-n8n-instance.com/webhook/chatbot'; // URL n8n webhook

  // Headers untuk request
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  // Fungsi untuk mengirim pesan ke Dify
  static Future<String> sendMessage({
    required String message,
    required String userId,
    String? conversationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat-messages'),
        headers: headers,
        body: jsonEncode({
          'inputs': {},
          'query': message,
          'user': userId,
          'conversation_id': conversationId,
          'response_mode': 'blocking',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'Maaf, saya tidak dapat memproses pesan Anda.';
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return 'Maaf, terjadi kesalahan dalam memproses pesan Anda.';
      }
    } catch (e) {
      print('Error sending message to Dify: $e');
      return 'Maaf, tidak dapat terhubung ke server saat ini.';
    }
  }

  // Fungsi untuk mendapatkan riwayat percakapan
  static Future<List<Map<String, dynamic>>> getConversationHistory({
    required String conversationId,
    String? userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/messages?conversation_id=$conversationId&user=$userId',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        print('Error getting conversation history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting conversation history: $e');
      return [];
    }
  }

  // Fungsi untuk integrasi dengan n8n (jika diperlukan)
  static Future<Map<String, dynamic>?> triggerN8nWorkflow({
    required String trigger,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(n8nWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trigger': trigger,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error triggering n8n workflow: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error triggering n8n workflow: $e');
      return null;
    }
  }
}
