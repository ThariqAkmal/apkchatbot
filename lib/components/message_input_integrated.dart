import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';

class MessageInputIntegrated extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final String selectedModel;
  final List<String> availableModels;
  final Function(String) onModelChanged;
  final Function(PlatformFile)?
  onFileSelected; // Callback untuk file yang dipilih
  final PlatformFile? selectedFile; // File yang sedang dipilih

  const MessageInputIntegrated({
    Key? key,
    required this.controller,
    required this.onSendMessage,
    required this.selectedModel,
    required this.availableModels,
    required this.onModelChanged,
    this.onFileSelected,
    this.selectedFile,
  }) : super(key: key);

  @override
  _MessageInputIntegratedState createState() => _MessageInputIntegratedState();
}

class _MessageInputIntegratedState extends State<MessageInputIntegrated> {
  @override
  Widget build(BuildContext context) {
    // Check if current model supports file upload
    bool supportsFileUpload = _supportsFileUpload(widget.selectedModel);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 30),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBackground.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected file indicator
            if (widget.selectedFile != null)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.accent,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.selectedFile!.name,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          () => widget.onFileSelected?.call(
                            PlatformFile(name: '', size: 0, path: null),
                          ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            // Main input row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.lightText),
                    ),
                    child: Row(
                      children: [
                        // Model Dropdown as prefix
                        Container(
                          padding: EdgeInsets.only(left: 8),
                          child: PopupMenuButton<String>(
                            onSelected: (String value) {
                              widget.onModelChanged(value);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBackground.withValues(
                                  alpha: 0.7,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 4),
                                  Text(
                                    _getShortModelName(widget.selectedModel),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 14,
                                    color: AppColors.secondaryText,
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (BuildContext context) {
                              return widget.availableModels.map((String model) {
                                return PopupMenuItem<String>(
                                  value: model,
                                  child: Text(
                                    model,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            color: AppColors.primaryBackground,
                          ),
                        ),
                        // File upload button (if supported)
                        if (supportsFileUpload)
                          GestureDetector(
                            onTap: _pickFile,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.attach_file,
                                size: 18,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        // Text Input
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            decoration: InputDecoration(
                              hintText: _getHintText(
                                widget.selectedModel,
                                supportsFileUpload,
                              ),
                              hintStyle: TextStyle(
                                color: AppColors.secondaryText,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: widget.onSendMessage,
                                child: Container(
                                  margin: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.send,
                                    color: AppColors.primaryText,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            style: TextStyle(color: AppColors.primaryText),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => widget.onSendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title: Text(
            'Izin Akses File Diperlukan',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: Text(
            'TSEL AI Assistant memerlukan izin akses file untuk mengupload dokumen PDF. Silakan berikan izin dan coba lagi.',
            style: TextStyle(color: AppColors.primaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title: Text(
            'Pengaturan Izin Diperlukan',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: Text(
            'Izin akses file untuk TSEL AI Assistant telah ditolak secara permanen. Silakan buka Pengaturan > Aplikasi > TSEL AI Assistant > Izin dan aktifkan izin "File dan media".',
            style: TextStyle(color: AppColors.primaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(
                'Buka Pengaturan',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        );
      },
    );
  }

  // Check if selected model supports file upload
  bool _supportsFileUpload(String modelName) {
    return modelName == 'TSEL-PDF-Agent' || modelName == 'TSEL-Learning-Based';
  }

  // Get appropriate hint text based on model
  String _getHintText(String modelName, bool supportsFileUpload) {
    if (modelName == 'TSEL-Learning-Based') {
      return 'Upload PDF untuk materi pembelajaran...';
    } else if (modelName == 'TSEL-PDF-Agent') {
      return 'Ketik pesan atau upload PDF untuk dianalisis...';
    } else if (supportsFileUpload) {
      return 'Ketik pesan atau upload PDF...';
    } else {
      return 'Ketik pesan Anda...';
    }
  }

  // Handle file picking with permission
  Future<void> _pickFile() async {
    try {
      // Request storage permission with better approach for different Android versions
      PermissionStatus status = await Permission.storage.request();

      // If storage permission denied, try manage external storage for Android 11+
      if (status.isDenied) {
        status = await Permission.manageExternalStorage.request();
      }

      // If still denied, try photos permission for Android 13+
      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      if (status.isDenied) {
        print('Storage permission denied');
        _showPermissionDialog();
        return;
      }

      if (status.isPermanentlyDenied) {
        print('Storage permission permanently denied');
        _showPermissionPermanentlyDeniedDialog();
        return;
      }

      // Now try to pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // This helps with file access
        withReadStream: false, // Ensure we get bytes directly
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        print(
          'File selected: ${file.name}, Size: ${file.size}, Path: ${file.path}',
        );
        print('File bytes available: ${file.bytes != null}');
        print('File bytes length: ${file.bytes?.length ?? 0}');

        // Verify file bytes are available
        if (file.bytes == null) {
          print('WARNING: File bytes are null! This will cause issues.');
          // Try to read file manually if bytes are null
          try {
            if (file.path != null) {
              // For mobile platforms, we might need different approach
              print('Attempting to handle file without bytes...');
            }
          } catch (e) {
            print('Error handling file without bytes: $e');
          }
        }

        widget.onFileSelected?.call(file);
      } else {
        print('No file selected');
      }
    } catch (e) {
      // Handle file picking error
      print('Error picking file: $e');
      // You might want to show a user-friendly error message here
    }
  }

  String _getShortModelName(String modelName) {
    // Shortening model names for display
    switch (modelName) {
      case 'TSEL-Chatbot':
        return 'Chatbot';
      case 'TSEL-Learning-Based':
        return 'Learning Based';
      case 'TSEL-PDF-Agent':
        return 'PDF Agent';
      case 'TSEL-Image-Generator':
        return 'Image Generator';
      case 'TSEL-Company-Agent':
        return 'Company Agent';
      default:
        return 'AI';
    }
  }
}
