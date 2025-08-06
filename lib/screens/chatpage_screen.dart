import 'dart:typed_data';
import 'dart:convert';
import 'package:difychatbot/services/api/me_api_service.dart';
import 'package:difychatbot/utils/string_capitalize.dart';
import 'package:difychatbot/constants/app_colors.dart';
import 'package:difychatbot/services/n8n/prompt_api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/me_response.dart';
import '../components/index.dart';
import '../services/web_chat_service.dart';

class ChatPageScreen extends StatefulWidget {
  @override
  _ChatPageScreenState createState() => _ChatPageScreenState();
}

class _ChatPageScreenState extends State<ChatPageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // AI Provider Selection
  String _selectedProvider = 'DIFY'; // 'DIFY' atau 'N8N'
  String _selectedModel = 'TSEL-Chatbot'; // Default model
  final meAPI _meAPI = meAPI();
  final PromptApiService _promptApiService = PromptApiService();
  final WebChatService _chatService = WebChatService();

  // Chat History
  List<Map<String, dynamic>> _conversationHistory = [];
  bool _isLoadingHistory = false;

  // Available models
  final List<String> _availableModels = [
    'TSEL-Chatbot',
    'TSEL-Lerning-Based',
    'TSEL-PDF-Agent',
    'TSEL-Image-Generator',
    'TSEL-Company-Agent',
  ];

  // File upload state
  PlatformFile? _selectedFile;

  // User data variables
  UserData? currentUser;
  bool isLoading = true;
  bool isClearingChat = false; // Loading state untuk clear chat
  bool isAiThinking = false; // Loading state untuk AI response
  String? errorMessage;

  // Sample chat messages for UI demonstration
  List<ChatMessage> messages = [
    ChatMessage(
      id: '1',
      text:
          "Halo! Saya adalah AI assistant Anda. Bagaimana saya bisa membantu Anda hari ini?",
      isUser: false,
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedProvider().then((_) {
      initUser().then((_) {
        // Update initial message after user data is loaded
        if (currentUser != null) {
          setState(() {
            messages[0] = ChatMessage(
              id: '1',
              text: getGreetingMessage(),
              isUser: false,
              timestamp: DateTime.now().subtract(Duration(minutes: 5)),
            );
          });
          // Load chat history setelah user data loaded
          _loadChatHistory();

          // Auto create new conversation jika provider N8N dan belum ada current conversation
          _autoCreateNewConversationIfNeeded();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider loading dipindah ke initState
  }

  Future<void> _loadSelectedProvider() async {
    try {
      // Get provider from SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final savedProvider = prefs.getString('selected_provider');
      print("Provider from SharedPreferences: $savedProvider"); // Debug

      if (savedProvider != null) {
        setState(() {
          _selectedProvider = savedProvider;
        });
        print(
          "Provider loaded from SharedPreferences: $_selectedProvider",
        ); // Debug
        return;
      }

      // Fallback: Get provider from route arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['provider'] != null) {
        print("Provider from args: ${args['provider']}"); // Debug
        setState(() {
          _selectedProvider = args['provider'];
        });
        print("Provider loaded from args: $_selectedProvider"); // Debug
        return;
      }

      print("No provider found, using default: $_selectedProvider"); // Debug
    } catch (e) {
      print("Error loading provider: $e"); // Debug
    }
  }

  Future<void> initUser() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _meAPI.getUserProfile();

      if (response != null && response.data.isNotEmpty) {
        // Successfully got user data
        setState(() {
          currentUser = response.data.first; // Ambil user pertama dari list
          isLoading = false;
          errorMessage = null;
        });

        // print(
        //   'User loaded successfully: ${currentUser!.namaDepan} ${currentUser!.namaBelakang}',
        // );
      } else {
        // Failed to get user data
        setState(() {
          currentUser = null;
          isLoading = false;
          errorMessage = 'Gagal mendapatkan data pengguna';
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anda belum login atau session telah berakhir'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      setState(() {
        currentUser = null;
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });

      print('Error loading user: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memuat data pengguna'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    String message = _messageController.text.trim();

    // For TSEL Learning Based, only file upload is required (no text message needed)
    if (_selectedModel == 'TSEL-Lerning-Based') {
      if (_selectedFile == null) {
        // Show message that PDF is required for Learning Based model
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silakan upload file PDF untuk materi pembelajaran'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      // For Learning Based, we only process the file, no text message required
    } else {
      // For other models, at least text message OR file is required
      if (message.isEmpty && _selectedFile == null) return;
    }

    final userMessage = message;

    // Tambahkan pesan user ke UI
    setState(() {
      if (_selectedModel == 'TSEL-PDF-Agent' && _selectedFile != null) {
        // For PDF Agent, combine text and file in one bubble
        messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: userMessage.isNotEmpty ? userMessage : '',
            isUser: true,
            timestamp: DateTime.now(),
            fileName: _selectedFile!.name,
            fileType: 'pdf',
          ),
        );
      } else {
        // For other models, handle separately
        // Only add text message if it's not empty
        if (message.isNotEmpty) {
          messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: userMessage,
              isUser: true,
              timestamp: DateTime.now(),
            ),
          );
        }

        // Add file attachment info if exists
        if (_selectedFile != null) {
          String fileMessage = '';
          if (_selectedModel == 'TSEL-Lerning-Based') {
            fileMessage = '📚 Materi pembelajaran: ${_selectedFile!.name}';
          } else {
            fileMessage = '📎 File uploaded: ${_selectedFile!.name}';
          }

          messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_file',
              text: fileMessage,
              isUser: true,
              timestamp: DateTime.now(),
            ),
          );
        }
      }

      isAiThinking = true; // Mulai loading AI
    });

    _messageController.clear();
    final tempFile = _selectedFile;
    _selectedFile = null; // Clear selected file
    _scrollToBottom();

    try {
      // Handle different response types
      Uint8List? imageData;
      bool isImageGenerated = false;
      String textResponse = '';

      // Use model-specific API calls
      // Using multipart form data (like Postman - more efficient)
      final promptResponse = await _promptApiService.postPromptWithMultipart(
        model: _selectedModel,
        prompt: userMessage,
        file: tempFile,
      );

      print("response: $promptResponse");

      if (promptResponse != null) {
        print("Response success: ${promptResponse.succes}");
        print("Response content type: ${promptResponse.response.runtimeType}");
        print("Response length: ${promptResponse.response.length}");
        print(
          "Response preview: ${promptResponse.response.length > 50 ? promptResponse.response.substring(0, 50) + '...' : promptResponse.response}",
        );
      }

      if (promptResponse != null && promptResponse.succes) {
        // Check if response is image data for TSEL-Image-Generator
        if (_selectedModel == 'TSEL-Image-Generator') {
          imageData = _tryParseImageResponse(promptResponse.response);
          if (imageData != null && imageData.isNotEmpty) {
            isImageGenerated = true;
            textResponse =
                'Gambar berhasil dibuat! Tap untuk melihat lebih detail.';
          } else {
            textResponse =
                promptResponse.response.isNotEmpty
                    ? promptResponse.response
                    : 'Gambar sedang diproses, mohon tunggu...';
          }
        } else {
          textResponse =
              promptResponse.response.isNotEmpty
                  ? promptResponse.response
                  : _getDefaultResponse(_selectedModel, tempFile);
        }
      } else {
        textResponse = '''# Koneksi Terputus 

## Tidak dapat terhubung ke AI Assistant

Maaf, saat ini **tidak dapat terhubung** ke AI assistant. 

### Silakan coba:
1. Periksa koneksi internet Anda
2. Refresh halaman 
3. Coba lagi dalam beberapa saat

---

_Jika masalah berlanjut, hubungi administrator sistem._

### Contoh Format Markdown

**Teks tebal** dan _teks miring_

- Item list 1
- Item list 2  
- Item list 3

```dart
// Contoh kode
print("Hello World!");
```

[Link ke Google](https://www.google.com)

> Ini adalah quote block untuk informasi penting

### Test Zoom dan Copy Features

Gunakan **long press** pada pesan ini untuk:
- 🔍 **Zoom In/Out** - Perbesar atau perkecil teks
- 📋 **Copy** - Salin teks ke clipboard  
- 🖼️ **Full Screen** - Lihat dalam mode layar penuh

---

*Testing markdown rendering dengan berbagai elemen*''';
      }

      // Tambahkan respons AI ke UI
      setState(() {
        isAiThinking = false; // Stop loading AI
        messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: textResponse,
            isUser: false,
            timestamp: DateTime.now(),
            imageData: imageData,
            isImageGenerated: isImageGenerated,
          ),
        );
      });

      // Save to chat history if using N8N provider
      if (_selectedProvider == 'N8N' && currentUser != null) {
        await _saveChatToHistory(userMessage, textResponse);
      }

      _scrollToBottom();
    } catch (e) {
      // Tampilkan pesan error
      setState(() {
        isAiThinking = false; // Stop loading AI
        messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: "Maaf, terjadi kesalahan. Silakan coba lagi.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
      print('Error sending message: $e');
    }
  }

  void _onFileSelected(PlatformFile file) {
    setState(() {
      if (file.name.isEmpty) {
        // Clear file if empty file passed (used for removing file)
        _selectedFile = null;
      } else {
        _selectedFile = file;
      }
    });
  }

  void _showNewChatConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.secondaryBackground,
              title: Text(
                'Percakapan Baru',
                style: TextStyle(color: AppColors.primaryText),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isClearingChat)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.accent),
                          SizedBox(height: 8),
                          Text(
                            'Membuat percakapan baru...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Apakah Anda ingin membuat percakapan baru?',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
              actions: [
                if (!isClearingChat) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _createNewChatWithLoading(setDialogState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryText,
                    ),
                    child: Text('Ya, Buat Baru'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNewChatWithLoading(StateSetter setDialogState) async {
    // Mulai loading
    setDialogState(() {
      isClearingChat = true;
    });
    setState(() {
      isClearingChat = true;
    });

    try {
      // Untuk N8N provider, reset current conversation dan siapkan untuk conversation baru
      if (_selectedProvider == 'N8N' && currentUser != null) {
        // Reset current conversation ID untuk memastikan conversation baru akan dibuat
        _chatService.setCurrentConversation(0); // Clear current conversation

        // Buat conversation baru dengan greeting message
        final newConversationId = await _chatService.startNewConversation(
          userId: currentUser!.id,
          title:
              'Percakapan Baru ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        );

        print('🆕 Created new conversation: $newConversationId');

        // Set sebagai conversation aktif
        await _chatService.setCurrentConversation(newConversationId);
      }

      // Simulasi proses buat percakapan baru
      await Future.delayed(Duration(milliseconds: 500));

      // Clear chat dan kembali ke greeting message
      setState(() {
        messages.clear();
        messages.add(
          ChatMessage(
            id: '1',
            text: getGreetingMessage(),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        isClearingChat = false;
      });

      // Reload chat history untuk menampilkan conversation baru di sidebar
      if (_selectedProvider == 'N8N' && mounted) {
        _loadChatHistory();
      }

      // Tutup dialog
      Navigator.pop(context);

      // Scroll ke bawah untuk menampilkan pesan baru
      _scrollToBottom();
    } catch (e) {
      // Jika terjadi error
      print('❌ Error creating new conversation: $e');
      setState(() {
        isClearingChat = false;
      });

      Navigator.pop(context);
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper method untuk mendapatkan nama user
  String getUserDisplayName() {
    if (currentUser != null) {
      return 'Selamat Datang ${currentUser!.namaDepan.capitalize()}';
    }
    return 'Guest User';
  }

  // Helper method untuk mendapatkan default response berdasarkan model
  String _getDefaultResponse(String model, PlatformFile? file) {
    switch (model) {
      case 'TSEL-PDF-Agent':
        if (file != null) {
          return "PDF berhasil dianalisis. Saya telah memproses dokumen ${file.name}. Ada yang ingin Anda tanyakan tentang isi dokumen ini?";
        }
        return 'Terima kasih atas pesan Anda. Saya siap membantu Anda menganalisis dokumen PDF.';

      case 'TSEL-Lerning-Based':
        if (file != null) {
          return "Materi pembelajaran berhasil diupload! File ${file.name} telah saya proses dan siap untuk membantu pembelajaran Anda. Silakan tanyakan apa saja tentang materi ini.";
        }
        return 'Silakan upload file PDF sebagai materi pembelajaran.';

      case 'TSEL-Chatbot':
        return 'Terima kasih atas pesan Anda. Saya siap membantu menjawab pertanyaan Anda.';

      case 'TSEL-Image-Generator':
        return 'Permintaan gambar Anda sedang diproses. Mohon tunggu sebentar. Gambar akan muncul setelah selesai dibuat.';

      case 'TSEL-Company-Agent':
        return 'Terima kasih atas pertanyaan Anda tentang perusahaan. Saya siap membantu memberikan informasi yang Anda butuhkan.';

      default:
        return 'Terima kasih atas pesan Anda. Saya telah memproses permintaan Anda.';
    }
  }

  // Helper method untuk mendapatkan greeting message
  String getGreetingMessage() {
    if (currentUser != null) {
      return 'Halo ${currentUser!.namaDepan}! Saya adalah AI assistant Anda. Bagaimana saya bisa membantu anda hari ini?';
    }
    return 'Halo! Saya adalah AI assistant Anda. Bagaimana saya bisa membantu anda hari ini?';
  }

  // Load chat history untuk sidebar
  Future<void> _loadChatHistory() async {
    if (currentUser == null || _selectedProvider != 'N8N' || !mounted) return;

    if (mounted) {
      setState(() {
        _isLoadingHistory = true;
      });
    }

    try {
      final history = await _chatService.getConversationHistory(
        currentUser!.id,
      );

      // Sort history berdasarkan waktu terbaru (updated_at) - terbaru di atas
      history.sort((a, b) {
        final aTime = DateTime.parse(a['updated_at'] as String);
        final bTime = DateTime.parse(b['updated_at'] as String);
        return bTime.compareTo(aTime); // Descending order (terbaru di atas)
      });

      if (mounted) {
        setState(() {
          _conversationHistory = history;
          _isLoadingHistory = false;
        });
      }
      print(
        '📚 Loaded ${history.length} conversations (sorted by newest first)',
      );
    } catch (e) {
      print('❌ Error loading chat history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  // Load conversation dari history
  Future<void> _loadConversation(Map<String, dynamic> conversation) async {
    try {
      final conversationId = conversation['id'] as int;
      final chatHistory = await _chatService.getChatHistory(conversationId);

      setState(() {
        messages.clear();
        messages.addAll(chatHistory);

        // Jika tidak ada pesan, tambahkan greeting
        if (messages.isEmpty) {
          messages.add(
            ChatMessage(
              id: '1',
              text: getGreetingMessage(),
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        }
      });

      // Set current conversation
      await _chatService.setCurrentConversation(conversationId);

      print('📖 Loaded conversation: ${conversation['conversation_title']}');
      _scrollToBottom();
    } catch (e) {
      print('❌ Error loading conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memuat conversation'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Helper method untuk format waktu "time ago"
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Dialog untuk konfirmasi hapus conversation
  void _showDeleteConversationDialog(Map<String, dynamic> conversation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title: Text(
            'Hapus Percakapan',
            style: TextStyle(color: AppColors.primaryText),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus percakapan "${conversation['conversation_title']}"?',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteConversation(conversation);
              },
              child: Text('Hapus', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  // Method untuk hapus conversation
  Future<void> _deleteConversation(Map<String, dynamic> conversation) async {
    try {
      // TODO: Implement delete conversation method in WebChatService
      // For now, just remove from local list
      setState(() {
        _conversationHistory.removeWhere(
          (conv) => conv['id'] == conversation['id'],
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Percakapan berhasil dihapus'),
          backgroundColor: AppColors.accent,
        ),
      );
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menghapus percakapan'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Save chat to history untuk N8N provider
  Future<void> _saveChatToHistory(
    String userMessage,
    String botResponse,
  ) async {
    try {
      // Pastikan ada conversation yang aktif atau buat yang baru
      int conversationId;
      if (_chatService.currentConversationId == null) {
        conversationId = await _chatService.startNewConversation(
          userId: currentUser!.id,
          title: _generateConversationTitle(userMessage),
        );
        print('📝 Started new conversation: $conversationId');
      } else {
        conversationId = _chatService.currentConversationId!;
      }

      // Simpan user message dan bot response
      await _chatService.sendMessage(
        conversationId: conversationId,
        message: userMessage,
        userId: currentUser!.id,
      );

      print('💾 Chat saved to history');

      // Reload history untuk update sidebar - hanya jika mounted
      if (mounted) {
        _loadChatHistory();
      }
    } catch (e) {
      print('❌ Error saving chat to history: $e');
    }
  }

  // Generate conversation title dari first message
  String _generateConversationTitle(String message) {
    final cleanMessage = message.trim();
    if (cleanMessage.length <= 30) {
      return cleanMessage;
    }
    return '${cleanMessage.substring(0, 30)}...';
  }

  // Auto create new conversation jika diperlukan (untuk N8N provider)
  Future<void> _autoCreateNewConversationIfNeeded() async {
    if (_selectedProvider != 'N8N' || currentUser == null) return;

    try {
      // Cek apakah user datang dari provider selection (mengindikasikan session baru)
      final prefs = await SharedPreferences.getInstance();
      final lastProvider = prefs.getString('last_used_provider');
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final lastVisitTime = prefs.getInt('last_n8n_visit_time') ?? 0;

      // Jika belum pernah visit N8N atau sudah lewat dari 5 menit, buat conversation baru
      final shouldCreateNew =
          lastProvider != 'N8N' ||
          (currentTime - lastVisitTime) > 300000; // 5 menit

      if (shouldCreateNew) {
        // Selalu buat conversation baru ketika user baru memilih N8N
        final newConversationId = await _chatService.startNewConversation(
          userId: currentUser!.id,
          title:
              'Percakapan ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        );

        await _chatService.setCurrentConversation(newConversationId);
        print('🆕 Auto-created new conversation: $newConversationId');

        // Update last visit info
        await prefs.setString('last_used_provider', 'N8N');
        await prefs.setInt('last_n8n_visit_time', currentTime);

        // Reload history untuk update sidebar
        _loadChatHistory();
      } else {
        // Load existing conversation jika masih dalam session yang sama
        await _chatService.loadCurrentConversation();
        print(
          '📖 Continuing existing conversation: ${_chatService.currentConversationId}',
        );
      }
    } catch (e) {
      print('❌ Error auto-creating conversation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Intercept back button dan arahkan ke provider selection
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/provider-selection',
          (route) => false,
        );
        return false; // Mencegah pop default
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        drawer: _buildSidebar(),
        appBar: AppBar(
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.subtleGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      color: AppColors.gradientStart,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientStart.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${_selectedProvider.toUpperCase()} Assistant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.whiteText,
                letterSpacing: 0.3,
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primaryBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body:
            isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 16),
                      Text(
                        'Memuat data pengguna...',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    // Chat Messages Area
                    Expanded(
                      child:
                          messages.isEmpty && !isAiThinking
                              ? ChatEmptyState()
                              : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(16),
                                itemCount:
                                    messages.length + (isAiThinking ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == messages.length &&
                                      isAiThinking) {
                                    // Tampilkan thinking bubble di akhir
                                    return ModernThinkingBubble();
                                  }
                                  return ModernMessageBubble(
                                    message: messages[index],
                                  );
                                },
                              ),
                    ),

                    // Message Input Area
                    MessageInputIntegrated(
                      controller: _messageController,
                      onSendMessage: _sendMessage,
                      selectedModel: _selectedModel,
                      availableModels: _availableModels,
                      onModelChanged: (String newModel) {
                        setState(() {
                          _selectedModel = newModel;
                        });
                      },
                      onFileSelected: _onFileSelected,
                      selectedFile: _selectedFile,
                    ),
                  ],
                ),
      ), // Penutup untuk WillPopScope
    );
  }

  // Sidebar Widget
  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: AppColors.primaryBackground,
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBackground, AppColors.cardBackground],
          ),
        ),
        child: ListView(
          children: [
            // Modern Header
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.whiteText,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: AppColors.gradientMiddle,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_selectedProvider.toUpperCase()} Assistant',
                              style: TextStyle(
                                color: AppColors.whiteText,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'AI-Powered Conversations',
                        style: TextStyle(
                          color: AppColors.whiteText.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Menu Items with Modern Design
            _buildSidebarItem(
              icon: Icons.home_rounded,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/provider-selection',
                  (route) => false,
                );
              },
            ),

            _buildSidebarItem(
              icon: Icons.add_circle_outline_rounded,
              title: 'New Conversation',
              onTap: () {
                Navigator.pop(context);
                _showNewChatConfirmation();
              },
            ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              height: 1,
              decoration: BoxDecoration(gradient: AppColors.subtleGradient),
            ),

            // History Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.subtleGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppColors.gradientStart,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (_selectedProvider == 'N8N') ...[
                    Spacer(),
                    if (_isLoadingHistory)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gradientMiddle,
                        ),
                      )
                    else
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: AppColors.gradientMiddle,
                          ),
                        ),
                        onPressed: _loadChatHistory,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                  ],
                ],
              ),
            ),

            // Chat History List
            if (_selectedProvider == 'N8N') ...[
              if (_conversationHistory.isEmpty && !_isLoadingHistory)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.lightText,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No conversations yet',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Start a new conversation to begin',
                        style: TextStyle(
                          color: AppColors.lightText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._conversationHistory.map((conversation) {
                  final title = conversation['conversation_title'] as String;
                  final updatedAt = DateTime.parse(
                    conversation['updated_at'] as String,
                  );
                  final timeAgo = _getTimeAgo(updatedAt);

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.subtleGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.gradientStart,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        title.length > 25
                            ? '${title.substring(0, 25)}...'
                            : title,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        timeAgo,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _loadConversation(conversation);
                      },
                      onLongPress: () {
                        _showDeleteConversationDialog(conversation);
                      },
                    ),
                  );
                }).toList(),
            ] else ...[
              // Untuk provider DIFY, tampilkan pesan modern
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.subtleGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.gradientStart,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'History Feature',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chat history is only available for N8N Provider conversations.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method for sidebar items
  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.subtleGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.gradientStart, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  // Helper method to try parsing image response from API
  Uint8List? _tryParseImageResponse(String response) {
    try {
      print('Trying to parse image response, length: ${response.length}');

      // Case 1: Pure base64 string (most common from our N8N setup)
      if (response.length > 100 &&
          !response.contains('{') &&
          !response.contains('"')) {
        try {
          print('Attempting to decode as pure base64 string');
          final bytes = base64Decode(response);
          print(
            'Successfully decoded base64, image size: ${bytes.length} bytes',
          );
          return Uint8List.fromList(bytes);
        } catch (e) {
          print('Failed to decode as pure base64: $e');
        }
      }

      // Case 2: Data URL format (data:image/jpeg;base64,...)
      if (response.contains('data:image') && response.contains('base64,')) {
        try {
          print('Attempting to decode as data URL');
          final base64String = response.split('base64,').last;
          final bytes = base64Decode(base64String);
          print(
            'Successfully decoded data URL, image size: ${bytes.length} bytes',
          );
          return Uint8List.fromList(bytes);
        } catch (e) {
          print('Failed to decode data URL: $e');
        }
      }

      // Case 3: JSON wrapped base64
      if (response.trim().startsWith('{') && response.trim().endsWith('}')) {
        try {
          print('Attempting to decode as JSON');
          final jsonData = json.decode(response);
          if (jsonData is Map<String, dynamic>) {
            // Look for common image data fields
            final imageFields = [
              'image',
              'data',
              'base64',
              'image_data',
              'result',
              'file',
            ];
            for (final field in imageFields) {
              if (jsonData.containsKey(field)) {
                final imageValue = jsonData[field];
                if (imageValue is String && imageValue.isNotEmpty) {
                  try {
                    String base64String = imageValue;
                    if (base64String.contains('base64,')) {
                      base64String = base64String.split('base64,').last;
                    }
                    final bytes = base64Decode(base64String);
                    print(
                      'Successfully decoded JSON field "$field", image size: ${bytes.length} bytes',
                    );
                    return Uint8List.fromList(bytes);
                  } catch (e) {
                    print('Error decoding image from field $field: $e');
                    continue;
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Failed to parse as JSON: $e');
        }
      }

      // Case 4: Base64 with quotes (some APIs return this)
      if (response.startsWith('"') && response.endsWith('"')) {
        try {
          print('Attempting to decode quoted base64');
          final unquoted = response.substring(1, response.length - 1);
          final bytes = base64Decode(unquoted);
          print(
            'Successfully decoded quoted base64, image size: ${bytes.length} bytes',
          );
          return Uint8List.fromList(bytes);
        } catch (e) {
          print('Failed to decode quoted base64: $e');
        }
      }

      print('Could not parse response as image data');
      return null;
    } catch (e) {
      print('Error parsing image response: $e');
      return null;
    }
  }
}
