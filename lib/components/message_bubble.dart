import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  // File attachment preview (if exists)
                  if (message.fileName != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color:
                            message.isUser
                                ? AppColors.primaryBackground.withValues(
                                  alpha: 0.2,
                                )
                                : AppColors.secondaryBackground.withValues(
                                  alpha: 0.3,
                                ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              message.isUser
                                  ? AppColors.primaryText.withValues(alpha: 0.3)
                                  : AppColors.secondaryTextLight.withValues(
                                    alpha: 0.3,
                                  ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            message.fileType == 'pdf'
                                ? Icons.picture_as_pdf
                                : Icons.attach_file,
                            color:
                                message.isUser
                                    ? AppColors.primaryText.withValues(
                                      alpha: 0.8,
                                    )
                                    : AppColors.secondaryTextLight,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message.fileName!,
                              style: TextStyle(
                                color:
                                    message.isUser
                                        ? AppColors.primaryText.withValues(
                                          alpha: 0.8,
                                        )
                                        : AppColors.secondaryTextLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Generated image display (if exists)
                  if (message.imageData != null &&
                      message.isImageGenerated) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBackground.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap:
                              () => _showImageFullScreen(
                                context,
                                message.imageData!,
                              ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                              maxHeight: 300,
                            ),
                            child: Image.memory(
                              message.imageData!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        color: AppColors.secondaryTextLight,
                                        size: 48,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Gambar tidak dapat dimuat',
                                        style: TextStyle(
                                          color: AppColors.secondaryTextLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Text content
                  if (message.text.isNotEmpty) ...[
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
                  ],
                  SizedBox(height: 4),
                  // Row for timestamp and copy button (for AI messages)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      // Copy button only for AI messages
                      if (!message.isUser && message.text.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => _copyToClipboard(context, message.text),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryTextLight.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.copy,
                              size: 16,
                              color: AppColors.secondaryTextLight.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

  // Method to copy text to clipboard
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    // Show snackbar to confirm copy
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesan telah disalin ke clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primaryBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Method to show image in full screen
  void _showImageFullScreen(BuildContext context, Uint8List imageData) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),

              // Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        imageData,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: AppColors.secondaryTextLight,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Gambar tidak dapat dimuat',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextLight,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _saveImageToGallery(context, imageData),
                    icon: Icon(Icons.download, color: AppColors.primaryText),
                    label: Text(
                      'Simpan Gambar',
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Method to save image to gallery (placeholder)
  void _saveImageToGallery(BuildContext context, Uint8List imageData) {
    // TODO: Implement save to gallery functionality
    // You can use packages like 'image_gallery_saver' or 'gallery_saver'
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur simpan gambar akan segera tersedia'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primaryBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
