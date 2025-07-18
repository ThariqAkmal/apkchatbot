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
              gradient: AppColors.backgroundGradient,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppColors.secondaryTextLight,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Mulai Percakapan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kirim pesan untuk memulai chat dengan AI Assistant',
            style: TextStyle(fontSize: 16, color: AppColors.secondaryTextLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
