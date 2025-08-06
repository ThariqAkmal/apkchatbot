import 'package:difychatbot/services/api/login_api_service.dart';
import 'package:difychatbot/services/api/me_api_service.dart';
import 'package:difychatbot/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String emailErrorMessage = '';
  String passErrorMessage = '';
  bool mailIsError = false;
  bool passIsError = false;
  final LoginAPI _loginAPI = LoginAPI();
  final meAPI _meAPI = meAPI();

  @override
  void initState() {
    super.initState();
    // Add listeners to clear error when user types
    _emailController.addListener(_clearEmailError);
    _passwordController.addListener(_clearPasswordError);
  }

  void _clearEmailError() {
    if (mailIsError) {
      setState(() {
        mailIsError = false;
        emailErrorMessage = '';
      });
    }
  }

  void _clearPasswordError() {
    if (passIsError) {
      setState(() {
        passIsError = false;
        passErrorMessage = '';
      });
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearEmailError);
    _passwordController.removeListener(_clearPasswordError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        emailErrorMessage = '';
        passErrorMessage = '';
        mailIsError = false;
        passIsError = false;
        _isLoading = true;
      });

      try {
        // Step 1: Call Login API
        final loginResponse = await _loginAPI.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (loginResponse == null) {
          // Login failed - wrong credentials
          setState(() {
            _isLoading = false;
            emailErrorMessage = 'Email atau password salah';
            passErrorMessage = 'Email atau password salah';
            mailIsError = true;
            passIsError = true;
          });

          // Also show a snackbar for immediate feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email atau password salah. Silakan coba lagi.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Step 2: Call Me API to get user profile
        final meResponse = await _meAPI.getUserProfile();

        setState(() {
          _isLoading = false;
        });

        if (meResponse != null && meResponse.data.isNotEmpty) {
          // Both APIs successful - show success message then navigate
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login berhasil! Selamat datang.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to provider selection after a short delay
          Future.delayed(Duration(milliseconds: 300), () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/provider-selection',
              (route) => false,
            );
          });
        } else {
          _showErrorDialog('Gagal mendapatkan data profil. Silakan coba lagi.');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        _showErrorDialog('Oppps Terjadi kesalahan');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.primaryBackground,
              AppColors.secondaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                color: AppColors.primaryBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: AppColors.borderLight, width: 1),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Modern Logo with Gradient
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gradientStart.withOpacity(
                                      0.3,
                                    ),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: AppColors.whiteText,
                                size: 48,
                              ),
                            ),
                            SizedBox(height: 32),

                            // Modern Title with Gradient Text
                            ShaderMask(
                              shaderCallback:
                                  (bounds) => AppColors.primaryGradient
                                      .createShader(bounds),
                              child: Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.whiteText,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sign in to continue your AI journey',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 40),

                            // Modern Email Field
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    spreadRadius: 0,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: TextStyle(
                                    color:
                                        mailIsError
                                            ? AppColors.error
                                            : AppColors.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Container(
                                    margin: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.subtleGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.email_outlined,
                                      color: AppColors.gradientStart,
                                      size: 20,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color:
                                          mailIsError
                                              ? AppColors.error
                                              : AppColors.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color:
                                          mailIsError
                                              ? AppColors.error
                                              : AppColors.gradientMiddle,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 2,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 2,
                                    ),
                                  ),
                                  errorText:
                                      mailIsError ? emailErrorMessage : null,
                                  errorStyle: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 20),

                            // Modern Password Field
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    spreadRadius: 0,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                    color:
                                        passIsError
                                            ? AppColors.error
                                            : AppColors.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Container(
                                    margin: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.subtleGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.lock_outline,
                                      color: AppColors.gradientStart,
                                      size: 20,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color:
                                          passIsError
                                              ? AppColors.error
                                              : AppColors.secondaryText,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardBackground,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color:
                                          passIsError
                                              ? AppColors.error
                                              : AppColors.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color:
                                          passIsError
                                              ? AppColors.error
                                              : AppColors.gradientMiddle,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 2,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 2,
                                    ),
                                  ),
                                  errorText:
                                      passIsError ? passErrorMessage : null,
                                  errorStyle: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 32),

                            // Modern Gradient Login Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gradientStart.withOpacity(
                                      0.3,
                                    ),
                                    spreadRadius: 0,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.whiteText,
                                          ),
                                        )
                                        : Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.whiteText,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                              ),
                            ),
                            SizedBox(height: 32),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => RegisterScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  child: ShaderMask(
                                    shaderCallback:
                                        (bounds) => AppColors.primaryGradient
                                            .createShader(bounds),
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.whiteText,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
