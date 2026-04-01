import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'chat_room_page.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Load and filter users to remove YOURSELF from the list
  Future<void> _loadUsers() async {
    final String? loggedInUser = await _authService.getUsername();
    final String url = 'http://localhost:8080/api/users?currentUser=$loggedInUser';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          // Manual filter to ensure "Atul505" doesn't see "Atul505"
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
      _searchQuery = query;
      _filteredUsers = _allUsers
          .where((user) => user['username'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e3c72),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        actions: [
          IconButton(
              onPressed: () async {
                await _authService.logout();
                if (mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white70)
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: _filteredUsers.isEmpty
                      ? const Center(child: Text("No contacts found"))
                      : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildChatItem(context, _filteredUsers[index]);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers, // Use for quick refresh
        backgroundColor: const Color(0xFF00d2ff),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        onChanged: _filterSearch,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search contacts...",
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, dynamic user) {
    String name = user['username'] ?? "Unknown";
    String lastMsg = user['lastMessage'] ?? "No messages yet";
    String rawTime = user['lastTime'] ?? "";

    // CLEAN TIME FORMATTING LOGIC
    String formattedTime = "";
    if (rawTime.isNotEmpty) {
      try {
        DateTime dateTime = DateTime.parse(rawTime).toLocal();
        DateTime now = DateTime.now();
        if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
          formattedTime = DateFormat.jm().format(dateTime); // e.g., "1:05 AM"
        } else if (dateTime.day == now.day - 1) {
          formattedTime = "Yesterday";
        } else {
          formattedTime = DateFormat('MMM d').format(dateTime);
        }
      } catch (e) {
        formattedTime = "";
      }
    }

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatRoomPage(userName: name)),
        ).then((_) => _loadUsers()); // Refresh when coming back from chat
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.blueGrey[100],
        child: Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1e3c72))),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // Fix for Atul_Developer wrapping
      ),
      subtitle: Text(
        lastMsg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: lastMsg == "No messages yet" ? Colors.grey : Colors.black54),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 5),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}