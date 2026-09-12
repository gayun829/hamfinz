import 'package:flutter/material.dart';

/// Figma node `273:181` 마이페이지 수정 (393×852).
abstract final class FigmaSettingsTokens {
  static const designWidth = 393.0;

  static const background = Color(0xFFFBFBFB);

  // 상단 그라데이션 헤더 (273:182) — linear-gradient(53.68deg, #3cc6ff 35.9%, #b7f0f2 98.7%)
  static const headerHeight = 296.0;
  static const headerGradientStart = Color(0xFF3CC6FF);
  static const headerGradientEnd = Color(0xFFB7F0F2);
  static const headerGradientFrom = Alignment(-1.009, 0.984);
  static const headerGradientTo = Alignment(1.009, -0.984);
  static const headerGradientStops = [0.359, 0.987];

  // 한줄소개 박스 (273:268) — rgba(251,251,251,0.3)
  static const bioBoxFill = Color(0x4DFBFBFB);
  static const bioBoxRadius = 13.0;
  static const bioMaxLength = 30;

  // 메뉴 카드
  static const cardRadius = 13.0;
  static const cardShadow = Color(0xFFE5E5E5);
  static const cardShadowBlur = 5.2; // Figma layer blur 3.5px
  static const menuTop = 329.0;
  static const menuHorizontal = 24.0;
  static const menuGap = 16.0;
  static const rowHeight = 40.0;
  static const topRowHeight = 60.0;
  static const textLeft = 15.0;

  static const destructive = Color(0xFFFF6262);

  static TextStyle titleStyle(double scale) => TextStyle(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle nicknameStyle(double scale) => TextStyle(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );

  static TextStyle bioStyle(double scale) => TextStyle(
        fontSize: 13 * scale,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.35,
      );

  static TextStyle menuStyle(double scale, {bool destructive = false}) =>
      TextStyle(
        fontSize: 16 * scale,
        fontWeight: destructive ? FontWeight.w400 : FontWeight.w500,
        color: destructive ? FigmaSettingsTokens.destructive : Colors.black,
      );
}
