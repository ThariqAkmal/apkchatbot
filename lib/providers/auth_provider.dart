import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final token = await ApiService.getToken();
    if (token != null) {
      final response = await ApiService.getCurrentUser();
      if (response.success && response.data != null) {
        _user = response.data;
        _isAuthenticated = true;
      } else {
        await ApiService.removeToken();
        _isAuthenticated = false;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Register
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    if (response.success && response.data != null) {
      _user = response.data!.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } else {
      _isLoading = false;
      notifyListeners();
      return response.message; // Error message
    }
  }

  // Login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.login(email: email, password: password);

    if (response.success && response.data != null) {
      _user = response.data!.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } else {
      _isLoading = false;
      notifyListeners();
      return response.message; // Error message
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await ApiService.logout();
    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }
}
