import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../models/quiz_question.dart';
import '../../theme/app_theme.dart';
import 'figma_asset_image.dart';
import 'figma_canvas.dart';
import 'figma_scale.dart';

/// Figma node `1:242` / `1:376` / `1:435` — 1화면용 Y는 중간 여백만 압축.
abstract final class QuizFigmaLayout {
  static const progressLeft = 250.0;
  static const progressTop = 166.0;
  static const progressWidth = 785.454;
  static const progressHeight = 52.0;

  static const backLeft = 116.0;
  static const backTop = 172.0;
  static const backTapSize = 80.0;

  static const bgEllipseLeft = 214.0;
  static const bgEllipseTop = 520.0;
  static const bgEllipseSize = 720.0;

  static const categoryLeft = 105.0;
  static const categoryTop = 280.0;
  static const categoryWidth = 320.0;
  static const categoryHeight = 72.0;

  /// Figma hero 대비 축소 (햄스터·그림자·배경 원). [heroScaleFor]로 화면별 추가 조정.
  static const heroScale = 0.72;
  static const hamsterTop = 300.0;
  static const hamsterWidth = 438.0 * heroScale;
  static const hamsterHeight = 596.0 * heroScale;
  static const hamsterCenterOffsetX = 13.66;

  static const shadowLeft = 429.0;
  static const shadowTop = 680.0;
  static const shadowWidth = 414.0 * heroScale;
  static const shadowHeight = 137.0 * heroScale;

  static const mcQuestionLeft = 105.0;
  static const mcQuestionTop = 790.0;
  static const mcQuestionWidth = 1003.0;
  static const mcQuestionFontSize = 42.0;

  static const optionLeft = 105.0;
  static const optionWidth = 1003.0;
  static const optionHeight = 132.0;
  static const optionRadius = 66.0;

  /// hero·질문 축소분 반영, 보기 간격 128px.
  static const optionTops = [960.0, 1088.0, 1216.0, 1344.0];

  static const oxCardLeft = 106.0;
  static const oxCardTop = 860.0;
  static const oxCardWidth = 999.0;
  static const oxCardHeight = 965.0;
  static const oxQuestionAreaHeight = 397.0;
  static const oxQuestionLeft = 150.0;
  static const oxQuestionTop = 933.0;
  static const oxQuestionWidth = 910.0;
  static const oxQuestionFontSize = 42.0;
  static const oxButtonLefts = [187.0, 619.0];
  static const oxButtonTop = 1325.0;
  static const oxButtonWidth = 403.0;
  static const oxButtonHeight = 420.0;
  static const oxVerticalButtonTops = [960.0, 1088.0];

  static const footerTop = 1600.0;
  static const footerHeight = 472.0;
  static const buttonLeft = 158.9;
  static const buttonTop = 1774.0;
  static const buttonWidth = 876.0;
  static const buttonHeight = 141.0;
  static const buttonTextLeft = 522.0;
  static const buttonTextTop = 2375.0;
  static const buttonTextSize = 45.0;

  static const dualButtonLeft = 105.0;
  static const dualButtonWidth = 490.0;
  static const dualButtonGap = 24.0;

  static const resultTop = 1495.0;
  static const resultHeight = 90.0;
  static const explanationLeft = 850.0;
  static const explanationTop = 1885.0;

  /// footer 하단 = 퀴즈 캔버스 designHeight ([FigmaScale.quizContentHeight]와 동기화).
  static const contentHeight = footerTop + footerHeight;
}

