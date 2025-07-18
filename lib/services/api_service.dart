import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/api_response.dart';

class ApiService {
  // Untuk Web (Chrome/Edge)
  static const String baseUrl = 'http://localhost:8000/api';
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Untuk Android Emulator
  // static const String baseUrl = 'http://192.168.1.100:8000/api'; // Untuk Real Device

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Menyimpan token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Mengambil token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Menghapus token
  static Future<void> removeToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Headers dengan authorization
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Register
  static Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(data['data']);
        await saveToken(authResponse.token);
        return ApiResponse<AuthResponse>(
          success: true,
          message: data['message'],
          data: authResponse,
        );
      } else {
        return ApiResponse<AuthResponse>(
          success: false,
          message: data['message'] ?? 'Registration failed',
          errors: data['errors'],
        );
      }
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Login
  static Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data['data']);
        await saveToken(authResponse.token);
        return ApiResponse<AuthResponse>(
          success: true,
          message: data['message'],
          data: authResponse,
        );
      } else {
        return ApiResponse<AuthResponse>(
          success: false,
          message: data['message'] ?? 'Login failed',
          errors: data['errors'],
        );
      }
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Logout
  static Future<ApiResponse<void>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _getHeaders(),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      await removeToken();

      return ApiResponse<void>(
        success: response.statusCode == 200,
        message: data['message'] ?? 'Logout completed',
      );
    } catch (e) {
      await removeToken(); // Remove token even if request fails
      return ApiResponse<void>(success: false, message: 'Network error: $e');
    }
  }

  // Get current user
  static Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/user'),
        headers: await _getHeaders(),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(data['data']);
        return ApiResponse<User>(
          success: true,
          message: 'User retrieved successfully',
          data: user,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message: data['message'] ?? 'Failed to get user',
        );
      }
    } catch (e) {
      return ApiResponse<User>(success: false, message: 'Network error: $e');
    }
  }
}
