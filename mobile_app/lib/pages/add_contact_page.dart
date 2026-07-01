import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class AddContactPage extends StatefulWidget {
  final String currentUser;

  const AddContactPage({super.key, required this.currentUser});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('${ApiConfig.searchUrl}?q=$query&currentUser=${widget.currentUser}'));
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addContact(String contactUsername) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.contactsUrl}/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ownerUsername': widget.currentUser,
          'contactUsername': contactUsername,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$contactUsername added to contacts')),
        );
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add contact')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Add Contact', style: TextStyle(color: AppTheme.text)),
        iconTheme: const IconThemeData(color: AppTheme.text),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: _searchUsers,
              placeholder: 'Search by username or email',
              style: const TextStyle(color: AppTheme.text),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Center(child: Text('No users found', style: TextStyle(color: AppTheme.textMuted)))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: UserAvatar(
                      name: user['username'],
                      imageUrl: user['profileImage'],
                    ),
                    title: Text(user['username'], style: const TextStyle(color: AppTheme.text)),
                    subtitle: Text(user['email'], style: const TextStyle(color: AppTheme.textMuted)),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add, color: AppTheme.primary),
                      onPressed: () => _addContact(user['username']),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
