import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../theme/app_theme.dart';
import 'figma_asset_image.dart';
import 'figma_canvas.dart';
import 'figma_scale.dart';

/// Figma node `1:195` 좌표 (1212.67×2629).
abstract final class SignupFigmaLayout {
  static const heroGlowLeft = 374.0;
  static const heroGlowTop = 231.0;
  static const heroGlowSize = 464.0;

  static const hamsterLeft = 455.0;
  static const hamsterTop = 357.0;
  static const hamsterWidth = 306.0;
  static const hamsterHeight = 384.147;

  static const nicknameLabelLeft = 112.0;
  static const nicknameLabelTop = 806.0;
  static const emailLabelLeft = 112.0;
  static const emailLabelTop = 1113.0;
  static const passwordLabelLeft = 112.0;
  static const passwordLabelTop = 1420.0;
  static const labelFontSize = 42.0;

  static const nicknameFieldLeft = 105.0;
  static const nicknameFieldTop = 900.0;
  static const emailFieldLeft = 112.0;
  static const emailFieldTop = 1207.0;
  static const passwordFieldLeft = 112.0;
  static const passwordFieldTop = 1508.0;
  static const fieldWidth = 997.0;
  static const fieldHeight = 131.0;
  static const fieldRadius = 50.0;
  static const fieldFontSize = 30.0;

  static const duplicateButtonLeft = 860.0;
  static const duplicateButtonTop = 929.0;
  static const duplicateButtonWidth = 204.0;
  static const duplicateButtonHeight = 74.0;
  static const duplicateButtonRadius = 30.0;
  static const duplicateTextLeft = 905.0;
  static const duplicateTextTop = 948.0;
  static const duplicateTextSize = 30.0;

  static const signupButtonLeft = 106.0;
  static const signupButtonTop = 1783.0;
  static const signupButtonWidth = 998.0;
  static const signupButtonHeight = 165.0;
  static const signupButtonRadius = 82.5;
  static const signupTextLeft = 521.0;
  static const signupTextTop = 1843.0;
  static const signupTextSize = 42.0;

  static const dividerLeft = 112.0;
  static const dividerTop = 2044.72;
  static const dividerWidth = 989.503;
  static const dividerHeight = 12.55;
  static const orTextLeft = 580.0;
  static const orTextTop = 2035.0;
  static const orTextSize = 30.0;

  static const googleButtonLeft = 347.0;
  static const appleButtonLeft = 535.0;
  static const kakaoButtonLeft = 723.0;
  static const socialButtonTop = 2143.0;
  static const appleButtonTop = 2144.0;
  static const socialButtonWidth = 145.0;
  static const socialButtonHeight = 143.0;
  static const socialButtonRadius = 89.0;

  static const googleLogoLeft = 393.0;
  static const googleLogoTop = 2187.0;
  static const googleLogoWidth = 54.0;
  static const googleLogoHeight = 55.0;
  static const appleLogoLeft = 580.0;
  static const appleLogoTop = 2183.0;
  static const appleLogoWidth = 54.0;
  static const appleLogoHeight = 64.0;
  static const kakaoLogoLeft = 767.0;
  static const kakaoLogoTop = 2190.0;
  static const kakaoLogoWidth = 58.0;
  static const kakaoLogoHeight = 57.0;

  static const footerPrefixLeft = 361.0;
  static const footerTop = 2447.0;
  static const footerPrefixSize = 30.0;
  static const loginLeft = 731.0;
  static const loginWidth = 120.0;
  static const loginSize = 32.0;

  static const errorLeft = 112.0;
  static const errorTop = 1660.0;
  static const errorWidth = 997.0;
}

