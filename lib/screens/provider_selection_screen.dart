import 'package:difychatbot/services/api/me_api_service.dart';
import 'package:difychatbot/utils/string_capitalize.dart';
import 'package:difychatbot/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/me_response.dart';
import '../components/skeleton_loader.dart';

class ProviderSelectionScreen extends StatefulWidget {
  @override
  _ProviderSelectionScreenState createState() =>
      _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends State<ProviderSelectionScreen> {
  final meAPI _meAPI = meAPI();
  UserData? currentUser;
  bool isLoading = true;
  bool isUserInfoLoading = true; // Loading khusus untuk info user
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  Future<void> initUser() async {
    setState(() {
      isLoading = false; // Set ke false agar halaman muncul
      isUserInfoLoading = true; // Loading khusus untuk user info
      errorMessage = null;
    });

    try {
      final response = await _meAPI.getUserProfile();

      if (response != null && response.data.isNotEmpty) {
        setState(() {
          currentUser = response.data.first;
          isUserInfoLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          currentUser = null;
          isUserInfoLoading = false;
          errorMessage = 'Gagal mendapatkan data pengguna';
        });

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      setState(() {
        currentUser = null;
        isUserInfoLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _selectProvider(String provider) async {
    // Save selected provider to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_provider', provider);

    // Navigate to home screen with selected provider
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
      arguments: {'provider': provider},
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Mencegah kembali ke login screen
        // User harus logout melalui menu
        return false;
      },
      child: Scaffold(
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Modern Header with Gradient
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gradientStart.withOpacity(0.3),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile section with modern design
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.whiteText,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 0,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 32,
                                  color: AppColors.gradientMiddle,
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/profile');
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isUserInfoLoading) ...[
                                      // Skeleton loader untuk nama dan email
                                      UserInfoSkeleton(),
                                    ] else if (currentUser != null) ...[
                                      Text(
                                        'Welcome back,',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.whiteText
                                              .withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${currentUser!.namaDepan.capitalize()} ${currentUser!.namaBelakang.capitalize()}',
                                        style: TextStyle(
                                          fontSize: 22,
                                          color: AppColors.whiteText,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        currentUser!.email,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.whiteText
                                              .withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'Welcome,',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.whiteText
                                              .withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Guest User',
                                        style: TextStyle(
                                          fontSize: 22,
                                          color: AppColors.whiteText,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'guest@example.com',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.whiteText
                                              .withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 28),
                        Text(
                          'Choose Your AI Provider',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.whiteText,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Select the AI service that best fits your needs',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.whiteText.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  // Modern Provider Selection Cards
                  Expanded(
                    child: Column(
                      children: [
                        _buildProviderCard(
                          provider: 'DIFY',
                          title: 'DIFY AI',
                          description:
                              'Advanced conversational AI with natural language processing and smart responses.',
                          icon: Icons.auto_awesome,
                          color: AppColors.gradientStart,
                          isSelected: false,
                        ),
                        SizedBox(height: 24),
                        _buildProviderCard(
                          provider: 'N8N',
                          title: 'N8N Workflow',
                          description:
                              'Powerful automation workflows for seamless integration with various services.',
                          icon: Icons.hub_rounded,
                          color: AppColors.gradientEnd,
                          isSelected: false,
                        ),
                      ],
                    ),
                  ),

                  // Modern Footer Info
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.subtleGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.gradientStart,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'You can switch providers anytime through the settings menu in the chat interface.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Modern Version Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.subtleGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.gradientStart,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'TSEL AI Assistant v1.0.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gradientStart,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildProviderCard({
    required String provider,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              spreadRadius: 0,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          color: AppColors.primaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? color : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _selectProvider(provider),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  // Modern icon container with gradient
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Modern arrow with gradient background
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.subtleGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