List<Widget> buildQuizFigmaLayers({
  required FigmaScale figma,
  required QuizQuestion question,
  required int currentIndex,
  required int totalQuestions,
  required int? selectedIndex,
  required bool showResult,
  required bool isCorrect,
  required VoidCallback onBack,
  required ValueChanged<int> onSelectOption,
  required VoidCallback onPrimaryAction,
  required VoidCallback onNextQuestion,
  required VoidCallback onShowExplanation,
}) {
  final s = figma.s;
  final progressFill =
      QuizFigmaLayout.progressWidth * (currentIndex + 1) / totalQuestions;
  final isOx = question.type == QuizType.ox;
  final useVerticalOx = isOx && currentIndex.isOdd;

  return [
    FigmaBox(
      figma: figma,
      left: QuizFigmaLayout.bgEllipseLeft,
      top: QuizFigmaLayout.bgEllipseTop,
      width: QuizFigmaLayout.bgEllipseSize,
      height: QuizFigmaLayout.bgEllipseSize,
      child: const FigmaSvg(FigmaAssets.quizBgEllipse, fit: BoxFit.fill),
    ),

    FigmaPill(
      figma: figma,
      left: QuizFigmaLayout.progressLeft,
      top: QuizFigmaLayout.progressTop,
      width: QuizFigmaLayout.progressWidth,
      height: QuizFigmaLayout.progressHeight,
      color: const Color(0xFFE8F8F7),
      radius: QuizFigmaLayout.progressHeight / 2,
    ),
    FigmaPill(
      figma: figma,
      left: QuizFigmaLayout.progressLeft,
      top: QuizFigmaLayout.progressTop,
      width: progressFill,
      height: QuizFigmaLayout.progressHeight,
      color: const Color(0xFF55DBD0),
      radius: QuizFigmaLayout.progressHeight / 2,
    ),

    FigmaTapArea(
      figma: figma,
      left: QuizFigmaLayout.backLeft,
      top: QuizFigmaLayout.backTop,
      width: QuizFigmaLayout.backTapSize,
      height: QuizFigmaLayout.backTapSize,
      onTap: onBack,
      child: FigmaSvg(
        FigmaAssets.quizBackChevron,
        width: s(29.79),
        height: s(49.68),
      ),
    ),

    FigmaPill(
      figma: figma,
      left: QuizFigmaLayout.categoryLeft,
      top: QuizFigmaLayout.categoryTop,
      width: QuizFigmaLayout.categoryWidth,
      height: QuizFigmaLayout.categoryHeight,
      color: AppTheme.figmaMintCard,
      radius: QuizFigmaLayout.categoryHeight / 2,
    ),
    FigmaLabel(
      figma: figma,
      left: QuizFigmaLayout.categoryLeft + 28,
      top: QuizFigmaLayout.categoryTop + 16,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: AppTheme.figmaTeal,
      text: question.category.label,
    ),

    if (!isOx || useVerticalOx) ...[
      // Figma: 그림자(81:350) → 햄스터(87:25) 순. Stack에서는 먼저 그릴수록 뒤.
      FigmaBox(
        figma: figma,
        left: QuizFigmaLayout.shadowLeft,
        top: QuizFigmaLayout.shadowTop,
        width: QuizFigmaLayout.shadowWidth,
        height: QuizFigmaLayout.shadowHeight,
        child: const FigmaSvg(FigmaAssets.quizHamsterShadow, fit: BoxFit.fill),
      ),
      FigmaCenterBox(
        figma: figma,
        designWidth: FigmaScale.quizDesignWidth,
        top: QuizFigmaLayout.hamsterTop,
        width: QuizFigmaLayout.hamsterWidth,
        height: QuizFigmaLayout.hamsterHeight,
        centerOffsetX: QuizFigmaLayout.hamsterCenterOffsetX,
        child: const FigmaPng(
          FigmaAssets.hamsterAuth,
          fit: BoxFit.contain,
          clip: true,
        ),
      ),
    ],

    if (isOx && !useVerticalOx) ..._buildOxCardLayers(figma, question),
    if (!isOx) ..._buildMcQuestionLayer(figma, question),
    if (isOx && useVerticalOx)
      ..._buildOxVerticalQuestionLayer(figma, question),

    ..._buildOptionLayers(
      figma: figma,
      question: question,
      selectedIndex: selectedIndex,
      showResult: showResult,
      useVerticalOx: useVerticalOx,
      onSelectOption: onSelectOption,
    ),

    if (showResult) ...[
      FigmaPill(
        figma: figma,
        left: QuizFigmaLayout.optionLeft,
        top: QuizFigmaLayout.resultTop,
        width: QuizFigmaLayout.optionWidth,
        height: QuizFigmaLayout.resultHeight,
        color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        radius: 24,
      ),
      FigmaLabel(
        figma: figma,
        left: QuizFigmaLayout.optionLeft + 36,
        top: QuizFigmaLayout.resultTop + 22,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: isCorrect ? AppTheme.success : AppTheme.error,
        text: isCorrect ? '정답!' : '오답이에요',
      ),
    ],

    ..._buildQuizFooter(
      figma: figma,
      showResult: showResult,
      selectedIndex: selectedIndex,
      isLast: currentIndex >= totalQuestions - 1,
      onSubmit: onPrimaryAction,
      onShowExplanation: onShowExplanation,
      onNext: onNextQuestion,
    ),
  ];
}

