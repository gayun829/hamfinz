import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../theme/app_theme.dart';
import 'figma_asset_image.dart';
import 'figma_canvas.dart';
import 'figma_scale.dart';

/// Figma node `1:152` 좌표 (1212.67×2629).
abstract final class LoginFigmaLayout {
  static const heroGlowLeft = 374.0;
  static const heroGlowTop = 231.0;
  static const heroGlowSize = 464.0;

  static const hamsterLeft = 423.0;
  static const hamsterTop = 322.0;
  static const hamsterWidth = 333.0;
  static const hamsterHeight = 453.0;

  static const emailLabelLeft = 111.0;
  static const emailLabelTop = 883.0;
  static const passwordLabelLeft = 109.0;
  static const passwordLabelTop = 1185.0;
  static const labelFontSize = 42.0;

  static const emailFieldLeft = 109.0;
  static const emailFieldTop = 972.0;
  static const passwordFieldLeft = 109.0;
  static const passwordFieldTop = 1279.0;
  static const fieldWidth = 997.0;
  static const fieldHeight = 131.0;
  static const fieldRadius = 50.0;
  static const fieldFontSize = 30.0;

  static const forgotLeft = 152.0;
  static const forgotTop = 1452.0;
  static const forgotWidth = 313.0;
  static const forgotHeight = 40.0;
  static const forgotFontSize = 30.0;

  static const loginButtonLeft = 88.0;
  static const loginButtonTop = 1693.0;
  static const loginButtonWidth = 998.0;
  static const loginButtonHeight = 165.0;
  static const loginButtonRadius = 82.5;
  static const loginTextLeft = 541.0;
  static const loginTextTop = 1756.0;
  static const loginTextSize = 42.0;

  static const dividerLeft = 92.0;
  static const dividerTop = 1965.72;
  static const dividerWidth = 989.503;
  static const dividerHeight = 12.55;
  static const orTextLeft = 560.0;
  static const orTextTop = 1956.0;
  static const orTextSize = 30.0;

  static const googleButtonLeft = 327.0;
  static const appleButtonLeft = 515.0;
  static const kakaoButtonLeft = 703.0;
  static const socialButtonTop = 2064.0;
  static const appleButtonTop = 2065.0;
  static const socialButtonWidth = 145.0;
  static const socialButtonHeight = 143.0;
  static const socialButtonRadius = 89.0;

  static const googleLogoLeft = 373.0;
  static const googleLogoTop = 2108.0;
  static const googleLogoWidth = 54.0;
  static const googleLogoHeight = 55.0;
  static const appleLogoLeft = 560.0;
  static const appleLogoTop = 2104.0;
  static const appleLogoWidth = 54.0;
  static const appleLogoHeight = 64.0;
  static const kakaoLogoLeft = 747.0;
  static const kakaoLogoTop = 2111.0;
  static const kakaoLogoWidth = 58.0;
  static const kakaoLogoHeight = 57.0;

  static const footerPrefixLeft = 361.0;
  static const footerTop = 2439.0;
  static const footerPrefixSize = 30.0;
  static const signupLeft = 731.0;
  static const signupWidth = 120.0;
  static const signupSize = 32.0;

  static const errorLeft = 109.0;
  static const errorTop = 1580.0;
  static const errorWidth = 997.0;
}

