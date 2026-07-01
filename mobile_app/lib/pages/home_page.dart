import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'login_page.dart';
import 'chat_room_page.dart';
import 'profile_page.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import '../config/api_config.dart';
import 'add_contact_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _currentUsername;

  final TextEditingController _searchController = TextEditingController();
  late AnimationController _searchAnimController;

  @override
  void initState() {
    super.initState();
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadCurrentUser();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    _currentUsername = await _authService.getUsername();
    if (mounted) setState(() {});
  }

  Future<void> _loadUsers() async {
    final String? loggedInUser = await _authService.getUsername();
    final String url = '${ApiConfig.usersUrl}?currentUser=$loggedInUser';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allUsers = data.where((user) => user['username'] != loggedInUser).toList();
          _filteredUsers = _allUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredUsers = _allUsers
          .where((user) => user['username'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredUsers = _allUsers;
        _searchAnimController.reverse();
      } else {
        _searchAnimController.forward();
      }
    });
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Logout", style: AppTheme.labelBold),
        content: Text("Are you sure you want to sign out?", style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
            child: Text("Logout", style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // Animated search bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _isSearching ? 64 : 0,
            curve: Curves.easeInOut,
            child: _isSearching ? _buildSearchBar() : const SizedBox.shrink(),
          ),
          // Chat list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    color: AppTheme.accent,
                    backgroundColor: AppTheme.card,
                    child: _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              return _buildChatItem(context, _filteredUsers[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentUsername != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddContactPage(currentUser: _currentUsername!)),
            ).then((_) => _loadUsers());
          }
        },
        backgroundColor: AppTheme.accent,
        elevation: 4,
        child: const Icon(Icons.person_add, color: Colors.white, size: 22),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0.5,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.textSecondary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        "Messenger",
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: AppTheme.textSecondary,
          ),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: _filterSearch,
        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: "Search contacts...",
          hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
          filled: true,
          fillColor: AppTheme.inputFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    name: _currentUsername ?? 'U',
                    radius: 32,
                    showOnline: true,
                    isOnline: true,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _currentUsername ?? 'User',
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Online",
                    style: GoogleFonts.inter(
                      color: AppTheme.online,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Menu items
            _buildDrawerItem(Icons.person_outline, "Profile", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(username: _currentUsername ?? 'User'),
                ),
              );
            }),
            _buildDrawerItem(Icons.group_outlined, "Contacts", () {
              Navigator.pop(context);
              _loadUsers();
            }),
            _buildDrawerItem(Icons.notifications_outlined, "Notifications", () {
              Navigator.pop(context);
            }),
            const Divider(color: AppTheme.divider, indent: 20, endIndent: 20),
            _buildDrawerItem(Icons.settings_outlined, "Settings", () {
              Navigator.pop(context);
            }),
            const Spacer(),
            _buildDrawerItem(Icons.logout, "Logout", () {
              Navigator.pop(context);
              _handleLogout();
            }, color: AppTheme.error),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textSecondary, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: color ?? AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.card.withAlpha(120),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, size: 56, color: AppTheme.textMuted.withAlpha(100)),
          ),
          const SizedBox(height: 20),
          Text("No conversations yet", style: AppTheme.labelBold),
          const SizedBox(height: 8),
          Text(
            "Start a new conversation by\ntapping the compose button",
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, dynamic user) {
    String name = user['username'] ?? "Unknown";
    String lastMsg = user['lastMessage'] ?? "No messages yet";
    String? lastMsgSender = user['lastMessageSender'];
    String rawTime = user['lastTime'] ?? "";
    bool hasMessage = lastMsg != "No messages yet";

    // Format last message with "You: " prefix if sent by current user
    String displayMsg = lastMsg;
    if (hasMessage && lastMsgSender != null && lastMsgSender == _currentUsername) {
      displayMsg = "You: $lastMsg";
    }

    // Clean time formatting
    String formattedTime = "";
    if (rawTime.isNotEmpty) {
      try {
        DateTime dateTime = DateTime.parse(rawTime).toLocal();
        DateTime now = DateTime.now();
        if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
          formattedTime = DateFormat.jm().format(dateTime);
        } else if (dateTime.day == now.day - 1) {
          formattedTime = "Yesterday";
        } else {
          formattedTime = DateFormat('MMM d').format(dateTime);
        }
      } catch (e) {
        formattedTime = "";
      }
    }

    return Dismissible(
      key: Key(name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.error.withAlpha(40),
        child: const Icon(Icons.delete_outline, color: AppTheme.error, size: 26),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("Delete Chat", style: AppTheme.labelBold),
            content: Text("Delete conversation with $name?", style: AppTheme.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("Cancel", style: GoogleFonts.inter(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text("Delete", style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            await http.delete(Uri.parse('${ApiConfig.messagesUrl}/conversation?user1=$_currentUsername&user2=$name'));
          } catch (e) {
            debugPrint('Delete error: $e');
          }
          setState(() {
            _allUsers.removeWhere((u) => u['username'] == name);
            _filteredUsers.removeWhere((u) => u['username'] == name);
          });
        }
        return false; // We handle removal ourselves via setState
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatRoomPage(userName: name)),
            ).then((_) => _loadUsers());
          },
          splashColor: AppTheme.accent.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
            ),
            child: Row(
              children: [
                // Avatar
                UserAvatar(
                  name: name,
                  radius: 28,
                  showOnline: true,
                  isOnline: user['online'] ?? false,
                  imageUrl: user['profileImage'],
                ),
                const SizedBox(width: 14),
                // Name + Last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (formattedTime.isNotEmpty)
                            Text(
                              formattedTime,
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: hasMessage ? AppTheme.textSecondary : AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}