List<Widget> _buildQuizFooter({
  required FigmaScale figma,
  required bool showResult,
  required int? selectedIndex,
  required bool isLast,
  required VoidCallback onSubmit,
  required VoidCallback onShowExplanation,
  required VoidCallback onNext,
}) {
  return [
    FigmaBox(
      figma: figma,
      left: 0,
      top: QuizFigmaLayout.footerTop,
      width: FigmaScale.quizDesignWidth,
      height: QuizFigmaLayout.footerHeight,
      child: const ColoredBox(color: AppTheme.figmaMintLight),
    ),
    if (!showResult) ...[
      ..._buildQuizActionButton(
        figma: figma,
        left: QuizFigmaLayout.buttonLeft,
        width: QuizFigmaLayout.buttonWidth,
        label: '정답 제출',
        onTap: selectedIndex != null ? onSubmit : null,
        enabled: selectedIndex != null,
      ),
    ] else ...[
      ..._buildQuizActionButton(
        figma: figma,
        left: QuizFigmaLayout.dualButtonLeft,
        width: QuizFigmaLayout.dualButtonWidth,
        label: '풀이확인',
        onTap: onShowExplanation,
        outlined: true,
      ),
      ..._buildQuizActionButton(
        figma: figma,
        left:
            QuizFigmaLayout.dualButtonLeft +
            QuizFigmaLayout.dualButtonWidth +
            QuizFigmaLayout.dualButtonGap,
        width: QuizFigmaLayout.dualButtonWidth,
        label: isLast ? '결과 보기' : '다음문제',
        onTap: onNext,
      ),
    ],
  ];
}

