import 'package:flutter/material.dart';

class AppTheme {
  static const primaryGreen = Color(0xFF58CC02);
  static const primaryBlue = Color(0xFF1CB0F6);
  static const accentOrange = Color(0xFFFF9600);
  static const background = Color(0xFFF7F9FC);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const error = Color(0xFFFF4B4B);
  static const success = Color(0xFF58CC02);

  // Figma design tokens (캐릭터 - 홈/퀴즈 초기화면)
  static const figmaAuthBackground = Color(0xFFF5FAFF);
  static const figmaPrimaryButton = Color(0xFF67D3FA);
  static const figmaInputBorder = Color(0xFF9EB6CE);
  static const figmaInputBorderAlt = Color(0xFF93A8BD);
  static const figmaPlaceholder = Color(0xFF93A8BD);
  static const figmaLink = Color(0xFF1BA1B9);
  static const figmaHomeBackground = Color(0xFFFBFBFB);
  static const figmaMintLight = Color(0xFFB7F1F3);
  static const figmaMintCard = Color(0xFFDDF6FF);
  static const figmaMintDeep = Color(0xFF46CABF);
  static const figmaTeal = Color(0xFF1B9CA1);
  static const figmaYellow = Color(0xFFFFCA55);
  static const figmaOrange = Color(0xFFFB8B3B);
  static const figmaNewsBanner = Color(0xFFB7F1F3);
  static const figmaLevelPill = Color(0xFFEEF9FD);
  static const figmaSpeechBubble = Color(0xFFF5FAFF);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      // Pretendard (SIL OFL) — assets/fonts/OFL.txt
      fontFamily: 'Pretendard',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: primaryBlue,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: primaryBlue, width: 2),
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}
