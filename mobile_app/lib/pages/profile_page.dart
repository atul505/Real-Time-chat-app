import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          // Avatar
          Center(
            child: UserAvatar(
              name: username,
              radius: 50,
              showOnline: true,
              isOnline: true,
            ),
          ),
          const SizedBox(height: 20),
          // Username
          Text(
            username,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Online",
            style: GoogleFonts.inter(
              color: AppTheme.online,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Info cards
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.person_outline, "Username", username),
                const Divider(color: AppTheme.divider, height: 24),
                _buildInfoRow(Icons.access_time, "Status", "Hey! I'm using Messenger"),
                const Divider(color: AppTheme.divider, height: 24),
                _buildInfoRow(Icons.info_outline, "About", "Available"),
              ],
            ),
          ),

          const Spacer(),

          // Logout button
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 20),
        const SizedBox(width: 14),
        Column(
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
      ],
    );
  }
}
