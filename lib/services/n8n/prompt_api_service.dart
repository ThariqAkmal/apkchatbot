import 'dart:convert';

import 'package:difychatbot/models/n8n_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PromptApiService {
  final String n8nUrl = dotenv.env['N8N_URL'].toString();

  Future<N8NModels?> postPrompt({String? message}) async {
    final url = Uri.parse('$n8nUrl/webhook-test/test-mode/core');
    final token = await _getToken();
    if (token == null) {
      return null; // Token tidak ditemukan
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      print('Response from MURNI N8N: ${response}');
      if (response.statusCode == 200) {
        final n8nResponse = N8NModels.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        print('Response from N8N: ${n8nResponse.response}');
        return n8nResponse;
      } else {
        return null;
      }
    } catch (e) {
      print('terjadi kesalahan: $e');
      return null;
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
