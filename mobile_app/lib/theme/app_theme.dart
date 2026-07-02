import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTheme {
  // ── Core Colors ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0E1621);
  static const Color surface = Color(0xFF17212B);
  static const Color card = Color(0xFF1B2838);
  static const Color inputFill = Color(0xFF242F3D);
  static const Color accent = Color(0xFF5EB5F7);
  static const Color accentDark = Color(0xFF3A8FD4);
  static const Color sent = Color(0xFF2B5278);
  static const Color sentBubble = Color(0xFF2B5278);
  static const Color receivedBubble = Color(0xFF182533);
  static const Color online = Color(0xFF4CAF50);
  static const Color divider = Color(0xFF1E2C3A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B9DAF);
  static const Color textMuted = Color(0xFF5D7085);
  static const Color error = Color(0xFFE53935);
  static const Color unreadBadge = Color(0xFF5EB5F7);

  // ── Gradient Presets ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2838), Color(0xFF0E1621)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5EB5F7), Color(0xFF3A8FD4)],
  );

  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0E1621)],
  );

  // ── Avatar Gradients (for user initials) ─────────────────────────────────
  static const List<List<Color>> avatarGradients = [
    [Color(0xFF5EB5F7), Color(0xFF3A8FD4)],
    [Color(0xFF7C4DFF), Color(0xFF536DFE)],
    [Color(0xFFFF6D00), Color(0xFFFF9100)],
    [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
    [Color(0xFFE91E63), Color(0xFFFF5252)],
    [Color(0xFF8BC34A), Color(0xFF4CAF50)],
    [Color(0xFFFF7043), Color(0xFFFFAB40)],
    [Color(0xFF9C27B0), Color(0xFFCE93D8)],
  ];

  static List<Color> getAvatarGradient(String name) {
    final index = name.hashCode.abs() % avatarGradients.length;
    return avatarGradients[index];
  }

  // ── Text Styles ──────────────────────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );

  static TextStyle get labelBold => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // ── Input Decoration ─────────────────────────────────────────────────────
  static InputDecoration inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 15),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: textMuted, size: 22)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(color: error, fontSize: 12),
    );
  }

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentDark,
        surface: surface,
        error: error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      dividerColor: divider,
      splashColor: accent.withAlpha(30),
      highlightColor: accent.withAlpha(15),
    );
  }
}