List<Widget> _buildQuizActionButton({
  required FigmaScale figma,
  required double left,
  required double width,
  required String label,
  required VoidCallback? onTap,
  bool enabled = true,
  bool outlined = false,
}) {
  final s = figma.s;
  final canTap = onTap != null && enabled;

  return [
    if (!outlined)
      FigmaPill(
        figma: figma,
        left: left,
        top: QuizFigmaLayout.buttonTop,
        width: width,
        height: QuizFigmaLayout.buttonHeight,
        color: const Color(0xFF9CE5FF),
        radius: 46.285,
      ),
    FigmaTapArea(
      figma: figma,
      left: left,
      top: QuizFigmaLayout.buttonTop,
      width: width,
      height: QuizFigmaLayout.buttonHeight,
      onTap: canTap ? onTap : null,
      child: Opacity(
        opacity: canTap ? 1 : 0.45,
        child: DecoratedBox(
          decoration: outlined
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(s(46.285)),
                  border: Border.all(color: AppTheme.figmaTeal, width: s(3)),
                )
              : const BoxDecoration(),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: s(QuizFigmaLayout.buttonTextSize),
                fontWeight: FontWeight.w700,
                color: outlined ? AppTheme.figmaTeal : Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  ];
}

List<Widget> _buildMcQuestionLayer(FigmaScale figma, QuizQuestion question) {
  return [
    FigmaBox(
      figma: figma,
      left: QuizFigmaLayout.mcQuestionLeft,
      top: QuizFigmaLayout.mcQuestionTop,
      width: QuizFigmaLayout.mcQuestionWidth,
      child: Text(
        question.question,
        style: TextStyle(
          fontSize: figma.s(QuizFigmaLayout.mcQuestionFontSize),
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          height: 1.35,
        ),
      ),
    ),
  ];
}

List<Widget> _buildOxCardLayers(FigmaScale figma, QuizQuestion question) {
  return [
    FigmaPill(
      figma: figma,
      left: QuizFigmaLayout.oxCardLeft + 4,
      top: QuizFigmaLayout.oxCardTop + 8,
      width: QuizFigmaLayout.oxCardWidth,
      height: QuizFigmaLayout.oxCardHeight,
      color: const Color(0xFFABC8D3),
      radius: 95,
    ),
    FigmaPill(
      figma: figma,
      left: QuizFigmaLayout.oxCardLeft,
      top: QuizFigmaLayout.oxCardTop,
      width: QuizFigmaLayout.oxCardWidth,
      height: QuizFigmaLayout.oxCardHeight,
      color: Colors.white,
      radius: 95,
    ),
    FigmaBox(
      figma: figma,
      left: QuizFigmaLayout.oxCardLeft,
      top: QuizFigmaLayout.oxCardTop,
      width: QuizFigmaLayout.oxCardWidth,
      height: QuizFigmaLayout.oxQuestionAreaHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.figmaMintCard,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(figma.s(95)),
          ),
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: QuizFigmaLayout.oxQuestionLeft,
      top: QuizFigmaLayout.oxQuestionTop,
      width: QuizFigmaLayout.oxQuestionWidth,
      child: Text(
        question.question,
        style: TextStyle(
          fontSize: figma.s(QuizFigmaLayout.oxQuestionFontSize),
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          height: 1.35,
        ),
      ),
    ),
  ];
}

List<Widget> _buildOxVerticalQuestionLayer(
  FigmaScale figma,
  QuizQuestion question,
) {
  return [
    FigmaBox(
      figma: figma,
      left: QuizFigmaLayout.mcQuestionLeft,
      top: QuizFigmaLayout.mcQuestionTop,
      width: QuizFigmaLayout.mcQuestionWidth,
      child: Text(
        question.question,
        style: TextStyle(
          fontSize: figma.s(QuizFigmaLayout.mcQuestionFontSize),
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          height: 1.35,
        ),
      ),
    ),
  ];
}

List<Widget> _buildOptionLayers({
  required FigmaScale figma,
  required QuizQuestion question,
  required int? selectedIndex,
  required bool showResult,
  required bool useVerticalOx,
  required ValueChanged<int> onSelectOption,
}) {
  final isOx = question.type == QuizType.ox;

  if (isOx && !useVerticalOx) {
    return [
      for (var i = 0; i < 2; i++)
        _buildOptionPill(
          figma: figma,
          left: QuizFigmaLayout.oxButtonLefts[i],
          top: QuizFigmaLayout.oxButtonTop,
          width: QuizFigmaLayout.oxButtonWidth,
          height: QuizFigmaLayout.oxButtonHeight,
          radius: 80,
          text: question.options[i],
          isOx: true,
          isSelected: selectedIndex == i,
          isCorrectOption: question.correctIndex == i,
          showResult: showResult,
          onTap: showResult ? null : () => onSelectOption(i),
        ),
    ];
  }

  if (isOx && useVerticalOx) {
    return [
      for (var i = 0; i < 2; i++)
        _buildOptionPill(
          figma: figma,
          left: QuizFigmaLayout.optionLeft,
          top: QuizFigmaLayout.oxVerticalButtonTops[i],
          width: QuizFigmaLayout.optionWidth,
          height: QuizFigmaLayout.optionHeight,
          radius: QuizFigmaLayout.optionRadius,
          text: question.options[i],
          isOx: true,
          isSelected: selectedIndex == i,
          isCorrectOption: question.correctIndex == i,
          showResult: showResult,
          onTap: showResult ? null : () => onSelectOption(i),
        ),
    ];
  }

  return [
    for (var i = 0; i < question.options.length; i++)
      _buildOptionPill(
        figma: figma,
        left: QuizFigmaLayout.optionLeft,
        top: QuizFigmaLayout.optionTops[i],
        width: QuizFigmaLayout.optionWidth,
        height: QuizFigmaLayout.optionHeight,
        radius: QuizFigmaLayout.optionRadius,
        text: question.options[i],
        isOx: false,
        isSelected: selectedIndex == i,
        isCorrectOption: question.correctIndex == i,
        showResult: showResult,
        onTap: showResult ? null : () => onSelectOption(i),
      ),
  ];
}

Widget _buildOptionPill({
  required FigmaScale figma,
  required double left,
  required double top,
  required double width,
  required double height,
  required double radius,
  required String text,
  required bool isOx,
  required bool isSelected,
  required bool isCorrectOption,
  required bool showResult,
  required VoidCallback? onTap,
}) {
  final colors = _optionColors(
    isSelected: isSelected,
    isCorrectOption: isCorrectOption,
    showResult: showResult,
  );

  return FigmaTapArea(
    figma: figma,
    left: left,
    top: top,
    width: width,
    height: height,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(figma.s(radius)),
        border: Border.all(color: colors.border, width: figma.s(3)),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: figma.s(24)),
          child: isOx
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: figma.s(120),
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: figma.s(36),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
        ),
      ),
    ),
  );
}

({Color background, Color border}) _optionColors({
  required bool isSelected,
  required bool isCorrectOption,
  required bool showResult,
}) {
  if (showResult && isCorrectOption) {
    return (background: const Color(0xFFDCFCE7), border: AppTheme.success);
  }
  if (showResult && isSelected && !isCorrectOption) {
    return (background: const Color(0xFFFEE2E2), border: AppTheme.error);
  }
  if (!showResult && isSelected) {
    return (
      background: const Color(0xFFE6F8FF),
      border: const Color(0xFF9CE5FF),
    );
  }
  return (background: Colors.white, border: const Color(0xFFD9D9D9));
}
