import 'package:flutter/material.dart';

/// Figma node `273:181` 마이페이지 수정 (393×852).
/// 학습 과정 카드 `538:56`, 학습 과정 시트 `539:2373`, 로그아웃 팝업 `546:1381`.
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
  static const menuTop = 328.0;
  static const menuHorizontal = 24.0;
  static const menuGap = 16.0;
  static const rowHeight = 40.0;
  static const topRowHeight = 60.0;
  static const textLeft = 15.0;

  static const destructive = Color(0xFFFF6262);

  // 학습 과정 카드 (538:108, 345×132)
  static const learningCardHeight = 132.0;
  static const learningSubtitle = Color(0xFFA7A6A6);
  static const progressTrack = Color(0xFFEAEAEA);
  static const progressFillLeft = Color(0xFFFEC62E);
  static const progressFillRight = Color(0xFFFDAC4E);
  static const progressGloss = Color(0x5CF4FCFF); // #f4fcff 36%

  // 학습 과정 시트 (539:2507) — 곰 칩 색: 지난 단계 / 현재 단계 / 아직
  static const sheetHeight = 477.6;
  static const sheetRadius = 13.0;
  static const sheetHandle = Color(0xFFD9D9D9);
  static const sheetHint = Color(0xFFC8C8C8);
  static const stagePassed = Color(0xFFA3E6FF);
  static const stageCurrent = Color(0xFF70D9FF);
  static const stageLocked = Color(0xFFD9D9D9);

  // 팝업 뒤 어둡게 (546:1515 그라데이션을 단색으로 근사)
  static const scrim = Color(0x8C454545);

  // 로그아웃 팝업 (546:1517, 310×184)
  static const dialogWidth = 310.0;
  static const dialogHeight = 184.0;
  static const dialogFill = Color(0xFFFBFBFB);
  static const dialogAccent = Color(0xFF00AFF8);
  static const dialogCancelFill = Color(0xFFDDF5FF);

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

  static TextStyle learningTitleStyle(double scale) => TextStyle(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );

  static TextStyle learningSubtitleStyle(double scale) => TextStyle(
        fontSize: 12 * scale,
        fontWeight: FontWeight.w400,
        color: learningSubtitle,
      );

  /// 불꽃·곰 칩 위 단계 숫자 (Pretendard Thin 20.107).
  static TextStyle stageNumberStyle(double scale) => TextStyle(
        fontSize: 20.107 * scale,
        fontWeight: FontWeight.w100,
        color: Colors.white,
        height: 1,
      );

  static TextStyle sheetTitleStyle(double scale) => TextStyle(
        fontSize: 20 * scale,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );

  static TextStyle sheetBodyStyle(double scale, {Color color = learningSubtitle}) =>
      TextStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle sheetTierStyle(double scale) => TextStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w600,
        color: learningSubtitle,
      );

  static TextStyle dialogTitleStyle(double scale) => TextStyle(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );

  static TextStyle dialogMessageStyle(double scale) => TextStyle(
        fontSize: 17 * scale,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      );

  static TextStyle dialogButtonStyle(double scale) => TextStyle(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w600,
        color: dialogAccent,
      );

  static TextStyle menuStyle(double scale, {bool destructive = false}) =>
      TextStyle(
        fontSize: 16 * scale,
        fontWeight: destructive ? FontWeight.w400 : FontWeight.w500,
        color: destructive ? FigmaSettingsTokens.destructive : Colors.black,
      );
}
