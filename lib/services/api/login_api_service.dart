import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/login_response.dart';

class LoginAPI {
  final String apiUrl = dotenv.env['API_URL'].toString();

  Future<LoginResponse?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth-api/post/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final loginResponse = loginResponseFromJson(response.body);
        print(loginResponse);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', loginResponse.token);

        print(loginResponse);
        return loginResponse;
      } else {
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
}
