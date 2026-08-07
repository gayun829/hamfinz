import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Figma node `27:3` 설정 화면 Dev Mode CSS 토큰.
abstract final class FigmaSettingsTokens {
  static const designWidth = 1212.67;

  static const background = AppTheme.figmaAuthBackground; // #f5faff
  static const profileLink = AppTheme.figmaLink; // #1ba1b9
  static const completeButton = Color(0xFF9CE5FF);
  static const destructive = AppTheme.error;

  static const profileSize = 280.0;
  static const profileTop = 120.0;
  static const profileLinkGap = 24.0;
  static const sectionTopGap = 80.0;
  static const sectionTitleGap = 48.0;
  static const menuItemGap = 24.0;
  static const withdrawTopGap = 32.0;
  static const buttonHorizontal = 88.0;
  static const buttonBottom = 48.0;
  static const buttonHeight = 141.0;
  static const buttonRadius = 46.285;

  static const menuButtonHeight = 110.0;
  static const menuButtonRadius = 50.0;
  static const menuButtonBorder = AppTheme.figmaInputBorder;
  static const menuButtonBackground = Colors.white;

  static const profileLinkFontSize = 32.0;
  static const sectionFontSize = 42.0;
  static const menuFontSize = 36.0;
  static const buttonFontSize = 45.0;

  static TextStyle sectionTitleStyle(double scale) => TextStyle(
        fontSize: sectionFontSize * scale,
        fontWeight: FontWeight.w800,
        color: Colors.black,
        height: 1.2,
      );

  static TextStyle menuItemStyle(double scale) => TextStyle(
        fontSize: menuFontSize * scale,
        fontWeight: FontWeight.w500,
        color: Colors.black,
        height: 1.3,
      );

  static TextStyle profileLinkStyle(double scale) => TextStyle(
        fontSize: profileLinkFontSize * scale,
        fontWeight: FontWeight.w600,
        color: profileLink,
        height: 1.2,
      );

  static TextStyle buttonStyle(double scale) => TextStyle(
        fontSize: buttonFontSize * scale,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.1,
      );
}
