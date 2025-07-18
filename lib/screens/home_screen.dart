import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/dify_service.dart';
import '../services/n8n_service.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId; // Untuk menyimpan conversation ID dari Dify

  // AI Provider Selection
  String _selectedProvider = 'DIFY'; // 'DIFY' atau 'N8N'

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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    final userId =
        Provider.of<AuthProvider>(context, listen: false).user?.id.toString() ??
        'anonymous';

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
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String response = '';

      if (_selectedProvider == 'DIFY') {
        // Menggunakan Dify
        response = await _sendToDify(userMessage, userId);
      } else {
        // Menggunakan n8n
        response = await _sendToN8n(userMessage, userId);
      }

      // Tambahkan respons AI ke UI
      setState(() {
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
        messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text:
                "Maaf, terjadi kesalahan dengan $_selectedProvider. Silakan coba lagi.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
      print('Error sending message to $_selectedProvider: $e');
    }
  }

  void _showProviderSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih AI Provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.smart_toy,
                  color:
                      _selectedProvider == 'DIFY' ? Colors.blue : Colors.grey,
                ),
                title: Text('DIFY'),
                subtitle: Text('Dify AI Platform'),
                trailing:
                    _selectedProvider == 'DIFY'
                        ? Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                onTap: () {
                  setState(() {
                    _selectedProvider = 'DIFY';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.account_tree,
                  color:
                      _selectedProvider == 'N8N' ? Colors.green : Colors.grey,
                ),
                title: Text('N8N'),
                subtitle: Text('N8N Workflow Platform'),
                trailing:
                    _selectedProvider == 'N8N'
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : null,
                onTap: () {
                  setState(() {
                    _selectedProvider = 'N8N';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _sendToDify(String message, String userId) async {
    // Log ke n8n untuk tracking
    N8nService.triggerChatWorkflow(
      userId: userId,
      message: message,
      conversationId: _conversationId ?? '',
      metadata: {
        'provider': 'DIFY',
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      },
    );

    // Kirim pesan ke Dify
    final response = await DifyService.sendMessage(
      message: message,
      userId: userId,
      conversationId: _conversationId,
    );

    // Log response ke n8n
    N8nService.triggerUserActivityWorkflow(
      userId: userId,
      activity: 'dify_response_received',
      additionalData: {
        'response_length': response.length,
        'conversation_id': _conversationId,
        'response_time': DateTime.now().toIso8601String(),
      },
    );

    return response;
  }

  Future<String> _sendToN8n(String message, String userId) async {
    // Kirim langsung ke n8n workflow
    final result = await N8nService.triggerChatWorkflow(
      userId: userId,
      message: message,
      conversationId: _conversationId ?? '',
      metadata: {
        'provider': 'N8N',
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      },
    );

    // Log activity
    N8nService.triggerUserActivityWorkflow(
      userId: userId,
      activity: 'n8n_response_received',
      additionalData: {
        'workflow_result': result,
        'conversation_id': _conversationId,
        'response_time': DateTime.now().toIso8601String(),
      },
    );

    // Extract response dari n8n result
    if (result != null && result['response'] != null) {
      return result['response'].toString();
    } else {
      return 'Response dari n8n workflow berhasil diproses.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Provider: ${_selectedProvider.toUpperCase()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 2,
        shadowColor: Colors.grey.withValues(alpha: 0.2),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
            onSelected: (value) async {
              if (value == 'logout') {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              } else if (value == 'clear') {
                setState(() {
                  messages.clear();
                  messages.add(
                    ChatMessage(
                      text:
                          "Chat telah dibersihkan. Bagaimana saya bisa membantu Anda?",
                      isUser: false,
                      timestamp: DateTime.now(),
                    ),
                  );
                });
              } else if (value == 'provider') {
                _showProviderSelectionDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'provider',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Pilih Provider'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Hapus Chat'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages Area
          Expanded(
            child:
                messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(messages[index]);
                      },
                    ),
          ),

          // Message Input Area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.grey.shade100],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Mulai Percakapan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kirim pesan untuk memulai chat dengan AI Assistant',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
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
                color: message.isUser ? Colors.blue.shade600 : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight:
                      message.isUser ? Radius.circular(4) : Radius.circular(18),
                  bottomLeft:
                      message.isUser ? Radius.circular(18) : Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                          message.isUser ? Colors.white : Colors.grey.shade800,
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
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey.shade600,
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
                  backgroundColor: Colors.grey.shade100,
                  child: Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
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

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan Anda...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: Colors.grey.shade800),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: Icon(Icons.send, color: Colors.white),
              iconSize: 20,
            ),
          ),
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

class ChatMessage {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
