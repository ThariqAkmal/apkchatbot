import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientStart.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 60,
              color: AppColors.whiteText,
            ),
          ),
          SizedBox(height: 32),
          ShaderMask(
            shaderCallback:
                (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'Start Conversation',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.whiteText,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Send a message to start chatting with your AI Assistant',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
