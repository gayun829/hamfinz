import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Figma Dev Mode CSS 값 (node `1:152` 로그인, `1:195` 회원가입).
///
/// MCP `get_design_context`에서 읽은 spacing · color · typography를
/// Flutter 위젯 레이아웃에 그대로 매핑한다. (절대 좌표 Stack 대신 Column spacing)
abstract final class FigmaAuthTokens {
  static const designWidth = 1212.67;

  // Colors (Dev Mode hex)
  static const background = AppTheme.figmaAuthBackground; // #f5faff
  static const primaryButton = AppTheme.figmaPrimaryButton; // #67d3fa
  static const inputBorder = AppTheme.figmaInputBorder; // #9eb6ce
  static const inputBorderAlt = AppTheme.figmaInputBorderAlt; // #93a8bd
  static const placeholder = AppTheme.figmaPlaceholder; // #93a8bd
  static const mutedText = Color(0xFF919299);
  static const link = AppTheme.figmaLink; // #1ba1b9
  static const duplicateAccent = Color(0xFF73B8BD);

  // Typography (Dev Mode px, Inter Regular)
  static const labelFontSize = 42.0;
  static const bodyFontSize = 30.0;
  static const linkFontSize = 32.0;
  static const buttonFontSize = 42.0;

  // Field geometry
  static const fieldHeight = 131.0;
  static const fieldRadius = 50.0;
  static const fieldPaddingH = 43.0;
  static const fieldPaddingV = 36.0;
  static const labelToField = 12.0;

  // Button geometry
  static const primaryButtonHeight = 165.0;
  static const primaryButtonRadius = 82.5;
  static const socialButtonSize = 143.0;
  static const socialIconGap = 43.0;
  static const duplicateButtonWidth = 204.0;
  static const duplicateButtonHeight = 74.0;
  static const duplicateButtonRadius = 30.0;

  // Hero (glow node `1:153` / `1:196`, hamster `87:7` / `87:19`)
  static const heroGlowSize = 464.0;
  static const heroGlowTop = 231.0;
  static const heroGlowColor = Color(0x6167D3FA);
  static const heroGlowBlur = 11.8;

  static const loginHamsterTop = 322.0;
  static const loginHamsterWidth = 333.0;
  static const loginHamsterHeight = 453.0;

  static const signupHamsterTop = 357.0;
  static const signupHamsterWidth = 306.0;
  static const signupHamsterHeight = 384.147;

  // Horizontal padding (Dev Mode left offsets)
  static const loginFieldPaddingX = 109.0;
  static const loginButtonPaddingX = 88.0;
  static const signupFieldPaddingX = 112.0;
  static const signupNicknameFieldPaddingX = 105.0;
  static const signupButtonPaddingX = 106.0;

  // Login vertical spacing (derived from Dev Mode top values)
  static const loginHeroHeight = loginHamsterTop + loginHamsterHeight; // 775
  static const loginHeroToForm = 108.0; // 883 - 775
  static const loginFieldGap = 82.0; // password label - email field bottom
  static const loginForgotTopGap = 42.0; // forgot - password field bottom
  static const loginButtonTopGap = 205.0; // button - forgot bottom
  static const loginDividerTopGap = 108.0; // divider - button bottom
  static const loginSocialTopGap = 98.0; // social - divider
  static const loginFooterTopGap = 232.0; // footer - social bottom

  // Signup vertical spacing
  static const signupHeroHeight = signupHamsterTop + signupHamsterHeight; // 741.147
  static const signupHeroToForm = 64.853; // 806 - 741.147

  static TextStyle labelStyle(double scale) => TextStyle(
        fontSize: labelFontSize * scale,
        fontWeight: FontWeight.w400,
        color: Colors.black,
        height: 1.1,
      );

  static TextStyle bodyStyle(double scale, {Color? color}) => TextStyle(
        fontSize: bodyFontSize * scale,
        fontWeight: FontWeight.w400,
        color: color ?? placeholder,
        height: 1.1,
      );

  static TextStyle linkStyle(double scale) => TextStyle(
        fontSize: linkFontSize * scale,
        fontWeight: FontWeight.w400,
        color: link,
        height: 1.1,
      );

  static TextStyle buttonStyle(double scale) => TextStyle(
        fontSize: buttonFontSize * scale,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1.1,
      );
}
