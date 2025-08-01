import 'package:flutter/material.dart';
import '../services/api/logout_service.dart';
import '../screens/auth/login_screen.dart';

class LogoutButton extends StatelessWidget {
  final bool showConfirmation;
  final String buttonText;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const LogoutButton({
    Key? key,
    this.showConfirmation = true,
    this.buttonText = 'Logout',
    this.icon = Icons.logout,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleLogout(context),
      icon: Icon(icon),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.red,
        foregroundColor: textColor ?? Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (showConfirmation) {
      // Tampilkan konfirmasi logout
      await LogoutService.confirmLogout(context);
    } else {
      // Langsung logout tanpa konfirmasi
      await LogoutService.logoutWithManualNavigation(context, LoginScreen());
    }
  }
}

// Widget untuk menu item logout (misalnya di Drawer atau AppBar)
class LogoutMenuItem extends StatelessWidget {
  final bool showConfirmation;

  const LogoutMenuItem({Key? key, this.showConfirmation = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.red),
      title: Text('Logout', style: TextStyle(color: Colors.red)),
      onTap: () => _handleLogout(context),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Tutup drawer jika ada
    Navigator.of(context).pop();

    if (showConfirmation) {
      await LogoutService.confirmLogout(context);
    } else {
      await LogoutService.logoutWithManualNavigation(context, LoginScreen());
    }
  }
}

// Widget untuk floating action button logout
class LogoutFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => LogoutService.confirmLogout(context),
      backgroundColor: Colors.red,
      child: Icon(Icons.logout, color: Colors.white),
      tooltip: 'Logout',
    );
  }
}
