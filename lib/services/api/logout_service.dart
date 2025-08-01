import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LogoutService {
  /// Logout user dan hapus token dari SharedPreferences
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Hapus token dari SharedPreferences
      bool tokenRemoved = await prefs.remove('auth_token');

      // Opsional: Hapus semua data terkait user lainnya
      // await prefs.remove('user_data');
      // await prefs.remove('user_profile');

      return tokenRemoved;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  /// Logout dengan UI feedback dan navigasi
  static Future<void> logoutWithNavigation(BuildContext context) async {
    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Logging out...'),
                ],
              ),
            ),
          ),
    );

    try {
      final logoutService = LogoutService();
      final success = await logoutService.logout();

      // Tutup loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Tampilkan success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil keluar. Sampai jumpa lagi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Tunggu sebentar untuk user membaca pesan
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate ke login page dan hapus semua history
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // Tampilkan error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Tutup loading dialog jika masih ada
      Navigator.of(context, rootNavigator: true).pop();

      // Tampilkan error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Logout dengan navigasi manual (jika tidak menggunakan named routes)
  static Future<void> logoutWithManualNavigation(
    BuildContext context,
    Widget loginPage,
  ) async {
    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Logging out...'),
                ],
              ),
            ),
          ),
    );

    try {
      final logoutService = LogoutService();
      final success = await logoutService.logout();

      // Tutup loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Tampilkan success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil keluar. Sampai jumpa lagi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Tunggu sebentar untuk user membaca pesan
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate ke login page dan hapus semua history
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => loginPage),
          (route) => false,
        );
      } else {
        // Tampilkan error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout. Silakan coba lagi.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Tutup loading dialog jika masih ada
      Navigator.of(context, rootNavigator: true).pop();

      // Tampilkan error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Konfirmasi logout dengan dialog
  static Future<void> confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Konfirmasi Logout'),
            content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      await logoutWithNavigation(context);
    }
  }

  /// Check apakah user sudah login (ada token)
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Get token dari SharedPreferences
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
}
