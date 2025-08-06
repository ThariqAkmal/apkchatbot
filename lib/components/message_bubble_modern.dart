import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../constants/app_colors.dart';
import '../models/chat_message.dart';

class ModernMessageBubble extends StatefulWidget {
  final ChatMessage message;

  const ModernMessageBubble({Key? key, required this.message})
    : super(key: key);

  @override
  _ModernMessageBubbleState createState() => _ModernMessageBubbleState();
}

class _ModernMessageBubbleState extends State<ModernMessageBubble> {
  double _textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientStart.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.whiteText,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
          ],

          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      widget.message.isUser
                          ? AppColors.cardBackground
                          : AppColors.primaryBackground,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight:
                        widget.message.isUser
                            ? Radius.circular(6)
                            : Radius.circular(20),
                    bottomLeft:
                        widget.message.isUser
                            ? Radius.circular(20)
                            : Radius.circular(6),
                  ),
                  border: Border.all(
                    color:
                        widget.message.isUser
                            ? AppColors.borderLight
                            : AppColors.borderMedium,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File attachment preview (if exists)
                    if (widget.message.fileName != null) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: AppColors.subtleGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gradientStart.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.whiteText,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                widget.message.fileType == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : Icons.attach_file,
                                color: AppColors.gradientStart,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                widget.message.fileName!,
                                style: TextStyle(
                                  color: AppColors.gradientStart,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowMedium,
                              blurRadius: 8,
                              offset: Offset(0, 4),
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
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_outlined,
                                          color: AppColors.secondaryText,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Image could not be loaded',
                                          style: TextStyle(
                                            color: AppColors.secondaryText,
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
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                )
                                : MarkdownWidget(
                                  data: widget.message.text,
                                  selectable: true,
                                  shrinkWrap: true,
                                  config: MarkdownConfig(
                                    configs: [
                                      // Modern H1 Configuration
                                      H1Config(
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                        ),
                                      ),
                                      // Modern H2 Configuration
                                      H2Config(
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                        ),
                                      ),
                                      // Modern H3 Configuration
                                      H3Config(
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                      // Modern Paragraph Configuration
                                      PConfig(
                                        textStyle: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.5,
                                        ),
                                      ),
                                      // Modern Code Configuration
                                      CodeConfig(
                                        style: TextStyle(
                                          color: AppColors.gradientStart,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          backgroundColor:
                                              AppColors.cardBackground,
                                        ),
                                      ),
                                      // Modern Pre Configuration
                                      PreConfig(
                                        theme: {
                                          'root': TextStyle(
                                            backgroundColor:
                                                AppColors.cardBackground,
                                            color: AppColors.primaryText,
                                          ),
                                        },
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBackground,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderLight,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      // Modern Link Configuration
                                      LinkConfig(
                                        style: TextStyle(
                                          color: AppColors.gradientMiddle,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ],

                    // Timestamp
                    SizedBox(height: 8),
                    Text(
                      _formatTime(widget.message.timestamp),
                      style: TextStyle(
                        color: AppColors.lightText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.message.isUser) ...[
            SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.gradientMiddle,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),

                Text(
                  'Message Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 20),

                // Copy option
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.subtleGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      color: AppColors.gradientStart,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Copy Text',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    _copyToClipboard();
                    Navigator.pop(context);
                  },
                ),

                // Zoom options
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.subtleGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.zoom_in_rounded,
                      color: AppColors.gradientStart,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Zoom In',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    _zoomIn();
                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.subtleGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.zoom_out_rounded,
                      color: AppColors.gradientStart,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Zoom Out',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    _zoomOut();
                    Navigator.pop(context);
                  },
                ),

                // Full screen option
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.subtleGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fullscreen_rounded,
                      color: AppColors.gradientStart,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Full Screen',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showFullScreenText(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _zoomIn() {
    setState(() {
      if (_textScale < 3.0) {
        _textScale += 0.2;
      }
    });
  }

  void _zoomOut() {
    setState(() {
      if (_textScale > 0.5) {
        _textScale -= 0.2;
      }
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Text copied to clipboard'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFullScreenText(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: AppColors.primaryBackground,
              appBar: AppBar(
                title: Text(
                  'Message Detail',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: AppColors.primaryBackground,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.primaryText),
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child:
                    widget.message.isUser
                        ? SelectableText(
                          widget.message.text,
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        )
                        : MarkdownWidget(
                          data: widget.message.text,
                          selectable: true,
                          shrinkWrap: true,
                          config: MarkdownConfig(
                            configs: [
                              H1Config(
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              H2Config(
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              H3Config(
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              PConfig(
                                textStyle: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                ),
                              ),
                              CodeConfig(
                                style: TextStyle(
                                  color: AppColors.gradientStart,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  backgroundColor: AppColors.cardBackground,
                                ),
                              ),
                              PreConfig(
                                theme: {
                                  'root': TextStyle(
                                    backgroundColor: AppColors.cardBackground,
                                    color: AppColors.primaryText,
                                  ),
                                },
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                              ),
                              LinkConfig(
                                style: TextStyle(
                                  color: AppColors.gradientMiddle,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
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

  void _showImageFullScreen(BuildContext context, Uint8List imageData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.whiteText),
                title: Text(
                  'Generated Image',
                  style: TextStyle(color: AppColors.whiteText),
                ),
              ),
              body: Center(
                child: InteractiveViewer(child: Image.memory(imageData)),
              ),
            ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
