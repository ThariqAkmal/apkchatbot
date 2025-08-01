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
        textResponse =
            'Maaf, tidak dapat terhubung ke AI assistant. Silakan coba lagi.';
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
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Apakah Anda ingin membuat percakapan baru?',
                      style: TextStyle(
                        color: AppColors.secondaryTextLight,
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
                      style: TextStyle(color: AppColors.secondaryTextLight),
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
      // Reset current conversation untuk N8N provider
      if (_selectedProvider == 'N8N') {
        await _chatService.setCurrentConversation(
          0,
        ); // Reset to no conversation
      }

      // Simulasi proses buat percakapan baru
      await Future.delayed(Duration(milliseconds: 1000));

      // Clear chat dan kembali ke greeting message (sama seperti clear chat tapi dengan pesan yang berbeda)
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

      // Tutup dialog
      Navigator.pop(context);

      // Scroll ke bawah untuk menampilkan pesan baru
      _scrollToBottom();
    } catch (e) {
      // Jika terjadi error
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
    if (currentUser == null || _selectedProvider != 'N8N') return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final history = await _chatService.getConversationHistory(
        currentUser!.id,
      );
      setState(() {
        _conversationHistory = history;
        _isLoadingHistory = false;
      });
      print('📚 Loaded ${history.length} conversations');
    } catch (e) {
      print('❌ Error loading chat history: $e');
      setState(() {
        _isLoadingHistory = false;
      });
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
            style: TextStyle(color: AppColors.secondaryTextLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.secondaryTextLight),
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

      // Reload history untuk update sidebar
      _loadChatHistory();
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
                  icon: Icon(Icons.menu, color: AppColors.primaryText),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
          title: Center(
            child: Text(
              '${_selectedProvider.toUpperCase()} Provider',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ),
          backgroundColor: AppColors.secondaryBackground,
          elevation: 2,
          shadowColor: AppColors.secondaryTextDark.withValues(alpha: 0.2),
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
                          color: AppColors.secondaryTextLight,
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
                                    return ThinkingBubble();
                                  }
                                  return MessageBubble(
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
      backgroundColor: AppColors.secondaryBackground,
      child: ListView(
        children: [
          // Header dengan nama provider dan tombol close
          Container(
            height: 120,
            color: AppColors.secondaryBackground,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedProvider.toUpperCase()} Provider',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu Items
          ListTile(
            leading: Icon(Icons.home, color: AppColors.accent),
            title: Text('Home', style: TextStyle(color: AppColors.primaryText)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/provider-selection',
                (route) => false,
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.add_comment, color: AppColors.accent),
            title: Text(
              'Percakapan Baru',
              style: TextStyle(color: AppColors.primaryText),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showNewChatConfirmation();
            },
          ),

          Divider(color: AppColors.secondaryTextDark.withValues(alpha: 0.3)),

          // History Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'History',
                  style: TextStyle(
                    color: AppColors.secondaryTextLight,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedProvider == 'N8N') ...[
                  Spacer(),
                  if (_isLoadingHistory)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.refresh, size: 16),
                      color: AppColors.accent,
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Belum ada riwayat chat',
                  style: TextStyle(
                    color: AppColors.secondaryTextLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ..._conversationHistory.map((conversation) {
                final title = conversation['conversation_title'] as String;
                final updatedAt = DateTime.parse(
                  conversation['updated_at'] as String,
                );
                final timeAgo = _getTimeAgo(updatedAt);

                return ListTile(
                  leading: Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.secondaryTextLight,
                    size: 20,
                  ),
                  title: Text(
                    title.length > 25 ? '${title.substring(0, 25)}...' : title,
                    style: TextStyle(
                      color: AppColors.secondaryTextLight,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    timeAgo,
                    style: TextStyle(
                      color: AppColors.secondaryTextLight.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 11,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _loadConversation(conversation);
                  },
                  onLongPress: () {
                    _showDeleteConversationDialog(conversation);
                  },
                );
              }).toList(),
          ] else ...[
            // Untuk provider DIFY, tampilkan pesan bahwa history tidak tersedia
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'History hanya tersedia untuk N8N Provider',
                style: TextStyle(
                  color: AppColors.secondaryTextLight,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
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
