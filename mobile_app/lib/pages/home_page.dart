import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'chat_room_page.dart';
import '../services/auth_service.dart'; // Import to use logout

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();

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
                // Properly clear the encrypted token
                await _authService.logout();
                if (mounted) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage())
                  );
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
                // Use FutureBuilder to fetch real data from Neon
                child: FutureBuilder<List<dynamic>>(
                  future: _fetchUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No users found in database"));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final user = snapshot.data![index];
                        return _buildChatItem(context, user);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF00d2ff),
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }

  // Fetch users from your Spring Boot /api/users endpoint
  Future<List<dynamic>> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/api/users'));
      print("Response Status: ${response.statusCode}"); // If this is 403, it's SecurityConfig!
      print("Response Body: ${response.body}"); // If this is HTML, it's the @RestController issue!

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      print("Connection Error: $e"); // If this triggers, it's an ADB/IP issue!
      throw e;
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
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
  } // Added missing closing brace here

  Widget _buildChatItem(BuildContext context, dynamic user) {
    String name = user['username'] ?? "Unknown"; // Match your entity field
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatRoomPage(userName: name)),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blueGrey[100],
            child: Text(name[0].toUpperCase()),
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(radius: 7, backgroundColor: Colors.white, child: CircleAvatar(radius: 5, backgroundColor: Colors.green)),
          ),
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: const Text("Hey, how is the project going?", maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Text("12:45 PM", style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}