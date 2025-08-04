import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  double _textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.message.isUser) ...[
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
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      widget.message.isUser
                          ? AppColors.userBubble
                          : AppColors.botBubble,
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight:
                        widget.message.isUser
                            ? Radius.circular(4)
                            : Radius.circular(18),
                    bottomLeft:
                        widget.message.isUser
                            ? Radius.circular(10)
                            : Radius.circular(4),
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
                    if (widget.message.fileName != null) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color:
                              widget.message.isUser
                                  ? AppColors.primaryBackground.withValues(
                                    alpha: 0.2,
                                  )
                                  : AppColors.secondaryBackground.withValues(
                                    alpha: 0.3,
                                  ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                widget.message.isUser
                                    ? AppColors.primaryText.withValues(
                                      alpha: 0.3,
                                    )
                                    : AppColors.secondaryTextLight.withValues(
                                      alpha: 0.3,
                                    ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.message.fileType == 'pdf'
                                  ? Icons.picture_as_pdf
                                  : Icons.attach_file,
                              color:
                                  widget.message.isUser
                                      ? AppColors.primaryText.withValues(
                                        alpha: 0.8,
                                      )
                                      : AppColors.secondaryTextLight,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.message.fileName!,
                                style: TextStyle(
                                  color:
                                      widget.message.isUser
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
                    if (widget.message.imageData != null &&
                        widget.message.isImageGenerated) ...[
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
                                  widget.message.imageData!,
                                ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.6,
                                maxHeight: 300,
                              ),
                              child: Image.memory(
                                widget.message.imageData!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryBackground,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

                    // Text content with zoom functionality
                    if (widget.message.text.isNotEmpty) ...[
                      Transform.scale(
                        scale: _textScale,
                        alignment: Alignment.centerLeft,
                        child:
                            widget.message.isUser
                                ? SelectableText(
                                  widget.message.text,
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                )
                                : MarkdownWidget(
                                  data: widget.message.text,
                                  selectable: true,
                                  shrinkWrap: true,
                                  config: MarkdownConfig(
                                    configs: [
                                      // H1 Configuration
                                      H1Config(
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                      // H2 Configuration
                                      H2Config(
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                      ),
                                      // H3 Configuration
                                      H3Config(
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                      // Paragraph Configuration
                                      PConfig(
                                        textStyle: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                      ),
                                      // Code Configuration
                                      CodeConfig(
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          backgroundColor:
                                              AppColors.secondaryBackground,
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                        ),
                                      ),
                                      // Pre/Code block Configuration
                                      PreConfig(
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryBackground,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.secondaryTextDark
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        padding: EdgeInsets.all(12),
                                        textStyle: TextStyle(
                                          color: AppColors.primaryText,
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                        ),
                                      ),
                                      // Link Configuration
                                      LinkConfig(
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ],
                    SizedBox(height: 4),
                    // Row for timestamp and action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(widget.message.timestamp),
                          style: TextStyle(
                            color:
                                widget.message.isUser
                                    ? AppColors.primaryText.withValues(
                                      alpha: 0.7,
                                    )
                                    : AppColors.secondaryTextLight,
                            fontSize: 12,
                          ),
                        ),
                        // Action buttons for AI messages
                        if (!widget.message.isUser &&
                            widget.message.text.isNotEmpty) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Zoom out button
                              GestureDetector(
                                onTap: _zoomOut,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  margin: EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryTextLight
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.zoom_out,
                                    size: 16,
                                    color: AppColors.secondaryTextLight
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              // Zoom in button
                              GestureDetector(
                                onTap: _zoomIn,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  margin: EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryTextLight
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.zoom_in,
                                    size: 16,
                                    color: AppColors.secondaryTextLight
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              // Copy button
                              GestureDetector(
                                onTap:
                                    () => _copyToClipboard(
                                      context,
                                      widget.message.text,
                                    ),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryTextLight
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: AppColors.secondaryTextLight
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.message.isUser) ...[
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

  // Zoom in function
  void _zoomIn() {
    setState(() {
      _textScale = (_textScale * 1.2).clamp(0.5, 3.0);
    });
  }

  // Zoom out function
  void _zoomOut() {
    setState(() {
      _textScale = (_textScale / 1.2).clamp(0.5, 3.0);
    });
  }

  // Show message options (Long press menu)
  void _showMessageOptions(BuildContext context) {
    if (widget.message.text.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondaryTextLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Opsi Pesan',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Copy option
              ListTile(
                leading: Icon(Icons.copy, color: AppColors.accent),
                title: Text(
                  'Salin Teks',
                  style: TextStyle(color: AppColors.primaryText),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(context, widget.message.text);
                },
              ),

              // Full screen text option
              ListTile(
                leading: Icon(Icons.fullscreen, color: AppColors.accent),
                title: Text(
                  'Tampilan Penuh',
                  style: TextStyle(color: AppColors.primaryText),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showFullScreenText(context);
                },
              ),

              // Reset zoom option
              if (_textScale != 1.0) ...[
                ListTile(
                  leading: Icon(Icons.refresh, color: AppColors.accent),
                  title: Text(
                    'Reset Zoom',
                    style: TextStyle(color: AppColors.primaryText),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _textScale = 1.0;
                    });
                  },
                ),
              ],

              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Show full screen text with zoom functionality
  void _showFullScreenText(BuildContext context) {
    double fullScreenTextScale = 1.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    // Header with controls
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Zoom out button
                              IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    fullScreenTextScale = (fullScreenTextScale /
                                            1.2)
                                        .clamp(0.5, 3.0);
                                  });
                                },
                                icon: Icon(
                                  Icons.zoom_out,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              // Zoom in button
                              IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    fullScreenTextScale = (fullScreenTextScale *
                                            1.2)
                                        .clamp(0.5, 3.0);
                                  });
                                },
                                icon: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              // Copy button
                              IconButton(
                                onPressed: () {
                                  _copyToClipboard(
                                    context,
                                    widget.message.text,
                                  );
                                },
                                icon: Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          // Close button
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Text content
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Transform.scale(
                            scale: fullScreenTextScale,
                            alignment: Alignment.topLeft,
                            child:
                                widget.message.isUser
                                    ? SelectableText(
                                      widget.message.text,
                                      style: TextStyle(
                                        color: AppColors.primaryText,
                                        fontSize: 18,
                                        height: 1.6,
                                      ),
                                    )
                                    : MarkdownWidget(
                                      data: widget.message.text,
                                      selectable: true,
                                      shrinkWrap: true,
                                      config: MarkdownConfig(
                                        configs: [
                                          // H1 Configuration
                                          H1Config(
                                            style: TextStyle(
                                              color: AppColors.primaryText,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                            ),
                                          ),
                                          // H2 Configuration
                                          H2Config(
                                            style: TextStyle(
                                              color: AppColors.primaryText,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              height: 1.3,
                                            ),
                                          ),
                                          // H3 Configuration
                                          H3Config(
                                            style: TextStyle(
                                              color: AppColors.primaryText,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                          ),
                                          // Paragraph Configuration
                                          PConfig(
                                            textStyle: TextStyle(
                                              color: AppColors.primaryText,
                                              fontSize: 18,
                                              height: 1.6,
                                            ),
                                          ),
                                          // Code Configuration
                                          CodeConfig(
                                            style: TextStyle(
                                              color: AppColors.primaryText,
                                              backgroundColor:
                                                  AppColors.secondaryBackground,
                                              fontFamily: 'monospace',
                                              fontSize: 16,
                                            ),
                                          ),
                                          // Pre/Code block Configuration
                                          PreConfig(
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.primaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors
                                                    .secondaryTextDark
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            padding: EdgeInsets.all(16),
                                            textStyle: TextStyle(
                                              color: AppColors.primaryText,
                                              fontFamily: 'monospace',
                                              fontSize: 16,
                                            ),
                                          ),
                                          // Link Configuration
                                          LinkConfig(
                                            style: TextStyle(
                                              color: AppColors.accent,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
