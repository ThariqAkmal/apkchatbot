import 'dart:typed_data';

class ChatMessage {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? fileName; // For file attachments
  final String? fileType; // For file type (pdf, image, etc.)
  final Uint8List? imageData; // For binary image data from AI response
  final bool
  isImageGenerated; // To identify if this is an image generation response

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.fileName,
    this.fileType,
    this.imageData,
    this.isImageGenerated = false,
  });
}
