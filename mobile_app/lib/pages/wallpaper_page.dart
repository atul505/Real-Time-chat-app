import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';

class WallpaperPage extends StatefulWidget {
  const WallpaperPage({super.key});

  @override
  State<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends State<WallpaperPage> {
  String? _wallpaperPath;

  @override
  void initState() {
    super.initState();
    _loadWallpaper();
  }

  Future<void> _loadWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wallpaperPath = prefs.getString('chat_wallpaper');
    });
  }

  Future<void> _pickWallpaper() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_wallpaper', pickedFile.path);
      setState(() {
        _wallpaperPath = pickedFile.path;
      });
    }
  }

  Future<void> _clearWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_wallpaper');
    setState(() {
      _wallpaperPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Chat Wallpaper'),
        backgroundColor: AppTheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: _wallpaperPath != null
                ? Image.file(File(_wallpaperPath!), fit: BoxFit.cover)
                : const Center(child: Text('No wallpaper selected', style: TextStyle(color: AppTheme.textMuted))),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickWallpaper,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                  child: const Text('Change', style: TextStyle(color: Colors.white)),
                ),
                if (_wallpaperPath != null)
                  ElevatedButton(
                    onPressed: _clearWallpaper,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                    child: const Text('Remove', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
