import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/date_separator.dart';
import '../config/api_config.dart';
import '../utils/time_utils.dart';
import 'wallpaper_page.dart';

class ChatRoomPage extends StatefulWidget {
  final String userName; // The OTHER person's name
  const ChatRoomPage({super.key, required this.userName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _messages = [];
  late ChatService _chatService;
  String? _currentUserName;
  bool _isInitialised = false;
  bool _showEmojiPicker = false;
  bool _showScrollToBottom = false;
  bool _hasText = false;
  
  // Other user's status
  bool _isOnline = false;
  String? _lastSeen;
  String? _wallpaperPath;

  late AnimationController _sendBtnAnim;

  @override
  void initState() {
    super.initState();
    _sendBtnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    _loadWallpaper();
    _fetchUserStatus();
    _initChat();
  }

  Future<void> _loadWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallpaperPath = prefs.getString('chat_wallpaper');
    });
  }

  Future<void> _fetchUserStatus() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.profileUrl}/${widget.userName}/status'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isOnline = data['online'] ?? false;
            _lastSeen = data['lastSeen'];
          });
        }
      }
    } catch (e) {
      debugPrint("Status Fetch Error: $e");
    }
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendBtnAnim.forward();
      } else {
        _sendBtnAnim.reverse();
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100;
    if (_showScrollToBottom == atBottom) {
      setState(() => _showScrollToBottom = !atBottom);
    }
  }

  Future<void> _initChat() async {
    final myName = await _authService.getUsername();

    if (mounted) {
      setState(() {
        _currentUserName = myName;
        _isInitialised = true;
      });

      await _loadHistory();

      _chatService = ChatService(
        onMessageReceived: (message) {
          if (mounted) {
            // Also update online status if we receive a message from them
            if (message['sender'] == widget.userName) {
              setState(() => _isOnline = true);
            }
            
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
        Uri.parse(
            '${ApiConfig.messagesUrl}?user1=$_currentUserName&user2=${widget.userName}'),
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
    if (_messageController.text.trim().isEmpty) return;

    final String? myActualName = await _authService.getUsername();
    if (myActualName == null) return;

    final content = _messageController.text.trim();

    _chatService.sendMessage(myActualName, content, widget.userName);

    setState(() {
      _messages.add({
        'sender': myActualName,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _uploadAttachment(File file) async {
    final String? myActualName = await _authService.getUsername();
    if (myActualName == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading attachment...')));

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.uploadUrl}/attachment'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        
        _chatService.sendMessage(
          myActualName,
          _messageController.text.trim(),
          widget.userName,
          attachmentUrl: data['url'],
          attachmentType: data['type'],
          attachmentName: data['name'],
        );

        setState(() {
          _messages.add({
            'sender': myActualName,
            'content': _messageController.text.trim(),
            'attachmentUrl': data['url'],
            'attachmentType': data['type'],
            'attachmentName': data['name'],
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
        
        _messageController.clear();
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload error')));
      }
    }
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _uploadAttachment(File(pickedFile.path));
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      _uploadAttachment(File(result.files.single.path!));
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.primary),
              title: const Text('Image', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: AppTheme.primary),
              title: const Text('Document', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearChat() async {
    final myName = await _authService.getUsername();
    if (myName != null) {
      try {
        await http.delete(Uri.parse('${ApiConfig.messagesUrl}/conversation?user1=$myName&user2=${widget.userName}'));
        setState(() {
          _messages.clear();
        });
      } catch (e) {
        debugPrint('Clear chat error: $e');
      }
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

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final current = _parseDate(_messages[index]['timestamp'] ?? "");
    final previous = _parseDate(_messages[index - 1]['timestamp'] ?? "");
    if (current == null || previous == null) return false;
    return current.day != previous.day ||
        current.month != previous.month ||
        current.year != previous.year;
  }

  DateTime? _parseDate(String raw) {
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatDateSeparator(String raw) {
    final date = _parseDate(raw);
    if (date == null) return "";
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return "Today";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year) {
      return "Yesterday";
    }
    return DateFormat('MMMM d, yyyy').format(date);
  }

  String _formatMessageTime(String raw) {
    try {
      if (raw.isNotEmpty) {
        DateTime dateTime = DateTime.parse(raw).toLocal();
        return DateFormat('h:mm a').format(dateTime);
      }
    } catch (_) {}
    return "";
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendBtnAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: !_isInitialised
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : Column(
              children: [
                // Chat messages
                Expanded(
                  child: Stack(
                    children: [
                      // Chat background
                      if (_wallpaperPath != null)
                        Positioned.fill(
                          child: Image.file(
                            File(_wallpaperPath!),
                            fit: BoxFit.cover,
                            color: Colors.black.withAlpha(150),
                            colorBlendMode: BlendMode.darken,
                          ),
                        )
                      else
                        Container(color: AppTheme.background),
                      
                      // Messages list
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          String messageSender = msg['sender'] ?? "";
                          bool isMe = _currentUserName != null &&
                              messageSender == _currentUserName;

                          final showDate = _shouldShowDateSeparator(index);

                          return Column(
                            children: [
                              if (showDate)
                                DateSeparator(
                                  dateText: _formatDateSeparator(
                                      msg['timestamp'] ?? ""),
                                ),
                              ChatBubble(
                                text: msg['content'] ?? "",
                                time: _formatMessageTime(msg['timestamp'] ?? ""),
                                isMe: isMe,
                                showTail: index == _messages.length - 1 ||
                                    (_messages[index + 1]['sender'] ?? "") !=
                                        messageSender,
                                attachmentUrl: msg['attachmentUrl'],
                                attachmentType: msg['attachmentType'],
                                attachmentName: msg['attachmentName'],
                              ),
                            ],
                          );
                        },
                      ),

                      // Scroll-to-bottom FAB
                      if (_showScrollToBottom)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: FloatingActionButton.small(
                            onPressed: _scrollToBottom,
                            backgroundColor: AppTheme.card,
                            elevation: 4,
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Message input
                _buildMessageInput(),

                // Emoji picker
                if (_showEmojiPicker)
                  SizedBox(
                    height: 260,
                    child: EmojiPicker(
                      textEditingController: _messageController,
                      onEmojiSelected: (category, emoji) {
                        _onTextChanged();
                      },
                      config: Config(
                        height: 260,
                        checkPlatformCompatibility: true,
                        viewOrderConfig: const ViewOrderConfig(),
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 28,
                          backgroundColor: AppTheme.surface,
                          noRecents: Text(
                            'No Recents',
                            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 16),
                          ),
                        ),
                        categoryViewConfig: const CategoryViewConfig(
                          backgroundColor: AppTheme.surface,
                          indicatorColor: AppTheme.accent,
                          iconColorSelected: AppTheme.accent,
                          iconColor: AppTheme.textMuted,
                          dividerColor: AppTheme.divider,
                        ),
                        bottomActionBarConfig: const BottomActionBarConfig(
                          backgroundColor: AppTheme.surface,
                          buttonColor: AppTheme.accent,
                          buttonIconColor: Colors.white,
                        ),
                        searchViewConfig: SearchViewConfig(
                          backgroundColor: AppTheme.surface,
                          buttonIconColor: AppTheme.textMuted,
                          hintText: 'Search emoji...',
                          hintTextStyle: GoogleFonts.inter(color: AppTheme.textMuted),
                          inputTextStyle: GoogleFonts.inter(color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0.5,
      leadingWidth: 36,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
        onPressed: () => Navigator.pop(context),
        padding: const EdgeInsets.only(left: 8),
      ),
      title: Row(
        children: [
          UserAvatar(
            name: widget.userName,
            radius: 18,
            showOnline: true,
            isOnline: _isOnline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isOnline ? "online" : TimeUtils.formatLastSeen(_lastSeen),
                  style: GoogleFonts.inter(
                    color: _isOnline ? AppTheme.online : AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: AppTheme.textSecondary, size: 22),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: AppTheme.textSecondary, size: 22),
          onPressed: () {},
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          color: AppTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) async {
            if (value == 'wallpaper') {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const WallpaperPage()));
              _loadWallpaper();
            } else if (value == 'clear') {
              _clearChat();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'search',
              child: Text('Search', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
            ),
            PopupMenuItem(
              value: 'mute',
              child: Text('Mute', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
            ),
            PopupMenuItem(
              value: 'wallpaper',
              child: Text('Wallpaper', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Text('Clear Chat', style: GoogleFonts.inter(color: AppTheme.error)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(
        bottom: _showEmojiPicker ? 0 : MediaQuery.of(context).padding.bottom + 6,
        left: 8,
        right: 8,
        top: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(
              _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
              color: AppTheme.textMuted,
              size: 24,
            ),
            onPressed: _toggleEmojiPicker,
            padding: const EdgeInsets.only(bottom: 2),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
                onTap: () {
                  if (_showEmojiPicker) {
                    setState(() => _showEmojiPicker = false);
                  }
                },
                decoration: InputDecoration(
                  hintText: "Message",
                  hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 15),
                  filled: true,
                  fillColor: AppTheme.inputFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.attach_file, color: AppTheme.textMuted, size: 22),
                    onPressed: _showAttachmentOptions,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: _hasText
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.accentGradient,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('mic'),
                    onTap: () {},
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent.withAlpha(40),
                      ),
                      child: const Icon(Icons.mic, color: AppTheme.accent, size: 22),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}