List<Widget> buildSignupFigmaLayers({
  required FigmaScale figma,
  required TextEditingController nicknameController,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required bool loading,
  required String? error,
  required VoidCallback onSubmit,
  required VoidCallback onCheckDuplicate,
  required VoidCallback onSwitchToLogin,
  required VoidCallback onGoogle,
  required VoidCallback onApple,
  required VoidCallback onKakao,
}) {
  final s = figma.s;

  return [
    FigmaAuthHeroGlow(
      figma: figma,
      left: SignupFigmaLayout.heroGlowLeft,
      top: SignupFigmaLayout.heroGlowTop,
      size: SignupFigmaLayout.heroGlowSize,
    ),
    FigmaBox(
      figma: figma,
      left: SignupFigmaLayout.hamsterLeft,
      top: SignupFigmaLayout.hamsterTop,
      width: SignupFigmaLayout.hamsterWidth,
      height: SignupFigmaLayout.hamsterHeight,
      child: FigmaPng(
        FigmaAssets.hamsterSignup,
        fit: BoxFit.contain,
        clip: true,
      ),
    ),

    FigmaLabel(
      figma: figma,
      left: SignupFigmaLayout.nicknameLabelLeft,
      top: SignupFigmaLayout.nicknameLabelTop,
      fontSize: SignupFigmaLayout.labelFontSize,
      text: '닉네임',
    ),
    FigmaLabel(
      figma: figma,
      left: SignupFigmaLayout.emailLabelLeft,
      top: SignupFigmaLayout.emailLabelTop,
      fontSize: SignupFigmaLayout.labelFontSize,
      text: '아이디(이메일)',
    ),
    FigmaLabel(
      figma: figma,
      left: SignupFigmaLayout.passwordLabelLeft,
      top: SignupFigmaLayout.passwordLabelTop,
      fontSize: SignupFigmaLayout.labelFontSize,
      text: '비밀번호',
    ),

    _buildAuthField(
      figma: figma,
      left: SignupFigmaLayout.nicknameFieldLeft,
      top: SignupFigmaLayout.nicknameFieldTop,
      controller: nicknameController,
      hint: '닉네임을 입력하세요',
      borderColor: AppTheme.figmaInputBorder,
    ),
    FigmaTapArea(
      figma: figma,
      left: SignupFigmaLayout.duplicateButtonLeft,
      top: SignupFigmaLayout.duplicateButtonTop,
      width: SignupFigmaLayout.duplicateButtonWidth,
      height: SignupFigmaLayout.duplicateButtonHeight,
      onTap: onCheckDuplicate,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            figma.s(SignupFigmaLayout.duplicateButtonRadius),
          ),
          border: Border.all(color: const Color(0xFF73B8BD)),
        ),
        child: Center(
          child: Text(
            '중복확인',
            style: TextStyle(
              fontSize: figma.s(SignupFigmaLayout.duplicateTextSize),
              color: const Color(0xFF73B8BD),
            ),
          ),
        ),
      ),
    ),

    _buildAuthField(
      figma: figma,
      left: SignupFigmaLayout.emailFieldLeft,
      top: SignupFigmaLayout.emailFieldTop,
      controller: emailController,
      hint: '아이디/ 이메일 주소를 입력하세요',
      keyboardType: TextInputType.emailAddress,
      borderColor: AppTheme.figmaInputBorderAlt,
    ),
    _buildAuthField(
      figma: figma,
      left: SignupFigmaLayout.passwordFieldLeft,
      top: SignupFigmaLayout.passwordFieldTop,
      controller: passwordController,
      hint: '비밀번호를 입력하세요',
      obscureText: true,
      borderColor: AppTheme.figmaInputBorderAlt,
    ),

    if (error != null)
      FigmaBox(
        figma: figma,
        left: SignupFigmaLayout.errorLeft,
        top: SignupFigmaLayout.errorTop,
        width: SignupFigmaLayout.errorWidth,
        child: Text(
          error,
          style: TextStyle(
            fontSize: figma.s(28),
            color: AppTheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

    FigmaPill(
      figma: figma,
      left: SignupFigmaLayout.signupButtonLeft,
      top: SignupFigmaLayout.signupButtonTop,
      width: SignupFigmaLayout.signupButtonWidth,
      height: SignupFigmaLayout.signupButtonHeight,
      color: AppTheme.figmaPrimaryButton,
      radius: SignupFigmaLayout.signupButtonRadius,
    ),
    FigmaTapArea(
      figma: figma,
      left: SignupFigmaLayout.signupButtonLeft,
      top: SignupFigmaLayout.signupButtonTop,
      width: SignupFigmaLayout.signupButtonWidth,
      height: SignupFigmaLayout.signupButtonHeight,
      onTap: loading ? null : onSubmit,
      child: Center(
        child: loading
            ? SizedBox(
                width: s(32),
                height: s(32),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                '회원가입',
                style: TextStyle(
                  fontSize: s(SignupFigmaLayout.signupTextSize),
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
      ),
    ),

    FigmaBox(
      figma: figma,
      left: SignupFigmaLayout.dividerLeft,
      top: SignupFigmaLayout.dividerTop,
      width: SignupFigmaLayout.dividerWidth,
      height: SignupFigmaLayout.dividerHeight,
      child: const FigmaSvg(FigmaAssets.authDividerLineSignup, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: SignupFigmaLayout.orTextLeft - 20,
      top: SignupFigmaLayout.orTextTop - 8,
      width: 96,
      height: 52,
      child: const ColoredBox(color: AppTheme.figmaAuthBackground),
    ),
    FigmaLabel(
      figma: figma,
      left: SignupFigmaLayout.orTextLeft,
      top: SignupFigmaLayout.orTextTop,
      fontSize: SignupFigmaLayout.orTextSize,
      text: '또는',
    ),

    _buildSocialButton(
      figma: figma,
      left: SignupFigmaLayout.googleButtonLeft,
      top: SignupFigmaLayout.socialButtonTop,
      onTap: onGoogle,
    ),
    _buildSocialButton(
      figma: figma,
      left: SignupFigmaLayout.appleButtonLeft,
      top: SignupFigmaLayout.appleButtonTop,
      onTap: onApple,
    ),
    _buildSocialButton(
      figma: figma,
      left: SignupFigmaLayout.kakaoButtonLeft,
      top: SignupFigmaLayout.appleButtonTop,
      onTap: onKakao,
    ),

    FigmaBox(
      figma: figma,
      left: SignupFigmaLayout.googleLogoLeft,
      top: SignupFigmaLayout.googleLogoTop,
      width: SignupFigmaLayout.googleLogoWidth,
      height: SignupFigmaLayout.googleLogoHeight,
      child: IgnorePointer(
        child: FigmaPng(
          FigmaAssets.googleSignup,
          width: s(SignupFigmaLayout.googleLogoWidth),
          height: s(SignupFigmaLayout.googleLogoHeight),
          fit: BoxFit.contain,
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: SignupFigmaLayout.appleLogoLeft,
      top: SignupFigmaLayout.appleLogoTop,
      width: SignupFigmaLayout.appleLogoWidth,
      height: SignupFigmaLayout.appleLogoHeight,
      child: IgnorePointer(
        child: FigmaPng(
          FigmaAssets.appleSignup,
          width: s(SignupFigmaLayout.appleLogoWidth),
          height: s(SignupFigmaLayout.appleLogoHeight),
          fit: BoxFit.contain,
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: SignupFigmaLayout.kakaoLogoLeft,
      top: SignupFigmaLayout.kakaoLogoTop,
      width: SignupFigmaLayout.kakaoLogoWidth,
      height: SignupFigmaLayout.kakaoLogoHeight,
      child: IgnorePointer(
        child: FigmaPng(
          FigmaAssets.kakaoSignup,
          width: s(SignupFigmaLayout.kakaoLogoWidth),
          height: s(SignupFigmaLayout.kakaoLogoHeight),
          fit: BoxFit.contain,
        ),
      ),
    ),

    FigmaLabel(
      figma: figma,
      left: SignupFigmaLayout.footerPrefixLeft,
      top: SignupFigmaLayout.footerTop,
      fontSize: SignupFigmaLayout.footerPrefixSize,
      color: const Color(0xFF919299),
      text: '이미 계정을 가지고 있나요?',
    ),
    FigmaTapArea(
      figma: figma,
      left: SignupFigmaLayout.loginLeft,
      top: SignupFigmaLayout.footerTop,
      width: SignupFigmaLayout.loginWidth,
      height: 48,
      onTap: onSwitchToLogin,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '로그인',
          style: TextStyle(
            fontSize: s(SignupFigmaLayout.loginSize),
            color: AppTheme.figmaLink,
          ),
        ),
      ),
    ),
  ];
}

Widget _buildAuthField({
  required FigmaScale figma,
  required double left,
  required double top,
  required TextEditingController controller,
  required String hint,
  bool obscureText = false,
  TextInputType? keyboardType,
  required Color borderColor,
}) {
  return FigmaBox(
    figma: figma,
    left: left,
    top: top,
    width: SignupFigmaLayout.fieldWidth,
    height: SignupFigmaLayout.fieldHeight,
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: figma.s(SignupFigmaLayout.fieldFontSize),
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: figma.s(SignupFigmaLayout.fieldFontSize),
          color: AppTheme.figmaPlaceholder,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: figma.s(43),
          vertical: figma.s(36),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(figma.s(SignupFigmaLayout.fieldRadius)),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(figma.s(SignupFigmaLayout.fieldRadius)),
          borderSide: const BorderSide(
            color: AppTheme.figmaInputBorderAlt,
            width: 1.5,
          ),
        ),
      ),
    ),
  );
}

Widget _buildSocialButton({
  required FigmaScale figma,
  required double left,
  required double top,
  required VoidCallback onTap,
}) {
  return FigmaTapArea(
    figma: figma,
    left: left,
    top: top,
    width: SignupFigmaLayout.socialButtonWidth,
    height: SignupFigmaLayout.socialButtonHeight,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          figma.s(SignupFigmaLayout.socialButtonRadius),
        ),
        border: Border.all(color: AppTheme.figmaInputBorderAlt),
      ),
    ),
  );
}
