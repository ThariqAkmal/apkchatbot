import 'package:difychatbot/services/api/me_api_service.dart';
import 'package:difychatbot/utils/string_capitalize.dart';
import 'package:difychatbot/constants/app_colors.dart';
import 'package:difychatbot/services/n8n/prompt_api_service.dart';
import 'package:flutter/material.dart';
import '../services/api/logout_service.dart';
import '../models/chat_message.dart';
import '../models/me_response.dart';
import '../components/index.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // AI Provider Selection
  String _selectedProvider = 'DIFY'; // 'DIFY' atau 'N8N'
  final meAPI _meAPI = meAPI();
  final PromptApiService _promptApiService = PromptApiService();

  // User data variables
  UserData? currentUser;
  bool isLoading = true;
  bool isChangingProvider = false; // Loading state untuk provider change
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

  void _showProviderSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.secondaryBackground,
              title: Text(
                'Pilih AI Provider',
                style: TextStyle(color: AppColors.primaryText),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isChangingProvider)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.accent),
                          SizedBox(height: 8),
                          Text(
                            'Mengganti provider...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ListTile(
                      leading: Icon(
                        Icons.smart_toy,
                        color:
                            _selectedProvider == 'DIFY'
                                ? AppColors.accent
                                : AppColors.secondaryTextDark,
                      ),
                      title: Text(
                        'DIFY',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      subtitle: Text(
                        'Dify AI Platform',
                        style: TextStyle(color: AppColors.secondaryTextLight),
                      ),
                      trailing:
                          _selectedProvider == 'DIFY'
                              ? Icon(
                                Icons.check_circle,
                                color: AppColors.accent,
                              )
                              : null,
                      onTap: () => _changeProvider('DIFY', setDialogState),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.account_tree,
                        color:
                            _selectedProvider == 'N8N'
                                ? AppColors.success
                                : AppColors.secondaryTextDark,
                      ),
                      title: Text(
                        'N8N',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                      subtitle: Text(
                        'N8N Workflow Platform',
                        style: TextStyle(color: AppColors.secondaryTextLight),
                      ),
                      trailing:
                          _selectedProvider == 'N8N'
                              ? Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              )
                              : null,
                      onTap: () => _changeProvider('N8N', setDialogState),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isChangingProvider)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tutup',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeProvider(
    String newProvider,
    StateSetter setDialogState,
  ) async {
    if (_selectedProvider == newProvider) {
      Navigator.pop(context);
      return;
    }

    // Mulai loading
    setDialogState(() {
      isChangingProvider = true;
    });
    setState(() {
      isChangingProvider = true;
    });

    try {
      // Simulasi proses penggantian provider (bisa ditambah validasi koneksi dll)
      await Future.delayed(Duration(milliseconds: 1500));

      // Update provider
      setState(() {
        _selectedProvider = newProvider;
        isChangingProvider = false;
      });

      // Tutup dialog
      Navigator.pop(context);
    } catch (e) {
      // Jika terjadi error
      setState(() {
        isChangingProvider = false;
      });

      Navigator.pop(context);
    }
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.secondaryBackground,
              title: Text(
                'Hapus Chat',
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
                          CircularProgressIndicator(color: AppColors.warning),
                          SizedBox(height: 8),
                          Text(
                            'Menghapus chat...',
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
                      'Apakah Anda yakin ingin menghapus semua riwayat chat? Tindakan ini tidak dapat dibatalkan.',
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
                    onPressed: () => _clearChatWithLoading(setDialogState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.primaryText,
                    ),
                    child: Text('Hapus'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _clearChatWithLoading(StateSetter setDialogState) async {
    // Mulai loading
    setDialogState(() {
      isClearingChat = true;
    });
    setState(() {
      isClearingChat = true;
    });

    try {
      // Simulasi proses hapus chat
      await Future.delayed(Duration(milliseconds: 1000));

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
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppColors.primaryText,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? 'Loading...' : getUserDisplayName(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                Row(
                  children: [
                    if (isChangingProvider) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondaryTextLight,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Mengganti provider...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextLight,
                        ),
                      ),
                    ] else
                      Text(
                        'Provider: ${_selectedProvider.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.secondaryBackground,
        elevation: 2,
        shadowColor: AppColors.secondaryTextDark.withValues(alpha: 0.2),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.secondaryTextLight),
            color: AppColors.secondaryBackground,
            onSelected: (value) async {
              if (value == 'logout') {
                // Gunakan LogoutService untuk logout dengan konfirmasi
                await LogoutService.confirmLogout(context);
              } else if (value == 'clear') {
                _showClearChatConfirmation();
              } else if (value == 'provider' && !isChangingProvider) {
                _showProviderSelectionDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'provider',
                  enabled: !isChangingProvider,
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        color:
                            isChangingProvider
                                ? AppColors.secondaryTextDark
                                : AppColors.accent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isChangingProvider
                            ? 'Mengganti Provider...'
                            : 'Pilih Provider',
                        style: TextStyle(
                          color:
                              isChangingProvider
                                  ? AppColors.secondaryTextDark
                                  : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear',
                  enabled: !isClearingChat,
                  child: Row(
                    children: [
                      if (isClearingChat)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.warning,
                          ),
                        )
                      else
                        Icon(Icons.clear_all, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text(
                        isClearingChat ? 'Menghapus Chat...' : 'Hapus Chat',
                        style: TextStyle(
                          color:
                              isClearingChat
                                  ? AppColors.secondaryTextDark
                                  : AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
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
                                if (index == messages.length && isAiThinking) {
                                  // Tampilkan thinking bubble di akhir
                                  return ThinkingBubble();
                                }
                                return MessageBubble(message: messages[index]);
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
    );
  }
}
