import 'package:flutter/material.dart';

import '../constants/figma_assets.dart';
import '../theme/figma_onboarding_tokens.dart';
import 'figma/figma_asset_image.dart';
import 'figma/figma_scale.dart';

/// 온보딩 입력 화면의 공통 뼈대 — 뒤로가기 · 햄핀이 말풍선 · 본문 · 하단 CTA.
///
/// 디자인(`439:419` 외)은 한 화면에 질문 하나만 두고 좌표를 공유한다.
/// 밑줄 아래 보조 영역만 화면마다 달라서 [children]으로 받는다.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.message,
    required this.children,
    required this.ctaLabel,
    required this.onCta,
    this.onBack,
    this.loading = false,
    this.ctaRounded = false,
  });

  /// 말풍선 문구 ("닉네임을 입력해조~").
  final String message;
  final List<Widget> children;
  final String ctaLabel;

  /// null이면 버튼이 비활성으로 보인다.
  final VoidCallback? onCta;
  final VoidCallback? onBack;
  final bool loading;

  /// 약관 화면(`439:2830`)은 키보드가 없어서 둥근 버튼이 여백 위에 뜬다.
  final bool ctaRounded;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return Scaffold(
      backgroundColor: FigmaOnboardingTokens.background,
      // 디자인 프레임(393×852)은 상태바를 포함한 좌표라 위쪽은 SafeArea를 끄고
      // y 값을 그대로 쓴다. 아래쪽만 홈 인디케이터를 피한다.
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: s(FigmaOnboardingTokens.backTop)),
                    SizedBox(
                      height: s(FigmaOnboardingTokens.backSvgHeight),
                      child: onBack == null
                          ? null
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: OnboardingBackButton(onPressed: onBack!),
                            ),
                    ),
                    SizedBox(height: s(FigmaOnboardingTokens.backToHamster)),
                    OnboardingHamsterBubble(message: message),
                    ...children,
                  ],
                ),
              ),
            ),
            _Cta(
              label: ctaLabel,
              onPressed: onCta,
              loading: loading,
              rounded: ctaRounded,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    // 디자인 박스는 10.644×21.069지만 획이 밖으로 넘쳐 SVG가 더 크다.
    // 박스 중심을 맞춰 얹어야 화살표가 디자인 위치에 온다.
    final overflowX =
        (FigmaOnboardingTokens.backSvgWidth -
            FigmaOnboardingTokens.backBoxWidth) /
        2;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          left: s(FigmaOnboardingTokens.backLeft - overflowX),
          right: s(16),
        ),
        child: FigmaSvg(
          FigmaAssets.onboardingBackArrow,
          width: s(FigmaOnboardingTokens.backSvgWidth),
          height: s(FigmaOnboardingTokens.backSvgHeight),
        ),
      ),
    );
  }
}

