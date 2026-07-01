import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import '../config/api_config.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _profileData;

  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.profileUrl}/${widget.username}/profile'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profileData = data;
          _aboutController.text = data['about'] ?? '';
          _statusController.text = data['status'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.profileUrl}/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'about': _aboutController.text,
          'status': _statusController.text,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _isEditing = false);
        _fetchProfile();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.uploadUrl}/profile-image'));
        request.fields['username'] = widget.username;
        request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
        var response = await request.send();
        if (response.statusCode == 200) {
          _fetchProfile();
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profileData == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: AppTheme.surface, title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Profile", style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        )),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.primary),
              onPressed: _updateProfile,
            ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Stack(
                children: [
                  UserAvatar(
                    name: widget.username,
                    radius: 50,
                    showOnline: false,
                    imageUrl: _profileData?['profileImage'],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.username,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email_outlined, "Email", _profileData?['email'] ?? ''),
                  const Divider(color: AppTheme.divider, height: 24),
                  _isEditing
                      ? TextField(
                          controller: _statusController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: AppTheme.textMuted)),
                        )
                      : _buildInfoRow(Icons.access_time, "Status", _profileData?['status'] ?? ''),
                  const Divider(color: AppTheme.divider, height: 24),
                  _isEditing
                      ? TextField(
                          controller: _aboutController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'About', labelStyle: TextStyle(color: AppTheme.textMuted)),
                        )
                      : _buildInfoRow(Icons.info_outline, "About", _profileData?['about'] ?? ''),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService().logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text("Sign Out", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error.withAlpha(120)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
