import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../theme/figma_quiz_fonts.dart';
import '../../theme/figma_quiz_ox_tokens.dart';
import 'figma_asset_image.dart';
import 'figma_canvas.dart';
import 'figma_scale.dart';
import 'quiz_question_layout.dart';

/// Figma `137:5890` 문제 / `137:5957` 정답 / `291:971` 해설.
class FigmaQuizOxView extends StatelessWidget {
  const FigmaQuizOxView({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
    required this.options,
    required this.selectedIndex,
    required this.submitting,
    required this.locked,
    required this.onBack,
    required this.onSelect,
    required this.onNext,
    this.showAnswer = false,
    this.showExplanation = false,
    this.correctIndex,
    this.explanation = '',
    this.onQuestionTap,
    this.onExplanationTap,
  });

  final int questionNumber;
  final int totalQuestions;
  final String question;
  final List<String> options;
  final int? selectedIndex;
  final bool submitting;
  final bool locked;
  final VoidCallback onBack;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;
  final bool showAnswer;
  final bool showExplanation;
  final int? correctIndex;
  final String explanation;
  final VoidCallback? onQuestionTap;
  final VoidCallback? onExplanationTap;

  @override
  Widget build(BuildContext context) {
    final questionHeight = QuizQuestionLayout.textHeight(
      text: question,
      width: FigmaQuizOxTokens.questionWidth,
      fontSize: FigmaQuizOxTokens.questionFontSize,
      lineHeight: FigmaQuizOxTokens.questionLineHeight,
      minimumHeight: FigmaQuizOxTokens.questionHeight,
      fontFamily: FigmaQuizFonts.pretendard,
      textScaler: MediaQuery.textScalerOf(context),
    );
    final contentShift = questionHeight - FigmaQuizOxTokens.questionHeight;

    return Scaffold(
      backgroundColor: FigmaQuizOxTokens.background,
      body: FigmaCanvas(
        designWidth: FigmaScale.quizDesignWidth,
        designHeight: FigmaScale.quizDesignHeight + contentShift,
        backgroundColor: FigmaQuizOxTokens.background,
        fit: FigmaCanvasFit.widthScroll,
        scrollable: true,
        builder: (context, figma) => _layers(
          figma,
          questionHeight: questionHeight,
          contentShift: contentShift,
        ),
      ),
    );
  }