/// 햄핀이 + 말풍선 (`439:527` + `439:517`).
class OnboardingHamsterBubble extends StatelessWidget {
  const OnboardingHamsterBubble({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return SizedBox(
      height: s(FigmaOnboardingTokens.hamsterHeight),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: s(FigmaOnboardingTokens.hamsterLeft),
            top: 0,
            child: FigmaSvg(
              FigmaAssets.onboardingHamsterBubble,
              width: s(FigmaOnboardingTokens.hamsterWidth),
              height: s(FigmaOnboardingTokens.hamsterHeight),
            ),
          ),
          Positioned(
            left: s(FigmaOnboardingTokens.bubbleLeft),
            top: s(4), // 말풍선 135 − 햄스터 131
            child: Container(
              width: s(FigmaOnboardingTokens.bubbleWidth),
              height: s(FigmaOnboardingTokens.bubbleHeight),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FigmaOnboardingTokens.bubbleFill,
                borderRadius: BorderRadius.circular(
                  s(FigmaOnboardingTokens.bubbleRadius),
                ),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: FigmaOnboardingTokens.bubbleStyle(figma.scale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 라벨 + 밑줄 입력칸 (`439:523`~`439:526`).
class OnboardingField extends StatelessWidget {
  const OnboardingField({
    super.key,
    required this.label,
    required this.controller,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.autofocus = true,
    this.onSubmitted,
    this.onClear,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  /// 지우기(⊗) 버튼. null이면 버튼을 그리지 않는다.
  final VoidCallback? onClear;

  /// 비밀번호 화면의 눈 아이콘처럼 지우기 대신 놓을 위젯.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;
    // 밑줄은 23.33부터, 글자는 36부터 — 차이만큼 안쪽으로 더 민다.
    final textInset = s(FigmaOnboardingTokens.fieldLeft - 23.33);

    return Padding(
      padding: EdgeInsets.only(left: s(23.33), right: s(24.67)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: s(FigmaOnboardingTokens.hamsterToLabel)),
          Padding(
            padding: EdgeInsets.only(left: textInset),
            child: Text(
              label,
              style: FigmaOnboardingTokens.labelStyle(figma.scale),
            ),
          ),
          SizedBox(height: s(11)),
          Padding(
            padding: EdgeInsets.only(left: textInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    autofocus: autofocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: onSubmitted,
                    cursorColor: FigmaOnboardingTokens.accent,
                    style: FigmaOnboardingTokens.inputStyle(figma.scale),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: placeholder,
                      hintStyle: FigmaOnboardingTokens.inputStyle(
                        figma.scale,
                        color: FigmaOnboardingTokens.placeholder,
                      ),
                    ),
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: EdgeInsets.only(left: s(8), right: s(12.33)),
                    child: trailing,
                  )
                else if (onClear != null)
                  Padding(
                    padding: EdgeInsets.only(left: s(8), right: s(12.33)),
                    child: _ClearButton(onPressed: onClear!),
                  ),
              ],
            ),
          ),
          SizedBox(height: s(6)),
          Container(
            height: s(FigmaOnboardingTokens.underlineThickness),
            decoration: BoxDecoration(
              color: FigmaOnboardingTokens.accent,
              borderRadius: BorderRadius.circular(s(1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력칸과 같은 자리에 고정 값을 보여준다 — 인증 화면이 받는 주소를 띄울 때.
class OnboardingStaticField extends StatelessWidget {
  const OnboardingStaticField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;
    final textInset = s(FigmaOnboardingTokens.fieldLeft - 23.33);

    return Padding(
      padding: EdgeInsets.only(left: s(23.33), right: s(24.67)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: s(FigmaOnboardingTokens.hamsterToLabel)),
          Padding(
            padding: EdgeInsets.only(left: textInset),
            child: Text(
              label,
              style: FigmaOnboardingTokens.labelStyle(figma.scale),
            ),
          ),
          SizedBox(height: s(11)),
          Padding(
            padding: EdgeInsets.only(left: textInset),
            child: SizedBox(
              height: s(26),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FigmaOnboardingTokens.inputStyle(figma.scale),
                ),
              ),
            ),
          ),
          SizedBox(height: s(6)),
          Container(
            height: s(FigmaOnboardingTokens.underlineThickness),
            decoration: BoxDecoration(
              color: FigmaOnboardingTokens.accent,
              borderRadius: BorderRadius.circular(s(1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: s(FigmaOnboardingTokens.clearSize),
        height: s(FigmaOnboardingTokens.clearSize),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: FigmaOnboardingTokens.clearCircle,
          shape: BoxShape.circle,
        ),
        child: FigmaSvg(
          FigmaAssets.onboardingClearMark,
          width: s(FigmaOnboardingTokens.clearMarkSize),
          height: s(FigmaOnboardingTokens.clearMarkSize),
        ),
      ),
    );
  }
}

/// 밑줄 아래 한 줄 (도움말·타이머). 왼쪽 들여쓰기를 디자인 좌표로 받는다.
class OnboardingHelperLine extends StatelessWidget {
  const OnboardingHelperLine({
    super.key,
    required this.text,
    required this.topGap,
    this.left = FigmaOnboardingTokens.fieldLeft,
    this.color = FigmaOnboardingTokens.accent,
    this.underline = false,
    this.onTap,
  });

  final String text;
  final double topGap;
  final double left;
  final Color color;
  final bool underline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    final label = Text(
      text,
      style: FigmaOnboardingTokens.helperStyle(figma.scale, color: color)
          .copyWith(
            decoration: underline ? TextDecoration.underline : null,
            decorationColor: color,
          ),
    );

    return Padding(
      padding: EdgeInsets.only(left: s(left), top: s(topGap)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: onTap == null
            ? label
            : GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: label,
              ),
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({
    required this.label,
    required this.onPressed,
    required this.loading,
    required this.rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;
    final enabled = onPressed != null && !loading;

    final button = Container(
      height: s(FigmaOnboardingTokens.ctaHeight),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? FigmaOnboardingTokens.accent
            : FigmaOnboardingTokens.accent.withValues(alpha: 0.4),
        borderRadius: rounded
            ? BorderRadius.circular(s(FigmaOnboardingTokens.termsCtaRadius))
            : null,
      ),
      child: loading
          ? SizedBox(
              width: s(20),
              height: s(20),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label, style: FigmaOnboardingTokens.ctaStyle(figma.scale)),
    );

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: rounded
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                s(FigmaOnboardingTokens.termsCtaHorizontal),
                0,
                s(FigmaOnboardingTokens.termsCtaHorizontal),
                s(FigmaOnboardingTokens.termsCtaBottom),
              ),
              child: button,
            )
          : button,
    );
  }
}
