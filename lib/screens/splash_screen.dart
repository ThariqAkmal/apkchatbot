import 'package:flutter/material.dart';
import '../services/api/logout_service.dart';
import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for animation to complete
    await Future.delayed(Duration(seconds: 3));

    // Check login status using LogoutService
    final isLoggedIn = await LogoutService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        // User is logged in, always navigate to provider selection
        // Let user choose or confirm their provider choice
        Navigator.of(context).pushReplacementNamed('/provider-selection');
      } else {
        // User is not logged in, navigate to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBackground,
              AppColors.secondaryBackground,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo with Modern Design
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gradientStart.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.gradientEnd.withOpacity(0.2),
                              spreadRadius: 0,
                              blurRadius: 40,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Modern fallback design
                              return Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.whiteText,
                                  size: 64,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 40),

                      // App Name with Modern Typography
                      Text(
                        'Tsel AI-Assistant',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),

                      SizedBox(height: 8),

                      // App Tagline with Gradient Text Effect
                      ShaderMask(
                        shaderCallback:
                            (bounds) =>
                                AppColors.primaryGradient.createShader(bounds),
                        child: Text(
                          'Your AI-Powered Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.whiteText,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      SizedBox(height: 60),

                      // Modern Loading Indicator
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowMedium,
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.gradientMiddle,
                                ),
                                backgroundColor: AppColors.borderLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
