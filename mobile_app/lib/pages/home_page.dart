import 'package:flutter/material.dart';
import 'login_page.dart';
import 'chat_room_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e3c72), // Matching your theme
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        actions: [
          IconButton(
              onPressed: () {
                // Clear the JWT token and go back to Login
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage())
                );
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
                child: ListView.builder(
                  itemCount: 10, // Placeholder count
                  itemBuilder: (context, index) => _buildChatItem(context,index),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
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

  Widget _buildChatItem(BuildContext context,int index) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatRoomPage(userName: "User ${index + 1}")),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blueGrey[100],
            child: Text("U${index + 1}"), // Placeholder for User Initials
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(radius: 7, backgroundColor: Colors.white, child: CircleAvatar(radius: 5, backgroundColor: Colors.green)),
          ),
        ],
      ),
      title: Text("User ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: const Text("Hey, how is the project going?", maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Text("12:45 PM", style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}