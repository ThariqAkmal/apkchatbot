import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppColors.primaryText,
                size: 18,
              ),
            ),
            SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    message.isUser ? AppColors.userBubble : AppColors.botBubble,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight:
                      message.isUser ? Radius.circular(4) : Radius.circular(18),
                  bottomLeft:
                      message.isUser ? Radius.circular(10) : Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBackground.withValues(alpha: 0.3),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                          message.isUser
                              ? AppColors.primaryText
                              : AppColors.primaryText,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color:
                          message.isUser
                              ? AppColors.primaryText.withValues(alpha: 0.7)
                              : AppColors.secondaryTextLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (message.isUser) ...[
            SizedBox(width: 8),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondaryBackground,
                  child: Icon(
                    Icons.person,
                    color: AppColors.secondaryTextLight,
                    size: 18,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    String hour = timestamp.hour.toString().padLeft(2, '0');
    String minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
