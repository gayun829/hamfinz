import 'package:flutter/material.dart';

import '../theme/figma_settings_tokens.dart';
import 'figma/figma_scale.dart';

/// 설정 화면 메뉴 — [FigmaAuthField]·퀴즈 보기와 동일한 흰 배경 + 테두리 pill.
class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaSettingsTokens.designWidth,
    );
    final s = figma.s;
    final borderColor =
        destructive ? FigmaSettingsTokens.destructive : FigmaSettingsTokens.menuButtonBorder;
    final textColor =
        destructive ? FigmaSettingsTokens.destructive : Colors.black;

    return SizedBox(
      width: double.infinity,
      height: s(FigmaSettingsTokens.menuButtonHeight),
      child: Material(
        color: FigmaSettingsTokens.menuButtonBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s(FigmaSettingsTokens.menuButtonRadius)),
          side: BorderSide(color: borderColor, width: s(3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: FigmaSettingsTokens.menuItemStyle(figma.scale).copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 하단 [설정 완료] — 홈·퀴즈 CTA와 동일한 채움 pill.
class SettingsPrimaryButton extends StatelessWidget {
  const SettingsPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaSettingsTokens.designWidth,
    );
    final s = figma.s;

    return SizedBox(
      width: double.infinity,
      height: s(FigmaSettingsTokens.buttonHeight),
      child: Material(
        color: FigmaSettingsTokens.completeButton,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s(FigmaSettingsTokens.buttonRadius)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: FigmaSettingsTokens.buttonStyle(figma.scale),
            ),
          ),
        ),
      ),
    );
  }
}
