import 'package:difychatbot/services/api/me_api_service.dart';
import 'package:difychatbot/utils/string_capitalize.dart';
import 'package:difychatbot/constants/app_colors.dart';
import 'package:difychatbot/services/n8n/prompt_api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/me_response.dart';
import '../components/index.dart';

class ChatPageScreen extends StatefulWidget {
  @override
  _ChatPageScreenState createState() => _ChatPageScreenState();
}

class _ChatPageScreenState extends State<ChatPageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // AI Provider Selection
  String _selectedProvider = 'DIFY'; // 'DIFY' atau 'N8N'
  final meAPI _meAPI = meAPI();
  final PromptApiService _promptApiService = PromptApiService();

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
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();

    // Tambahkan pesan user ke UI
    setState(() {
      messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      isAiThinking = true; // Mulai loading AI
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String response = '';

      // Gunakan PromptApiService untuk mendapatkan respons AI
      final promptResponse = await _promptApiService.postPrompt(
        message: userMessage,
      );

      print("response: $promptResponse");

      if (promptResponse != null && promptResponse.succes) {
        // Gunakan response langsung karena sekarang response adalah String
        response =
            promptResponse.response.isNotEmpty
                ? promptResponse.response
                : 'Terima kasih atas pesan Anda. Saya telah memproses permintaan Anda.';
      } else {
        // Jika PromptApiService gagal, tampilkan pesan error
        response =
            'Maaf, tidak dapat terhubung ke AI assistant. Silakan coba lagi.';
      }

      // Tambahkan respons AI ke UI
      setState(() {
        isAiThinking = false; // Stop loading AI
        messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

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

  // Helper method untuk mendapatkan greeting message
  String getGreetingMessage() {
    if (currentUser != null) {
      return 'Halo ${currentUser!.namaDepan}! Saya adalah AI assistant Anda. Bagaimana saya bisa membantu anda hari ini?';
    }
    return 'Halo! Saya adalah AI assistant Anda. Bagaimana saya bisa membantu anda hari ini?';
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
                    MessageInput(
                      controller: _messageController,
                      onSendMessage: _sendMessage,
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
            child: Text(
              'History',
              style: TextStyle(
                color: AppColors.secondaryTextLight,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Placeholder untuk history items - nanti bisa diisi dengan actual chat history
          // ListTile(
          //   leading: Icon(
          //     Icons.chat_bubble_outline,
          //     color: AppColors.secondaryTextLight,
          //   ),
          //   title: Text(
          //     'Chat hari ini',
          //     style: TextStyle(
          //       color: AppColors.secondaryTextLight,
          //       fontSize: 14,
          //     ),
          //   ),
          //   onTap: () {
          //     Navigator.pop(context);
          //     // TODO: Load specific chat history
          //   },
          // ),

          // ListTile(
          //   leading: Icon(Icons.history, color: AppColors.secondaryTextLight),
          //   title: Text(
          //     'Chat kemarin',
          //     style: TextStyle(
          //       color: AppColors.secondaryTextLight,
          //       fontSize: 14,
          //     ),
          //   ),
          //   onTap: () {
          //     Navigator.pop(context);
          //     // TODO: Load specific chat history
          //   },
          // ),
        ],
      ),
    );
  }
}
