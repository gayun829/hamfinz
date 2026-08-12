import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Figma node `1:242` 퀴즈 객관식1 Dev Mode CSS 토큰.
abstract final class FigmaQuizTokens {
  static const designWidth = 1212.67;

  static const background = Colors.white;
  static const progressTrack = Color(0xFFE6E6E6);
  static const progressFill = Color(0xFF55DBD0);
  static const progressHighlight = Color(0xFFF4FCFF);
  static const footerMint = AppTheme.figmaMintLight;
  static const footerButtonTop = AppTheme.figmaMintDeep;
  static const footerButtonBottom = AppTheme.figmaTeal;
  static const submitButton = Color(0xFF9CE5FF);
  static const optionBorder = Color(0xFFE4E4E4);
  static const optionShadow = Color(0xFFE4E4E4);
  static const optionSelectedBg = Color(0xFFE6F8FF);
  static const optionSelectedBorder = Color(0xFF9CE5FF);
  static const optionCorrectBg = Color(0xFFDCFCE7);
  static const optionWrongBg = Color(0xFFFEE2E2);

  static const progressHeight = 52.0;
  static const progressRadius = 24.818;
  static const horizontalPadding = 88.0;
  static const heroTop = 24.0;
  static const heroWidth = 438.0;
  static const heroHeight = 596.0;
  static const shadowWidth = 414.0;
  static const shadowHeight = 137.0;
  static const categoryTopGap = 16.0;
  static const categoryHeight = 72.0;
  static const questionTopGap = 24.0;
  static const optionGap = 16.0;
  static const optionHeight = 132.0;
  static const optionRadius = 50.0;
  static const optionShadowOffset = 11.0;
  static const optionBorderWidth = 6.0;
  static const resultTopGap = 20.0;
  static const footerHeight = 472.0;
  static const footerButtonHeight = 142.0;
  static const footerButtonRadius = 57.841;
  static const submitButtonHeight = 141.0;
  static const submitButtonRadius = 46.285;
  static const dualButtonGap = 24.0;

  static const categoryFontSize = 32.0;
  static const questionFontSize = 42.0;
  static const optionFontSize = 36.0;
  static const footerFontSize = 45.0;
  static const resultFontSize = 36.0;

  // OX 가로 (node 1:376 / 퀴즈 OX 가로)
  static const oxCardRadius = 95.0;
  static const oxCardShadowOffset = 8.0;
  static const oxCardShadowColor = Color(0xFFABC8D3);
  static const oxCardBorder = Color(0xFF9CE5FF);
  static const oxChoiceGap = 24.0;
  static const oxChoiceRadius = 80.0;
  static const oxChoiceFontSize = 120.0;
  static const oxCardInnerPadding = 24.0;
  static const oxHamsterWidthRatio = 0.4;
  static const oxHeroFlex = 30;
  static const oxCardFlex = 70;
  static const oxHeroCardGap = 4.0;
  /// Figma `oxQuestionAreaHeight`(397) — 텍스트 높이만큼만, 최대 이 값.
  static const oxQuestionAreaHeight = 260.0;
  static const oxQuestionFontSize = 38.0;
  static const oxQuestionAreaMaxFraction = 0.32;
  static const oxSelectedFill = Color(0xFF9CE5FF);
  static const oxDefaultFill = Color(0xFFF3F3F3);
  static const oxCorrectFill = Color(0xFF84F028);
  static const oxWrongFill = Color(0xFFFF6B5B);

  static TextStyle questionStyle(double scale) => TextStyle(
        fontSize: questionFontSize * scale,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
        height: 1.35,
      );

  static TextStyle optionStyle(double scale) => TextStyle(
        fontSize: optionFontSize * scale,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        height: 1.2,
      );

  static TextStyle footerButtonStyle(double scale) => TextStyle(
        fontSize: footerFontSize * scale,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.1,
      );
}
