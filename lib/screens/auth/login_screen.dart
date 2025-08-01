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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Card(
              elevation: 2,
              color: AppColors.secondaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.smart_toy,
                            color: AppColors.primaryText,
                            size: 40,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Title
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.secondaryTextLight,
                          ),
                        ),
                        SizedBox(height: 32),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: AppColors.primaryText),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color:
                                  mailIsError
                                      ? AppColors.error
                                      : AppColors.secondaryTextLight,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color:
                                  mailIsError
                                      ? AppColors.error
                                      : AppColors.secondaryTextLight,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    mailIsError
                                        ? AppColors.error
                                        : AppColors.secondaryTextDark,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    mailIsError
                                        ? AppColors.error
                                        : AppColors.secondaryTextDark,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    mailIsError
                                        ? AppColors.error
                                        : AppColors.accent,
                                width: 2,
                              ),
                            ),
                            errorText: mailIsError ? emailErrorMessage : null,
                            errorStyle: TextStyle(color: AppColors.error),
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
                        SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          style: TextStyle(color: AppColors.primaryText),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              color:
                                  passIsError
                                      ? AppColors.error
                                      : AppColors.secondaryTextLight,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color:
                                  passIsError
                                      ? AppColors.error
                                      : AppColors.secondaryTextLight,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color:
                                    passIsError
                                        ? AppColors.error
                                        : AppColors.secondaryTextLight,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    passIsError
                                        ? AppColors.error
                                        : AppColors.secondaryTextDark,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    passIsError
                                        ? AppColors.error
                                        : AppColors.secondaryTextDark,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    passIsError
                                        ? AppColors.error
                                        : AppColors.accent,
                                width: 2,
                              ),
                            ),
                            errorText: passIsError ? passErrorMessage : null,
                            errorStyle: TextStyle(color: AppColors.error),
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
                        SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child:
                                _isLoading
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryText,
                                      ),
                                    )
                                    : Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: AppColors.secondaryTextLight,
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
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
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
    );
  }
}