  List<Widget> _layers(
    FigmaScale figma, {
    required double questionHeight,
    required double contentShift,
  }) {
    final progress = questionNumber / totalQuestions.clamp(1, 999);
    final fillWidth =
        FigmaQuizOxTokens.progressWidth * progress.clamp(0.0, 1.0);
    final highlightWidth =
        (fillWidth -
                FigmaQuizOxTokens.progressHighlightLeftInset -
                FigmaQuizOxTokens.progressHighlightRightInset)
            .clamp(0.0, fillWidth);
    final canNext = selectedIndex != null && !submitting;

    return [
      FigmaTapArea(
        figma: figma,
        left: FigmaQuizOxTokens.backTapLeft,
        top: FigmaQuizOxTokens.backTapTop,
        width: FigmaQuizOxTokens.backTapSize,
        height: FigmaQuizOxTokens.backTapSize,
        onTap: onBack,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: figma.s(
                FigmaQuizOxTokens.backLeft - FigmaQuizOxTokens.backTapLeft,
              ),
            ),
            child: FigmaSvg(
              FigmaAssets.quizOxBackChevron,
              width: figma.s(FigmaQuizOxTokens.backWidth),
              height: figma.s(FigmaQuizOxTokens.backHeight),
            ),
          ),
        ),
      ),
      FigmaPill(
        figma: figma,
        left: FigmaQuizOxTokens.progressLeft,
        top: FigmaQuizOxTokens.progressTop,
        width: FigmaQuizOxTokens.progressWidth,
        height: FigmaQuizOxTokens.progressHeight,
        color: FigmaQuizOxTokens.progressTrack,
        radius: FigmaQuizOxTokens.progressRadius,
      ),
      if (fillWidth > 0)
        FigmaPill(
          figma: figma,
          left: FigmaQuizOxTokens.progressLeft,
          top: FigmaQuizOxTokens.progressTop,
          width: fillWidth,
          height: FigmaQuizOxTokens.progressHeight,
          color: FigmaQuizOxTokens.progressFill,
          radius: FigmaQuizOxTokens.progressRadius,
        ),
      if (highlightWidth > 0)
        FigmaPill(
          figma: figma,
          left: FigmaQuizOxTokens.progressHighlightLeft,
          top: FigmaQuizOxTokens.progressHighlightTop,
          width: highlightWidth,
          height: FigmaQuizOxTokens.progressHighlightHeight,
          color: FigmaQuizOxTokens.progressHighlight.withValues(
            alpha: FigmaQuizOxTokens.progressHighlightOpacity,
          ),
        ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.characterShadowLeft,
        top: FigmaQuizOxTokens.characterShadowTop,
        width: FigmaQuizOxTokens.characterShadowWidth,
        height: FigmaQuizOxTokens.characterShadowHeight,
        child: FigmaSvg(
          FigmaAssets.quizOxCharacterShadow,
          width: figma.s(FigmaQuizOxTokens.characterShadowWidth),
          height: figma.s(FigmaQuizOxTokens.characterShadowHeight),
          fit: BoxFit.fill,
        ),
      ),
      FigmaBox(
        figma: figma,
        left: showExplanation
            ? FigmaQuizOxTokens.explainCharacterLeft
            : FigmaQuizOxTokens.characterLeft,
        top: showExplanation
            ? FigmaQuizOxTokens.explainCharacterTop
            : FigmaQuizOxTokens.characterTop,
        width: showExplanation
            ? FigmaQuizOxTokens.explainCharacterWidth
            : FigmaQuizOxTokens.characterWidth,
        height: showExplanation
            ? FigmaQuizOxTokens.explainCharacterHeight
            : FigmaQuizOxTokens.characterHeight,
        child: FigmaSvg(
          showExplanation
              ? FigmaAssets.quizOxCharacterExplain
              : FigmaAssets.quizOxCharacter,
          width: figma.s(
            showExplanation
                ? FigmaQuizOxTokens.explainCharacterWidth
                : FigmaQuizOxTokens.characterWidth,
          ),
          height: figma.s(
            showExplanation
                ? FigmaQuizOxTokens.explainCharacterHeight
                : FigmaQuizOxTokens.characterHeight,
          ),
          fit: BoxFit.fill,
        ),
      ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.qIconLeft,
        top: FigmaQuizOxTokens.qIconTop,
        width: FigmaQuizOxTokens.qIconWidth,
        height: FigmaQuizOxTokens.qIconHeight,
        child: FigmaSvg(
          showExplanation
              ? FigmaAssets.quizQuestionIconExplain
              : FigmaAssets.quizQuestionIcon,
          width: figma.s(FigmaQuizOxTokens.qIconWidth),
          height: figma.s(FigmaQuizOxTokens.qIconHeight),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.numberLeft,
        top: FigmaQuizOxTokens.numberTop,
        width: FigmaQuizOxTokens.numberWidth,
        height: FigmaQuizOxTokens.numberHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: _numberText(figma),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.cardLeft,
        top: FigmaQuizOxTokens.cardTop,
        width: FigmaQuizOxTokens.cardWidth,
        height: FigmaQuizOxTokens.cardHeight + contentShift,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              figma.s(FigmaQuizOxTokens.cardRadius),
            ),
            border: Border.all(
              color: showExplanation
                  ? FigmaQuizOxTokens.explainCardBorder
                  : FigmaQuizOxTokens.cardBorder,
              width: figma.s(FigmaQuizOxTokens.cardBorderWidth),
            ),
          ),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.cardLeft,
        top: FigmaQuizOxTokens.cardTop,
        width: FigmaQuizOxTokens.cardWidth,
        height: FigmaQuizOxTokens.headerHeight + contentShift,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: showExplanation
                ? FigmaQuizOxTokens.explainHeaderFill
                : FigmaQuizOxTokens.headerFill,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(figma.s(FigmaQuizOxTokens.cardRadius)),
            ),
          ),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.questionLeft,
        top: FigmaQuizOxTokens.questionTop,
        width: FigmaQuizOxTokens.questionWidth,
        height: questionHeight,
        child: Center(
          child: Text(
            question,
            textAlign: TextAlign.center,
            style: QuizQuestionLayout.textStyle(
              fontFamily: FigmaQuizFonts.pretendard,
              fontSize: figma.s(FigmaQuizOxTokens.questionFontSize),
              lineHeight: FigmaQuizOxTokens.questionLineHeight,
            ),
          ),
        ),
      ),
      if (showAnswer) ..._answerToggle(figma, contentShift),
      if (showExplanation) ..._explanationText(figma, contentShift),
      if (!showExplanation)
        for (var i = 0; i < FigmaQuizOxTokens.optionLefts.length; i++) ...[
          FigmaTapArea(
            figma: figma,
            left: FigmaQuizOxTokens.optionLefts[i],
            top: FigmaQuizOxTokens.optionTop + contentShift,
            width: FigmaQuizOxTokens.optionWidth,
            height: FigmaQuizOxTokens.optionHeight,
            onTap: locked || i >= options.length ? null : () => onSelect(i),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _optionFill(i),
                borderRadius: BorderRadius.circular(
                  figma.s(FigmaQuizOxTokens.optionRadius),
                ),
                border: Border.all(
                  color: _optionBorder(i),
                  width: figma.s(_optionBorderWidth(i)),
                ),
              ),
            ),
          ),
          FigmaBox(
            figma: figma,
            left: FigmaQuizOxTokens.markLefts[i],
            top: FigmaQuizOxTokens.markTops[i] + contentShift,
            width: FigmaQuizOxTokens.markSizes[i],
            height: FigmaQuizOxTokens.markSizes[i],
            // 마크는 선택 박스 위에 그려지므로 탭을 통과시킨다.
            child: IgnorePointer(
              child: FigmaSvg(
                _markAsset(i),
                width: figma.s(FigmaQuizOxTokens.markSizes[i]),
                height: figma.s(FigmaQuizOxTokens.markSizes[i]),
                colorFilter: ColorFilter.mode(_markColor(i), BlendMode.srcIn),
              ),
            ),
          ),
        ],
      FigmaTapArea(
        figma: figma,
        left: FigmaQuizOxTokens.ctaLeft,
        top: FigmaQuizOxTokens.ctaTop + contentShift,
        width: FigmaQuizOxTokens.ctaWidth,
        height: FigmaQuizOxTokens.ctaHeight,
        onTap: canNext ? onNext : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FigmaQuizOxTokens.cta.withValues(alpha: canNext ? 1 : 0.4),
            borderRadius: BorderRadius.circular(
              figma.s(FigmaQuizOxTokens.ctaRadius),
            ),
          ),
          child: Center(
            child: Text(
              submitting ? '제출 중…' : '다음으로',
              style: TextStyle(
                fontFamily: FigmaQuizFonts.pretendard,
                fontSize: figma.s(FigmaQuizOxTokens.ctaFontSize),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// 얇은 SUIT Thin 숫자에 디자인의 1.5px stroke를 덧입힌다.
  Widget _numberText(FigmaScale figma) {
    final base = TextStyle(
      fontFamily: FigmaQuizFonts.suit,
      fontSize: figma.s(FigmaQuizOxTokens.numberFontSize),
      fontWeight: FontWeight.w100,
      height: FigmaQuizOxTokens.numberLineHeight,
    );
    final label = '$questionNumber';
    final color = showExplanation
        ? FigmaQuizOxTokens.explainNumber
        : FigmaQuizOxTokens.number;

    return Stack(
      children: [
        Text(
          label,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = figma.s(FigmaQuizOxTokens.numberStrokeWidth)
              ..strokeJoin = StrokeJoin.round
              ..color = color,
          ),
        ),
        Text(label, style: base.copyWith(color: color)),
      ],
    );
  }

  List<Widget> _explanationText(FigmaScale figma, double contentShift) {
    return [
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.explainTextLeft,
        top: FigmaQuizOxTokens.explainTextTop + contentShift,
        width: FigmaQuizOxTokens.explainTextWidth,
        height: FigmaQuizOxTokens.explainTextHeight,
        child: SingleChildScrollView(
          child: Text(
            explanation.isEmpty ? question : explanation,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: FigmaQuizFonts.pretendard,
              fontSize: figma.s(FigmaQuizOxTokens.explainTextFontSize),
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.35,
            ),
          ),
        ),
      ),
    ];
  }

  /// 보기 라벨이 O/X면 라벨을 따르고, 아니면 디자인 순서(왼쪽 O, 오른쪽 X)를 쓴다.
  String _markAsset(int index) {
    final label = index < options.length
        ? options[index].trim().toUpperCase()
        : '';
    if (label == 'O') return FigmaAssets.quizOxMarkO;
    if (label == 'X') return FigmaAssets.quizOxMarkX;
    return index == 0 ? FigmaAssets.quizOxMarkO : FigmaAssets.quizOxMarkX;
  }

  Color _optionFill(int index) {
    if (!showAnswer || index >= options.length) return Colors.white;
    if (index == correctIndex) return FigmaQuizOxTokens.optionCorrectFill;
    if (index == selectedIndex) return FigmaQuizOxTokens.optionWrongFill;
    return Colors.white;
  }

  Color _optionBorder(int index) {
    if (index >= options.length) return FigmaQuizOxTokens.optionBorder;
    if (showAnswer) {
      if (index == correctIndex) return FigmaQuizOxTokens.optionCorrectBorder;
      if (index == selectedIndex) return FigmaQuizOxTokens.optionWrongBorder;
      return FigmaQuizOxTokens.optionBorder;
    }
    if (selectedIndex == index) return FigmaQuizOxTokens.optionSelectedBorder;
    return FigmaQuizOxTokens.optionBorder;
  }

  double _optionBorderWidth(int index) {
    if (showAnswer && (index == correctIndex || index == selectedIndex)) {
      return FigmaQuizOxTokens.optionAnswerBorderWidth;
    }
    return selectedIndex == index
        ? FigmaQuizOxTokens.optionSelectedBorderWidth
        : FigmaQuizOxTokens.optionBorderWidth;
  }

  List<Widget> _answerToggle(FigmaScale figma, double contentShift) {
    final explain = showExplanation;
    final questionColor = explain
        ? FigmaQuizOxTokens.toggleInactive
        : FigmaQuizOxTokens.toggleActive;
    final explainColor = explain
        ? FigmaQuizOxTokens.toggleExplainActive
        : FigmaQuizOxTokens.toggleInactive;

    return [
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.toggleLeft,
        top: FigmaQuizOxTokens.toggleTop + contentShift,
        width: FigmaQuizOxTokens.toggleWidth,
        height: FigmaQuizOxTokens.toggleHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FigmaQuizOxTokens.toggleFill,
            borderRadius: BorderRadius.circular(
              figma.s(FigmaQuizOxTokens.toggleRadius),
            ),
            border: Border.all(
              color: FigmaQuizOxTokens.toggleBorder,
              width: figma.s(FigmaQuizOxTokens.toggleBorderWidth),
            ),
          ),
        ),
      ),
      FigmaTapArea(
        figma: figma,
        left: FigmaQuizOxTokens.toggleQuestionLeft,
        top: FigmaQuizOxTokens.toggleQuestionTop + contentShift,
        width: FigmaQuizOxTokens.toggleQuestionWidth,
        height: FigmaQuizOxTokens.toggleLabelHeight,
        onTap: onQuestionTap,
        child: Text(
          '문제',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FigmaQuizFonts.pretendard,
            fontSize: figma.s(FigmaQuizOxTokens.toggleFontSize),
            fontWeight: FontWeight.w600,
            color: questionColor,
            height: 15 / 14,
          ),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizOxTokens.toggleDividerLeft,
        top: FigmaQuizOxTokens.toggleDividerTop + contentShift,
        width: FigmaQuizOxTokens.toggleDividerWidth,
        height: FigmaQuizOxTokens.toggleDividerHeight,
        child: ColoredBox(color: FigmaQuizOxTokens.toggleBorder),
      ),
      FigmaTapArea(
        figma: figma,
        left: FigmaQuizOxTokens.toggleExplainLeft,
        top: FigmaQuizOxTokens.toggleExplainTop + contentShift,
        width: FigmaQuizOxTokens.toggleExplainWidth,
        height: FigmaQuizOxTokens.toggleLabelHeight,
        onTap: onExplanationTap,
        child: Text(
          '해설',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FigmaQuizFonts.pretendard,
            fontSize: figma.s(FigmaQuizOxTokens.toggleFontSize),
            fontWeight: FontWeight.w600,
            color: explainColor,
            height: 15 / 14,
          ),
        ),
      ),
    ];
  }

  Color _markColor(int index) {
    if (index >= options.length) return FigmaQuizOxTokens.mark;
    if (showAnswer) {
      if (index == correctIndex) return FigmaQuizOxTokens.optionCorrectBorder;
      if (index == selectedIndex) return FigmaQuizOxTokens.optionWrongBorder;
      return FigmaQuizOxTokens.mark;
    }
    if (selectedIndex == index) return FigmaQuizOxTokens.optionSelectedBorder;
    return FigmaQuizOxTokens.mark;
  }
}