List<Widget> buildLoginFigmaLayers({
  required FigmaScale figma,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required bool loading,
  required String? error,
  required VoidCallback onSubmit,
  required VoidCallback onForgotPassword,
  required VoidCallback onSignup,
  required VoidCallback onGoogle,
  required VoidCallback onApple,
  required VoidCallback onKakao,
}) {
  final s = figma.s;

  return [
    FigmaAuthHeroGlow(
      figma: figma,
      left: LoginFigmaLayout.heroGlowLeft,
      top: LoginFigmaLayout.heroGlowTop,
      size: LoginFigmaLayout.heroGlowSize,
    ),
    FigmaBox(
      figma: figma,
      left: LoginFigmaLayout.hamsterLeft,
      top: LoginFigmaLayout.hamsterTop,
      width: LoginFigmaLayout.hamsterWidth,
      height: LoginFigmaLayout.hamsterHeight,
      child: FigmaPng(
        FigmaAssets.hamsterLogin,
        fit: BoxFit.contain,
        clip: true,
      ),
    ),

    FigmaLabel(
      figma: figma,
      left: LoginFigmaLayout.emailLabelLeft,
      top: LoginFigmaLayout.emailLabelTop,
      fontSize: LoginFigmaLayout.labelFontSize,
      text: '아이디(이메일)',
    ),
    FigmaLabel(
      figma: figma,
      left: LoginFigmaLayout.passwordLabelLeft,
      top: LoginFigmaLayout.passwordLabelTop,
      fontSize: LoginFigmaLayout.labelFontSize,
      text: '비밀번호',
    ),

    _buildAuthField(
      figma: figma,
      left: LoginFigmaLayout.emailFieldLeft,
      top: LoginFigmaLayout.emailFieldTop,
      controller: emailController,
      hint: '아이디/ 이메일 주소를 입력하세요',
      keyboardType: TextInputType.emailAddress,
      borderColor: AppTheme.figmaInputBorder,
    ),
    _buildAuthField(
      figma: figma,
      left: LoginFigmaLayout.passwordFieldLeft,
      top: LoginFigmaLayout.passwordFieldTop,
      controller: passwordController,
      hint: '비밀번호를 입력하세요',
      obscureText: true,
      borderColor: AppTheme.figmaInputBorderAlt,
    ),

    FigmaTapArea(
      figma: figma,
      left: LoginFigmaLayout.forgotLeft,
      top: LoginFigmaLayout.forgotTop,
      width: LoginFigmaLayout.forgotWidth,
      height: LoginFigmaLayout.forgotHeight,
      onTap: onForgotPassword,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '비밀번호를 잊으셨나요?',
          style: TextStyle(
            fontSize: s(LoginFigmaLayout.forgotFontSize),
            color: const Color(0xFF919299),
          ),
        ),
      ),
    ),

    if (error != null)
      FigmaBox(
        figma: figma,
        left: LoginFigmaLayout.errorLeft,
        top: LoginFigmaLayout.errorTop,
        width: LoginFigmaLayout.errorWidth,
        child: Text(
          error,
          style: TextStyle(
            fontSize: s(28),
            color: AppTheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

    FigmaPill(
      figma: figma,
      left: LoginFigmaLayout.loginButtonLeft,
      top: LoginFigmaLayout.loginButtonTop,
      width: LoginFigmaLayout.loginButtonWidth,
      height: LoginFigmaLayout.loginButtonHeight,
      color: AppTheme.figmaPrimaryButton,
      radius: LoginFigmaLayout.loginButtonRadius,
    ),
    FigmaTapArea(
      figma: figma,
      left: LoginFigmaLayout.loginButtonLeft,
      top: LoginFigmaLayout.loginButtonTop,
      width: LoginFigmaLayout.loginButtonWidth,
      height: LoginFigmaLayout.loginButtonHeight,
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
                '로그인',
                style: TextStyle(
                  fontSize: s(LoginFigmaLayout.loginTextSize),
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
      ),
    ),

    FigmaBox(
      figma: figma,
      left: LoginFigmaLayout.dividerLeft,
      top: LoginFigmaLayout.dividerTop,
      width: LoginFigmaLayout.dividerWidth,
      height: LoginFigmaLayout.dividerHeight,
      child: const FigmaSvg(FigmaAssets.authDividerLine, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: LoginFigmaLayout.orTextLeft - 20,
      top: LoginFigmaLayout.orTextTop - 8,
      width: 96,
      height: 52,
      child: ColoredBox(color: AppTheme.figmaAuthBackground),
    ),
    FigmaLabel(
      figma: figma,
      left: LoginFigmaLayout.orTextLeft,
      top: LoginFigmaLayout.orTextTop,
      fontSize: LoginFigmaLayout.orTextSize,
      text: '또는',
    ),

    _buildSocialButton(
      figma: figma,
      left: LoginFigmaLayout.googleButtonLeft,
      top: LoginFigmaLayout.socialButtonTop,
      onTap: onGoogle,
    ),
    _buildSocialButton(
      figma: figma,
      left: LoginFigmaLayout.appleButtonLeft,
      top: LoginFigmaLayout.appleButtonTop,
      onTap: onApple,
    ),
    _buildSocialButton(
      figma: figma,
      left: LoginFigmaLayout.kakaoButtonLeft,
      top: LoginFigmaLayout.appleButtonTop,
      onTap: onKakao,
    ),

    FigmaBox(
      figma: figma,
      left: LoginFigmaLayout.googleLogoLeft,
      top: LoginFigmaLayout.googleLogoTop,
      width: LoginFigmaLayout.googleLogoWidth,
      height: LoginFigmaLayout.googleLogoHeight,
      child: IgnorePointer(
        child: FigmaPng(
          FigmaAssets.googleLogin,
          width: s(LoginFigmaLayout.googleLogoWidth),
          height: s(LoginFigmaLayout.googleLogoHeight),
          fit: BoxFit.contain,
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: LoginFigmaLayout.appleLogoLeft,
      top: LoginFigmaLayout.appleLogoTop,
      width: LoginFigmaLayout.appleLogoWidth,
      height: LoginFigmaLayout.appleLogoHeight,
      child: IgnorePointer(
        child: FigmaPng(
          FigmaAssets.appleLogin,
          width: s(LoginFigmaLayout.appleLogoWidth),
          height: s(LoginFigmaLayout.appleLogoHeight),
          fit: BoxFit.contain,
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: LoginFigmaLayout.kakaoLogoLeft,
      top: LoginFigmaLayout.kakaoLogoTop,
      width: LoginFigmaLayout.kakaoLogoWidth,
      height: LoginFigmaLayout.kakaoLogoHeight,
      child: IgnorePointer(
        child: FigmaPng(
          FigmaAssets.kakaoLogin,
          width: s(LoginFigmaLayout.kakaoLogoWidth),
          height: s(LoginFigmaLayout.kakaoLogoHeight),
          fit: BoxFit.contain,
        ),
      ),
    ),

    FigmaLabel(
      figma: figma,
      left: LoginFigmaLayout.footerPrefixLeft,
      top: LoginFigmaLayout.footerTop,
      fontSize: LoginFigmaLayout.footerPrefixSize,
      color: const Color(0xFF919299),
      text: '기존 계정을 찾을 수 없나요?',
    ),
    FigmaTapArea(
      figma: figma,
      left: LoginFigmaLayout.signupLeft,
      top: LoginFigmaLayout.footerTop,
      width: LoginFigmaLayout.signupWidth,
      height: 48,
      onTap: onSignup,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '회원가입',
          style: TextStyle(
            fontSize: s(LoginFigmaLayout.signupSize),
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
    width: LoginFigmaLayout.fieldWidth,
    height: LoginFigmaLayout.fieldHeight,
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: figma.s(LoginFigmaLayout.fieldFontSize),
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: figma.s(LoginFigmaLayout.fieldFontSize),
          color: AppTheme.figmaPlaceholder,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: figma.s(43),
          vertical: figma.s(36),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(figma.s(LoginFigmaLayout.fieldRadius)),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(figma.s(LoginFigmaLayout.fieldRadius)),
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
    width: LoginFigmaLayout.socialButtonWidth,
    height: LoginFigmaLayout.socialButtonHeight,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          figma.s(LoginFigmaLayout.socialButtonRadius),
        ),
        border: Border.all(color: AppTheme.figmaInputBorderAlt),
      ),
    ),
  );
}
