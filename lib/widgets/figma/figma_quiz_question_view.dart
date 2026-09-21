import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../theme/figma_quiz_fonts.dart';
import '../../theme/figma_quiz_question_tokens.dart';
import 'figma_asset_image.dart';
import 'figma_canvas.dart';
import 'figma_scale.dart';
import 'quiz_question_layout.dart';

/// Figma `137:5521` 문제 / `137:5589` 정답 / `291:931` 해설 — 4지선다 전용.
///
/// OX 퀴즈는 [FigmaQuizOxView]가 담당한다.
class FigmaQuizQuestionView extends StatelessWidget {
  const FigmaQuizQuestionView({
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
    final questionHeight = showExplanation
        ? FigmaQuizQuestionTokens.questionHeight
        : QuizQuestionLayout.textHeight(
            text: question,
            width: FigmaQuizQuestionTokens.questionWidth,
            fontSize: FigmaQuizQuestionTokens.questionFontSize,
            lineHeight: FigmaQuizQuestionTokens.questionLineHeight,
            minimumHeight: FigmaQuizQuestionTokens.questionHeight,
            fontFamily: FigmaQuizFonts.pretendard,
            textScaler: MediaQuery.textScalerOf(context),
          );
    final contentShift =
        questionHeight - FigmaQuizQuestionTokens.questionHeight;

    return Scaffold(
      backgroundColor: FigmaQuizQuestionTokens.background,
      body: FigmaCanvas(
        designWidth: FigmaScale.quizDesignWidth,
        designHeight: FigmaScale.quizDesignHeight + contentShift,
        backgroundColor: FigmaQuizQuestionTokens.background,
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
        FigmaQuizQuestionTokens.progressWidth * progress.clamp(0.0, 1.0);
    final highlightWidth =
        (fillWidth -
                FigmaQuizQuestionTokens.progressHighlightLeftInset -
                FigmaQuizQuestionTokens.progressHighlightRightInset)
            .clamp(0.0, fillWidth);
    final canNext = selectedIndex != null && !submitting;

    return [
      FigmaTapArea(
        figma: figma,
        left: FigmaQuizQuestionTokens.backTapLeft,
        top: FigmaQuizQuestionTokens.backTapTop,
        width: FigmaQuizQuestionTokens.backTapSize,
        height: FigmaQuizQuestionTokens.backTapSize,
        onTap: onBack,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: figma.s(
                FigmaQuizQuestionTokens.backLeft -
                    FigmaQuizQuestionTokens.backTapLeft,
              ),
            ),
            child: FigmaSvg(
              FigmaAssets.quizBackChevronQuestion,
              width: figma.s(FigmaQuizQuestionTokens.backWidth),
              height: figma.s(FigmaQuizQuestionTokens.backHeight),
            ),
          ),
        ),
      ),
      FigmaPill(
        figma: figma,
        left: FigmaQuizQuestionTokens.progressLeft,
        top: FigmaQuizQuestionTokens.progressTop,
        width: FigmaQuizQuestionTokens.progressWidth,
        height: FigmaQuizQuestionTokens.progressHeight,
        color: FigmaQuizQuestionTokens.progressTrack,
        radius: FigmaQuizQuestionTokens.progressRadius,
      ),
      if (fillWidth > 0)
        FigmaPill(
          figma: figma,
          left: FigmaQuizQuestionTokens.progressLeft,
          top: FigmaQuizQuestionTokens.progressTop,
          width: fillWidth,
          height: FigmaQuizQuestionTokens.progressHeight,
          color: FigmaQuizQuestionTokens.progressFill,
          radius: FigmaQuizQuestionTokens.progressRadius,
        ),
      if (highlightWidth > 0)
        FigmaPill(
          figma: figma,
          left: FigmaQuizQuestionTokens.progressHighlightLeft,
          top: FigmaQuizQuestionTokens.progressHighlightTop,
          width: highlightWidth,
          height: FigmaQuizQuestionTokens.progressHighlightHeight,
          color: FigmaQuizQuestionTokens.progressHighlight.withValues(
            alpha: FigmaQuizQuestionTokens.progressHighlightOpacity,
          ),
        ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizQuestionTokens.qIconLeft,
        top: FigmaQuizQuestionTokens.qIconTop,
        width: FigmaQuizQuestionTokens.qIconWidth,
        height: FigmaQuizQuestionTokens.qIconHeight,
        child: FigmaSvg(
          showExplanation
              ? FigmaAssets.quizQuestionIconExplain
              : FigmaAssets.quizQuestionIcon,
          width: figma.s(FigmaQuizQuestionTokens.qIconWidth),
          height: figma.s(FigmaQuizQuestionTokens.qIconHeight),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizQuestionTokens.numberLeft,
        top: FigmaQuizQuestionTokens.numberTop,
        width: FigmaQuizQuestionTokens.numberWidth,
        height: FigmaQuizQuestionTokens.numberHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$questionNumber',
            style: TextStyle(
              fontFamily: FigmaQuizFonts.suit,
              fontSize: figma.s(FigmaQuizQuestionTokens.numberFontSize),
              fontWeight: FontWeight.w100,
              color: showExplanation
                  ? FigmaQuizQuestionTokens.explainNumber
                  : FigmaQuizQuestionTokens.questionNumber,
              height: 1.3,
            ),
          ),
        ),
      ),
      if (showExplanation)
        ..._explanationBubble(figma)
      else ...[
        FigmaBox(
          figma: figma,
          left: FigmaQuizQuestionTokens.bubbleLeft,
          top: FigmaQuizQuestionTokens.bubbleTop,
          width: FigmaQuizQuestionTokens.bubbleWidth,
          height: FigmaQuizQuestionTokens.bubbleHeight + contentShift,
          child: Transform.flip(
            flipX: true,
            child: FigmaSvg(
              FigmaAssets.quizSpeechBubble,
              width: figma.s(FigmaQuizQuestionTokens.bubbleWidth),
              height: figma.s(
                FigmaQuizQuestionTokens.bubbleHeight + contentShift,
              ),
              fit: BoxFit.fill,
            ),
          ),
        ),
        FigmaBox(
          figma: figma,
          left: FigmaQuizQuestionTokens.questionLeft,
          top: FigmaQuizQuestionTokens.questionTop,
          width: FigmaQuizQuestionTokens.questionWidth,
          height: questionHeight,
          child: Center(
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: QuizQuestionLayout.textStyle(
                fontFamily: FigmaQuizFonts.pretendard,
                fontSize: figma.s(FigmaQuizQuestionTokens.questionFontSize),
                lineHeight: FigmaQuizQuestionTokens.questionLineHeight,
              ),
            ),
          ),
        ),
        FigmaBox(
          figma: figma,
          left: FigmaQuizQuestionTokens.characterShadowLeft,
          top: FigmaQuizQuestionTokens.characterShadowTop + contentShift,
          width: FigmaQuizQuestionTokens.characterShadowWidth,
          height: FigmaQuizQuestionTokens.characterShadowHeight,
          child: FigmaSvg(
            FigmaAssets.quizCharacterShadow,
            width: figma.s(FigmaQuizQuestionTokens.characterShadowWidth),
            height: figma.s(FigmaQuizQuestionTokens.characterShadowHeight),
            fit: BoxFit.fill,
          ),
        ),
        FigmaBox(
          figma: figma,
          left: FigmaQuizQuestionTokens.characterLeft,
          top: FigmaQuizQuestionTokens.characterTop + contentShift,
          width: FigmaQuizQuestionTokens.characterWidth,
          height: FigmaQuizQuestionTokens.characterHeight,
          child: FigmaSvg(
            FigmaAssets.quizCharacter,
            width: figma.s(FigmaQuizQuestionTokens.characterWidth),
            height: figma.s(FigmaQuizQuestionTokens.characterHeight),
          ),
        ),
      ],
      if (showAnswer) ..._answerToggle(figma, contentShift),
      for (var i = 0; i < FigmaQuizQuestionTokens.optionTops.length; i++)
        FigmaTapArea(
          figma: figma,
          left: FigmaQuizQuestionTokens.optionLeft,
          top: FigmaQuizQuestionTokens.optionTops[i] + contentShift,
          width: FigmaQuizQuestionTokens.optionWidth,
          height: FigmaQuizQuestionTokens.optionHeight,
          onTap: locked || i >= options.length ? null : () => onSelect(i),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _optionFill(i),
              borderRadius: BorderRadius.circular(
                figma.s(FigmaQuizQuestionTokens.optionRadius),
              ),
              border: Border.all(
                color: _optionBorder(i),
                width: figma.s(FigmaQuizQuestionTokens.optionBorderWidth),
              ),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: figma.s(16)),
                child: Text(
                  i < options.length ? options[i] : '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FigmaQuizFonts.pretendard,
                    fontSize: figma.s(FigmaQuizQuestionTokens.optionFontSize),
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      FigmaTapArea(
        figma: figma,
        left: FigmaQuizQuestionTokens.ctaLeft,
        top: FigmaQuizQuestionTokens.ctaTop + contentShift,
        width: FigmaQuizQuestionTokens.ctaWidth,
        height: FigmaQuizQuestionTokens.ctaHeight,
        onTap: canNext ? onNext : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FigmaQuizQuestionTokens.cta.withValues(
              alpha: canNext ? 1 : 0.4,
            ),
            borderRadius: BorderRadius.circular(
              figma.s(FigmaQuizQuestionTokens.ctaRadius),
            ),
          ),
          child: Center(
            child: Text(
              submitting ? '제출 중…' : '다음으로',
              style: TextStyle(
                fontFamily: FigmaQuizFonts.pretendard,
                fontSize: figma.s(FigmaQuizQuestionTokens.ctaFontSize),
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

  Color _optionFill(int index) {
    if (!showAnswer || showExplanation || index >= options.length) {
      return Colors.white;
    }
    if (index == correctIndex) return FigmaQuizQuestionTokens.optionCorrectFill;
    if (index == selectedIndex) return FigmaQuizQuestionTokens.optionWrongFill;
    return Colors.white;
  }

  Color _optionBorder(int index) {
    if (index >= options.length || showExplanation) {
      return FigmaQuizQuestionTokens.optionBorder;
    }
    if (showAnswer) {
      if (index == correctIndex) {
        return FigmaQuizQuestionTokens.optionCorrectBorder;
      }
      if (index == selectedIndex) {
        return FigmaQuizQuestionTokens.optionWrongBorder;
      }
      return FigmaQuizQuestionTokens.optionBorder;
    }
    if (selectedIndex == index) {
      return FigmaQuizQuestionTokens.optionSelectedBorder;
    }
    return FigmaQuizQuestionTokens.optionBorder;
  }

  List<Widget> _explanationBubble(FigmaScale figma) {
    return [
      FigmaBox(
        figma: figma,
        left: FigmaQuizQuestionTokens.bubbleLeft,
        top: FigmaQuizQuestionTokens.bubbleTop,
        width: FigmaQuizQuestionTokens.bubbleWidth,
        height: FigmaQuizQuestionTokens.explainBubbleHeight,
        child: Transform.flip(
          flipX: true,
          child: FigmaSvg(
            FigmaAssets.quizSpeechBubbleExplain,
            width: figma.s(FigmaQuizQuestionTokens.bubbleWidth),
            height: figma.s(FigmaQuizQuestionTokens.explainBubbleHeight),
            fit: BoxFit.fill,
          ),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: FigmaQuizQuestionTokens.explainTextLeft,
        top: FigmaQuizQuestionTokens.explainTextTop,
        width: FigmaQuizQuestionTokens.explainTextWidth,
        height: FigmaQuizQuestionTokens.explainTextHeight,
        child: SingleChildScrollView(
          child: Text(
            explanation.isEmpty ? question : explanation,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: FigmaQuizFonts.pretendard,
              fontSize: figma.s(FigmaQuizQuestionTokens.questionFontSize),
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.35,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _answerToggle(FigmaScale figma, double contentShift) {
    final explain = showExplanation;
    final questionColor = explain
        ? FigmaQuizQuestionTokens.toggleInactive
        : FigmaQuizQuestionTokens.toggleActive;
    final explainColor = explain
        ? FigmaQuizQuestionTokens.toggleExplainActive
        : FigmaQuizQuestionTokens.toggleInactive;

    return [
      FigmaBox(
        figma: figma,
        left: explain
            ? FigmaQuizQuestionTokens.explainToggleLeft
            : FigmaQuizQuestionTokens.toggleLeft,
        top: explain
            ? FigmaQuizQuestionTokens.explainToggleTop
            : FigmaQuizQuestionTokens.toggleTop + contentShift,
        width: FigmaQuizQuestionTokens.toggleWidth,
        height: FigmaQuizQuestionTokens.toggleHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FigmaQuizQuestionTokens.toggleFill,
            borderRadius: BorderRadius.circular(
              figma.s(FigmaQuizQuestionTokens.toggleRadius),
            ),
            border: Border.all(
              color: FigmaQuizQuestionTokens.toggleBorder,
              width: figma.s(FigmaQuizQuestionTokens.toggleBorderWidth),
            ),
          ),
        ),
      ),
      FigmaTapArea(
        figma: figma,
        left: explain
            ? FigmaQuizQuestionTokens.explainToggleQuestionLeft
            : FigmaQuizQuestionTokens.toggleQuestionLeft,
        top: explain
            ? FigmaQuizQuestionTokens.explainToggleQuestionTop
            : FigmaQuizQuestionTokens.toggleQuestionTop + contentShift,
        width: FigmaQuizQuestionTokens.toggleQuestionWidth,
        height: FigmaQuizQuestionTokens.toggleLabelHeight,
        onTap: onQuestionTap,
        child: Text(
          '문제',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FigmaQuizFonts.pretendard,
            fontSize: figma.s(FigmaQuizQuestionTokens.toggleFontSize),
            fontWeight: FontWeight.w600,
            color: questionColor,
            height: 15 / 14,
          ),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: explain
            ? FigmaQuizQuestionTokens.explainToggleDividerLeft
            : FigmaQuizQuestionTokens.toggleDividerLeft,
        top: explain
            ? FigmaQuizQuestionTokens.explainToggleDividerTop
            : FigmaQuizQuestionTokens.toggleDividerTop + contentShift,
        width: FigmaQuizQuestionTokens.toggleDividerWidth,
        height: FigmaQuizQuestionTokens.toggleDividerHeight,
        child: ColoredBox(color: FigmaQuizQuestionTokens.toggleBorder),
      ),
      FigmaTapArea(
        figma: figma,
        left: explain
            ? FigmaQuizQuestionTokens.explainToggleExplainLeft
            : FigmaQuizQuestionTokens.toggleExplainLeft,
        top: explain
            ? FigmaQuizQuestionTokens.explainToggleExplainTop
            : FigmaQuizQuestionTokens.toggleExplainTop + contentShift,
        width: FigmaQuizQuestionTokens.toggleExplainWidth,
        height: FigmaQuizQuestionTokens.toggleLabelHeight,
        onTap: onExplanationTap,
        child: Text(
          '해설',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FigmaQuizFonts.pretendard,
            fontSize: figma.s(FigmaQuizQuestionTokens.toggleFontSize),
            fontWeight: FontWeight.w600,
            color: explainColor,
            height: 15 / 14,
          ),
        ),
      ),
    ];
  }
}
