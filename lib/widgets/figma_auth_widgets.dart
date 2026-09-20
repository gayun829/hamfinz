import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../constants/figma_assets.dart';
import '../theme/app_theme.dart';
import '../theme/figma_auth_tokens.dart';
import 'figma/figma_asset_image.dart';
import 'figma/figma_scale.dart';

class FigmaAuthField extends StatelessWidget {
  const FigmaAuthField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
    this.borderColor = FigmaAuthTokens.inputBorder,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final Color borderColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FigmaAuthTokens.labelStyle(figma.scale)),
        SizedBox(height: s(FigmaAuthTokens.labelToField)),
        SizedBox(
          height: s(FigmaAuthTokens.fieldHeight),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  enabled: enabled,
                  style: FigmaAuthTokens.bodyStyle(
                    figma.scale,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: FigmaAuthTokens.bodyStyle(figma.scale),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: s(FigmaAuthTokens.fieldPaddingH),
                      vertical: s(FigmaAuthTokens.fieldPaddingV),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        s(FigmaAuthTokens.fieldRadius),
                      ),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        s(FigmaAuthTokens.fieldRadius),
                      ),
                      borderSide: const BorderSide(
                        color: FigmaAuthTokens.inputBorderAlt,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: s(8)),
                trailing!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class FigmaAuthDivider extends StatelessWidget {
  const FigmaAuthDivider({super.key, this.useSignupLine = false});

  final bool useSignupLine;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: s(useSignupLine ? 112 : 92)),
      child: SizedBox(
        height: s(36),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: FigmaSvg(
                  useSignupLine
                      ? FigmaAssets.authDividerLineSignup
                      : FigmaAssets.authDividerLine,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Container(
              color: FigmaAuthTokens.background,
              padding: EdgeInsets.symmetric(horizontal: s(16)),
              child: Text(
                '또는',
                style: FigmaAuthTokens.bodyStyle(
                  figma.scale,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FigmaSocialLoginRow extends StatelessWidget {
  const FigmaSocialLoginRow({
    super.key,
    required this.onGoogle,
    required this.onApple,
    required this.onKakao,
    this.useSignupAssets = false,
  });

  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onKakao;
  final bool useSignupAssets;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;
    final buttonSize = s(FigmaAuthTokens.socialButtonSize);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialCircleButton(
          size: buttonSize,
          onPressed: onGoogle,
          child: FigmaPng(
            useSignupAssets ? FigmaAssets.googleSignup : FigmaAssets.googleLogin,
            width: s(54),
            height: s(55),
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: s(FigmaAuthTokens.socialIconGap)),
        _SocialCircleButton(
          size: buttonSize,
          onPressed: onApple,
          child: FigmaPng(
            useSignupAssets ? FigmaAssets.appleSignup : FigmaAssets.appleLogin,
            width: s(54),
            height: s(64),
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: s(FigmaAuthTokens.socialIconGap)),
        _SocialCircleButton(
          size: buttonSize,
          onPressed: onKakao,
          child: FigmaPng(
            useSignupAssets ? FigmaAssets.kakaoSignup : FigmaAssets.kakaoLogin,
            width: s(58),
            height: s(57),
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  const _SocialCircleButton({
    required this.size,
    required this.onPressed,
    required this.child,
  });

  final double size;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: const BorderSide(color: FigmaAuthTokens.inputBorderAlt),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
        ),
        child: child,
      ),
    );
  }
}

class FigmaAuthFooterLink extends StatelessWidget {
  const FigmaAuthFooterLink({
    super.key,
    required this.prefix,
    required this.actionLabel,
    required this.onAction,
  });

  final String prefix;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prefix,
          style: FigmaAuthTokens.bodyStyle(
            figma.scale,
            color: FigmaAuthTokens.mutedText,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: FigmaAuthTokens.link,
            padding: EdgeInsets.symmetric(horizontal: s(4)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel, style: FigmaAuthTokens.linkStyle(figma.scale)),
        ),
      ],
    );
  }
}

class FigmaHamsterHero extends StatelessWidget {
  const FigmaHamsterHero({super.key, this.useSignupAsset = false});

  final bool useSignupAsset;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;

    final heroHeight = s(
      useSignupAsset
          ? FigmaAuthTokens.signupHeroHeight
          : FigmaAuthTokens.loginHeroHeight,
    );
    final hamsterTop = s(
      useSignupAsset
          ? FigmaAuthTokens.signupHamsterTop
          : FigmaAuthTokens.loginHamsterTop,
    );
    final hamsterWidth = s(
      useSignupAsset
          ? FigmaAuthTokens.signupHamsterWidth
          : FigmaAuthTokens.loginHamsterWidth,
    );
    final hamsterHeight = s(
      useSignupAsset
          ? FigmaAuthTokens.signupHamsterHeight
          : FigmaAuthTokens.loginHamsterHeight,
    );
    final glowSize = s(
      FigmaAuthTokens.heroGlowSize * 0.91 * 1.0509,
    );
    final glowTop = s(FigmaAuthTokens.heroGlowTop);
    final glowBlur = s(FigmaAuthTokens.heroGlowBlur);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: glowTop,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.flip(
                flipY: true,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: glowBlur,
                    sigmaY: glowBlur,
                  ),
                  child: Container(
                    width: glowSize,
                    height: glowSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: FigmaAuthTokens.heroGlowColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: hamsterTop,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.translate(
                offset: Offset(
                  useSignupAsset ? 0 : s(FigmaAuthTokens.loginHamsterCenterOffsetX),
                  0,
                ),
                child: FigmaPng(
                  useSignupAsset
                      ? FigmaAssets.hamsterSignup
                      : FigmaAssets.hamsterLogin,
                  width: hamsterWidth,
                  height: hamsterHeight,
                  fit: BoxFit.contain,
                  clip: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FigmaAuthPrimaryButton extends StatelessWidget {
  const FigmaAuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;

    return SizedBox(
      height: s(FigmaAuthTokens.primaryButtonHeight),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: FigmaAuthTokens.primaryButton,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              s(FigmaAuthTokens.primaryButtonRadius),
            ),
          ),
          textStyle: FigmaAuthTokens.buttonStyle(figma.scale),
        ),
        child: loading
            ? SizedBox(
                width: s(28),
                height: s(28),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class FigmaDuplicateCheckButton extends StatelessWidget {
  const FigmaDuplicateCheckButton({
    super.key,
    required this.onPressed,
    this.label = '중복확인',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;

    return SizedBox(
      width: s(FigmaAuthTokens.duplicateButtonWidth),
      height: s(FigmaAuthTokens.duplicateButtonHeight),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              s(FigmaAuthTokens.duplicateButtonRadius),
            ),
          ),
          side: const BorderSide(color: FigmaAuthTokens.duplicateAccent),
          foregroundColor: FigmaAuthTokens.duplicateAccent,
          backgroundColor: Colors.white,
          disabledForegroundColor: FigmaAuthTokens.duplicateAccent.withValues(
            alpha: 0.4,
          ),
          textStyle: FigmaAuthTokens.bodyStyle(
            figma.scale,
            color: FigmaAuthTokens.duplicateAccent,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// 가입 화면의 "(필수) 이용약관에 동의합니다" 한 줄. 링크만 눌러서 본문을 연다.
class FigmaLegalAgreementRow extends StatelessWidget {
  const FigmaLegalAgreementRow({
    super.key,
    required this.scale,
    required this.value,
    required this.onChanged,
    required this.labelPrefix,
    required this.linkLabel,
    required this.labelSuffix,
    required this.onOpenDocument,
  });

  final double scale;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String labelPrefix;
  final String linkLabel;
  final String labelSuffix;
  final VoidCallback onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final fontSize = 28 * scale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28 * scale,
          height: 28 * scale,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.figmaTeal,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4 * scale),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  labelPrefix,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
                GestureDetector(
                  onTap: onOpenDocument,
                  child: Text(
                    linkLabel,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: AppTheme.figmaLink,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      height: 1.35,
                    ),
                  ),
                ),
                Text(
                  labelSuffix,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
