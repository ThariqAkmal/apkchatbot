import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/me_response.dart';

class meAPI {
  final String apiUrl = dotenv.env['API_URL'].toString();

  Future<MeResponse?> getUserProfile() async {
    final url = Uri.parse('$apiUrl/auth-api/get/me');
    final token = await getToken();
    if (token == null) {
      return null; // Token tidak ditemukan
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Parse response menggunakan model MeResponse
        final meResponse = MeResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        return meResponse;
      } else {
        return null;
      }
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
