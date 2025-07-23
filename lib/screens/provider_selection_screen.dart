import 'package:difychatbot/services/api/me_api_service.dart';
import 'package:difychatbot/utils/string_capitalize.dart';
import 'package:difychatbot/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/me_response.dart';

class ProviderSelectionScreen extends StatefulWidget {
  @override
  _ProviderSelectionScreenState createState() =>
      _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends State<ProviderSelectionScreen> {
  final meAPI _meAPI = meAPI();
  UserData? currentUser;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  Future<void> initUser() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _meAPI.getUserProfile();

      if (response != null && response.data.isNotEmpty) {
        setState(() {
          currentUser = response.data.first;
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          currentUser = null;
          isLoading = false;
          errorMessage = 'Gagal mendapatkan data pengguna';
        });

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      setState(() {
        currentUser = null;
        isLoading = false;
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
        body:
            isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 16),
                      Text(
                        'Memuat data...',
                        style: TextStyle(
                          color: AppColors.secondaryTextLight,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              // Profile section with icon on left and user info on right
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/profile');
                                    },
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: AppColors.primaryText,
                                      child: Icon(
                                        Icons.person,
                                        size: 30,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/profile',
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (currentUser != null) ...[
                                            Text(
                                              '${currentUser!.namaDepan.capitalize()} ${currentUser!.namaBelakang.capitalize()}',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: AppColors.primaryText,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              currentUser!.email,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.primaryText
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ] else ...[
                                            Text(
                                              'Guest User',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: AppColors.primaryText,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'guest@example.com',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.primaryText
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // SizedBox(height: 20),
                              // Text(
                              //   'Selamat Datang!',
                              //   style: TextStyle(
                              //     fontSize: 24,
                              //     fontWeight: FontWeight.bold,
                              //     color: AppColors.primaryText,
                              //   ),
                              // ),
                              SizedBox(height: 20),
                              Text(
                                'Pilih AI Provider yang ingin Anda gunakan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.primaryText.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Provider Selection Cards
                        Expanded(
                          child: Column(
                            children: [
                              _buildProviderCard(
                                provider: 'DIFY',
                                title: 'DIFY AI',
                                description:
                                    'AI conversational yang canggih dengan natural language processing.',
                                icon: Icons.smart_toy,
                                color: AppColors.accent,
                                isSelected: false,
                              ),
                              SizedBox(height: 20),
                              _buildProviderCard(
                                provider: 'N8N',
                                title: 'N8N Workflow',
                                description:
                                    'Automation workflow yang powerful untuk integrasi berbagai layanan.',
                                icon: Icons.settings_suggest,
                                color: AppColors.warning,
                                isSelected: false,
                              ),
                            ],
                          ),
                        ),

                        // Footer Info
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondaryTextDark.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.secondaryTextLight,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Anda dapat mengubah provider kapan saja melalui menu pengaturan di halaman chat.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondaryTextLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // Version Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TSEL AI Chatbot v1.0.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryTextDark,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.secondaryTextDark,
                            ),
                          ],
                        ),
                      ],
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
      duration: Duration(milliseconds: 200),
      child: Card(
        elevation: 4,
        color: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                isSelected
                    ? color
                    : AppColors.secondaryTextDark.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectProvider(provider),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryTextLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.secondaryTextLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
