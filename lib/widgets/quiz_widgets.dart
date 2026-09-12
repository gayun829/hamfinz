import 'package:flutter/material.dart';

import '../constants/figma_assets.dart';
import '../theme/app_theme.dart';
import '../theme/figma_quiz_tokens.dart';
import 'figma/figma_asset_image.dart';
import 'figma/figma_scale.dart';

class QuizProgressHeader extends StatelessWidget {
  const QuizProgressHeader({
    super.key,
    required this.progress,
    required this.onBack,
  });

  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;

    return Padding(
      padding: EdgeInsets.fromLTRB(s(88), s(8), s(88), 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: FigmaSvg(
              FigmaAssets.quizBackChevron,
              width: s(29.79),
              height: s(49.68),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: s(FigmaQuizTokens.progressHeight),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: FigmaQuizTokens.progressTrack,
                      borderRadius: BorderRadius.circular(
                        s(FigmaQuizTokens.progressRadius),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: FigmaQuizTokens.progressFill,
                        borderRadius: BorderRadius.circular(
                          s(FigmaQuizTokens.progressRadius),
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: s(23), right: s(23)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: s(14),
                          decoration: BoxDecoration(
                            color: FigmaQuizTokens.progressHighlight.withValues(
                              alpha: 0.36,
                            ),
                            borderRadius: BorderRadius.circular(s(89)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// MC1 — 중앙 햄스터 + 하단 그림자 (객관식2 좌측 말풍선 레이아웃 아님).
class QuizMc1Hero extends StatelessWidget {
  const QuizMc1Hero({super.key});

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;

    return Padding(
      padding: EdgeInsets.only(top: s(FigmaQuizTokens.heroTop)),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(top: s(FigmaQuizTokens.heroHeight * 0.72)),
            child: FigmaSvg(
              FigmaAssets.quizHamsterShadow,
              width: s(FigmaQuizTokens.shadowWidth),
              height: s(FigmaQuizTokens.shadowHeight),
              fit: BoxFit.fill,
            ),
          ),
          Image.asset(
            FigmaAssets.hamsterAuth,
            width: s(FigmaQuizTokens.heroWidth * 0.72),
            height: s(FigmaQuizTokens.heroHeight * 0.72),
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class QuizCategoryBadge extends StatelessWidget {
  const QuizCategoryBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;

    return Padding(
      padding: EdgeInsets.only(top: s(FigmaQuizTokens.categoryTopGap)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: s(28), vertical: s(16)),
        decoration: BoxDecoration(
          color: AppTheme.figmaMintCard,
          borderRadius: BorderRadius.circular(
            s(FigmaQuizTokens.categoryHeight / 2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: s(FigmaQuizTokens.categoryFontSize),
            fontWeight: FontWeight.w600,
            color: AppTheme.figmaTeal,
          ),
        ),
      ),
    );
  }
}

class QuizOptionButton extends StatelessWidget {
  const QuizOptionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.isCorrectOption = false,
    this.showResult = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isCorrectOption;
  final bool showResult;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;
    final colors = _colors();

    return SizedBox(
      height: s(
        FigmaQuizTokens.optionHeight + FigmaQuizTokens.optionShadowOffset,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: s(FigmaQuizTokens.optionShadowOffset),
            child: Container(
              height: s(FigmaQuizTokens.optionHeight),
              decoration: BoxDecoration(
                color: colors.shadow,
                borderRadius: BorderRadius.circular(
                  s(FigmaQuizTokens.optionRadius),
                ),
                border: Border.all(color: colors.shadow, width: s(3)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Material(
              color: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  s(FigmaQuizTokens.optionRadius),
                ),
                side: BorderSide(
                  color: colors.border,
                  width: s(FigmaQuizTokens.optionBorderWidth),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  height: s(FigmaQuizTokens.optionHeight),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: s(24)),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FigmaQuizTokens.optionStyle(figma.scale),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color background, Color border, Color shadow}) _colors() {
    if (showResult && isCorrectOption) {
      return (
        background: FigmaQuizTokens.optionCorrectBg,
        border: AppTheme.success,
        shadow: AppTheme.success.withValues(alpha: 0.35),
      );
    }
    if (showResult && isSelected && !isCorrectOption) {
      return (
        background: FigmaQuizTokens.optionWrongBg,
        border: AppTheme.error,
        shadow: AppTheme.error.withValues(alpha: 0.35),
      );
    }
    if (!showResult && isSelected) {
      return (
        background: FigmaQuizTokens.optionSelectedBg,
        border: FigmaQuizTokens.optionSelectedBorder,
        shadow: FigmaQuizTokens.optionShadow,
      );
    }
    return (
      background: Colors.white,
      border: FigmaQuizTokens.optionBorder,
      shadow: FigmaQuizTokens.optionShadow,
    );
  }
}

class QuizResultBanner extends StatelessWidget {
  const QuizResultBanner({
    super.key,
    required this.isCorrect,
    required this.xpText,
  });

  final bool isCorrect;
  final String xpText;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: s(36), vertical: s(22)),
      decoration: BoxDecoration(
        color: isCorrect
            ? FigmaQuizTokens.optionCorrectBg
            : FigmaQuizTokens.optionWrongBg,
        borderRadius: BorderRadius.circular(s(24)),
      ),
      child: Text(
        xpText,
        style: TextStyle(
          fontSize: s(FigmaQuizTokens.resultFontSize),
          fontWeight: FontWeight.w800,
          color: isCorrect ? AppTheme.success : AppTheme.error,
        ),
      ),
    );
  }
}

class QuizSubmitButton extends StatelessWidget {
  const QuizSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: s(FigmaQuizTokens.submitButtonHeight),
        child: Material(
          color: FigmaQuizTokens.submitButton,
          borderRadius: BorderRadius.circular(
            s(FigmaQuizTokens.submitButtonRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Center(
              child: Text(
                label,
                style: FigmaQuizTokens.footerButtonStyle(figma.scale),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizFooterPrimaryButton extends StatelessWidget {
  const QuizFooterPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;
    final height = s(FigmaQuizTokens.footerButtonHeight);
    final offset = s(16);

    final canTap = enabled && onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        height: height + offset,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: offset,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: FigmaQuizTokens.footerButtonBottom,
                  borderRadius: BorderRadius.circular(
                    s(FigmaQuizTokens.footerButtonRadius),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Material(
                color: FigmaQuizTokens.footerButtonTop,
                borderRadius: BorderRadius.circular(
                  s(FigmaQuizTokens.footerButtonRadius),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: canTap ? onPressed : null,
                  child: SizedBox(
                    height: height,
                    child: Center(
                      child: Text(
                        label,
                        style: FigmaQuizTokens.footerButtonStyle(figma.scale),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// OX 가로 — 햄스터 전용 영역과 문제 카드 영역을 분리.
class QuizOxHeroZone extends StatelessWidget {
  const QuizOxHeroZone({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final zoneW = constraints.maxWidth;
        final zoneH = constraints.maxHeight;
        final hamsterW = zoneW * FigmaQuizTokens.oxHamsterWidthRatio;
        final hamsterH =
            hamsterW * (FigmaQuizTokens.heroHeight / FigmaQuizTokens.heroWidth);
        final scale = (zoneH / hamsterH).clamp(0.0, 1.0);
        final displayW = hamsterW * scale;
        final displayH = hamsterH * scale;
        final ellipseSize = (displayW * 1.15).clamp(0.0, zoneW);

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              bottom: displayH * 0.02,
              child: FigmaSvg(
                FigmaAssets.quizBgEllipse,
                width: ellipseSize,
                height: ellipseSize,
                fit: BoxFit.contain,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                FigmaAssets.hamsterAuth,
                width: displayW,
                height: displayH,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }
}

class QuizOxHorizontalLayout extends StatelessWidget {
  const QuizOxHorizontalLayout({
    super.key,
    required this.question,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.showResult,
    required this.onSelect,
  });

  final String question;
  final List<String> options;
  final int? selectedIndex;
  final int correctIndex;
  final bool showResult;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 420;
        final heroFlex = compact ? 24 : FigmaQuizTokens.oxHeroFlex;
        final cardFlex = compact ? 76 : FigmaQuizTokens.oxCardFlex;

        return Column(
          children: [
            Expanded(flex: heroFlex, child: const QuizOxHeroZone()),
            SizedBox(height: compact ? 0 : s(FigmaQuizTokens.oxHeroCardGap)),
            Expanded(
              flex: cardFlex,
              child: QuizOxQuestionCard(
                question: question,
                options: options,
                selectedIndex: selectedIndex,
                correctIndex: correctIndex,
                showResult: showResult,
                onSelect: onSelect,
              ),
            ),
          ],
        );
      },
    );
  }
}

class QuizOxQuestionCard extends StatelessWidget {
  const QuizOxQuestionCard({
    super.key,
    required this.question,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.showResult,
    required this.onSelect,
  });

  final String question;
  final List<String> options;
  final int? selectedIndex;
  final int correctIndex;
  final bool showResult;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;
    final radius = s(FigmaQuizTokens.oxCardRadius);
    final shadowOffset = s(FigmaQuizTokens.oxCardShadowOffset);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxQuestionHeight =
            (constraints.maxHeight * FigmaQuizTokens.oxQuestionAreaMaxFraction)
                .clamp(0.0, s(FigmaQuizTokens.oxQuestionAreaHeight));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: s(4),
              right: s(4),
              top: shadowOffset,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FigmaQuizTokens.oxCardShadowColor,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: FigmaQuizTokens.oxCardBorder,
                    width: s(2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxQuestionHeight,
                          minHeight: s(88),
                        ),
                        child: ColoredBox(
                          color: AppTheme.figmaMintCard,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: s(36),
                              vertical: s(20),
                            ),
                            child: Center(
                              child: Text(
                                question,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    FigmaQuizTokens.questionStyle(
                                      figma.scale,
                                    ).copyWith(
                                      fontSize: s(
                                        FigmaQuizTokens.oxQuestionFontSize,
                                      ),
                                      height: 1.28,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(
                            s(FigmaQuizTokens.oxCardInnerPadding),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < options.length; i++) ...[
                                if (i > 0)
                                  SizedBox(
                                    width: s(FigmaQuizTokens.oxChoiceGap),
                                  ),
                                Expanded(
                                  child: QuizOxChoiceButton(
                                    label: options[i],
                                    isSelected: selectedIndex == i,
                                    isCorrectOption: correctIndex == i,
                                    showResult: showResult,
                                    onTap: showResult
                                        ? null
                                        : () => onSelect(i),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class QuizOxChoiceButton extends StatelessWidget {
  const QuizOxChoiceButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.isCorrectOption = false,
    this.showResult = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isCorrectOption;
  final bool showResult;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;
    final colors = _colors();
    final radius = s(FigmaQuizTokens.oxChoiceRadius);

    return Material(
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: colors.border, width: s(3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(s(12)),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: s(FigmaQuizTokens.oxChoiceFontSize),
                  fontWeight: FontWeight.w900,
                  color: colors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ({Color background, Color border, Color text}) _colors() {
    if (showResult && isCorrectOption) {
      return (
        background: FigmaQuizTokens.oxCorrectFill,
        border: FigmaQuizTokens.oxCorrectFill,
        text: AppTheme.textPrimary,
      );
    }
    if (showResult && isSelected && !isCorrectOption) {
      return (
        background: FigmaQuizTokens.oxWrongFill,
        border: FigmaQuizTokens.oxWrongFill,
        text: AppTheme.textPrimary,
      );
    }
    if (!showResult && isSelected) {
      return (
        background: FigmaQuizTokens.oxSelectedFill,
        border: FigmaQuizTokens.optionSelectedBorder,
        text: AppTheme.textPrimary,
      );
    }
    return (
      background: FigmaQuizTokens.oxDefaultFill,
      border: FigmaQuizTokens.optionBorder,
      text: AppTheme.textPrimary,
    );
  }
}

class QuizFooterOutlinedButton extends StatelessWidget {
  const QuizFooterOutlinedButton({
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
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;

    return SizedBox(
      height: s(FigmaQuizTokens.footerButtonHeight),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            s(FigmaQuizTokens.footerButtonRadius),
          ),
          side: BorderSide(color: AppTheme.figmaTeal, width: s(3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: FigmaQuizTokens.footerButtonStyle(
                figma.scale,
              ).copyWith(color: AppTheme.figmaTeal),
            ),
          ),
        ),
      ),
    );
  }
}

/// 393×852 프레임 퀴즈 화면 하단 CTA. 퀴즈_중간 학습창(`293:1662`)과
/// 퀴즈_결과보기창(`131:3552`)이 좌표·색·서체까지 같은 버튼을 쓴다.
class QuizFigmaCtaButton extends StatelessWidget {
  const QuizFigmaCtaButton({
    super.key,
    required this.figma,
    required this.label,
    required this.onTap,
  });

  static const color = Color(0xFF3CC6FF);
  static const horizontalMargin = 24.0;
  static const bottomMargin = 54.0;
  static const height = 50.0;
  static const radius = 13.0;
  static const fontSize = 18.0;

  final FigmaScale figma;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(figma.s(radius));
    return Positioned(
      left: figma.s(horizontalMargin),
      right: figma.s(horizontalMargin),
      bottom: figma.s(bottomMargin),
      height: figma.s(height),
      child: Material(
        color: color,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: figma.s(fontSize),
                height: 1.203,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
