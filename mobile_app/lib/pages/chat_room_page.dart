import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'package:intl/intl.dart'; // This defines DateFormat
class ChatRoomPage extends StatefulWidget {
  final String userName; // The OTHER person's name
  const ChatRoomPage({super.key, required this.userName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _messages = [];
  late ChatService _chatService;
  String? _currentUserName;
  bool _isInitialised = false; // Tracks if your identity is loaded

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Fetch your identity FIRST
    final myName = await _authService.getUsername();

    if (mounted) {
      setState(() {
        _currentUserName = myName;
        _isInitialised = true;
      });

      // 2. Load historical messages using your confirmed identity
      await _loadHistory();

      // 3. Initialize WebSocket connection
      _chatService = ChatService(
        onMessageReceived: (message) {
          if (mounted) {
            // Check for duplicates to avoid double-showing your own sent messages
            bool isDuplicate = _messages.any((m) =>
            m['content'] == message['content'] &&
                m['timestamp'] == message['timestamp'] &&
                m['sender'] == message['sender']);

            if (!isDuplicate) {
              setState(() {
                _messages.add(message);
              });
              _scrollToBottom();
            }
          }
        },
      );
    }
  }

  Future<void> _loadHistory() async {
    if (_currentUserName == null) return;

    try {
      final response = await http.get(
          Uri.parse('http://localhost:8080/api/messages?user1=$_currentUserName&user2=${widget.userName}')
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages = data.cast<Map<String, dynamic>>();
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("History Fetch Error: $e");
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      // 1. Force a direct read from storage right before sending
      final String? myActualName = await _authService.getUsername();

      if (myActualName == null) {
        print("Error: No logged-in user found.");
        return;
      }

      // 2. Send the message with the confirmed sender name
      _chatService.sendMessage(
        myActualName,
        _messageController.text.trim(),
        widget.userName, // This is the receiver
      );

      setState(() {
        _messages.add({
          'sender': myActualName, // Store your name locally for 'isMe' check
          'content': _messageController.text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      });

      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    if (this._chatService != null) _chatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e3c72),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_isInitialised
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  // 1. Get the sender from the message
                  String messageSender = msg['sender'] ?? "";

                  // 2. If the sender matches your stored name, it's YOU (Right side)
                  bool isMe = _currentUserName != null && messageSender == _currentUserName;
                  return _buildMessageBubble(msg, isMe);
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    String text = msg['content'] ?? "";
    String rawTime = msg['timestamp'] ?? "";
    String formattedTime = "";

    try {
      if (rawTime.isNotEmpty) {
        DateTime dateTime = DateTime.parse(rawTime).toLocal();
        formattedTime = DateFormat('h:mm a').format(dateTime); // e.g. "1:36 PM"
      }
    } catch (_) {}

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF00d2ff) : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            child: Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Text(
              formattedTime,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 15, right: 15, top: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF1e3c72),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}