import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../theme/figma_quiz_fonts.dart';
import '../../theme/figma_quiz_question_tokens.dart';
import 'figma_asset_image.dart';
import 'figma_canvas.dart';
import 'figma_scale.dart';
import 'quiz_coin_bar.dart';
import 'quiz_question_layout.dart';

typedef _T = FigmaQuizQuestionTokens;

/// 짧은 질문은 햄핀이 위 말풍선, 긴 질문과 해설은 꼬리 없는 박스에 담는다.
enum _QuestionLayout { bubble, box, explanation }

/// 4지선다 퀴즈. Figma `632:1982` 짧은 문제 / `632:1090` 긴 문제 /
/// `632:1288`·`632:1182` 정답 / `632:1795` 해설.
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

  double get _boxFontSize =>
      question.characters.length >= _T.longQuestionMinLength
      ? _T.longQuestionFontSize
      : _T.boxFontSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final textScaler = MediaQuery.textScalerOf(context);
          final layout = _layoutFor(constraints, textScaler);
          final questionHeight = layout == _QuestionLayout.box
              ? QuizQuestionLayout.fittedTextHeight(
                  constraints: constraints,
                  designWidth: FigmaScale.quizDesignWidth,
                  baseCanvasHeight: _T.contentHeight,
                  minimumHeight: _T.boxTextHeight,
                  measure: (scale) => QuizQuestionLayout.textHeight(
                    text: question,
                    width: _T.boxTextWidth,
                    fontSize: _boxFontSize,
                    lineHeight: _T.questionLineHeight,
                    minimumHeight: _T.boxTextHeight,
                    fontFamily: FigmaQuizFonts.pretendard,
                    textAlign: TextAlign.left,
                    textScaler: textScaler,
                    scale: scale,
                  ),
                )
              : _T.boxTextHeight;
          final contentShift = questionHeight - _T.boxTextHeight;

          return FigmaCanvas(
            designWidth: FigmaScale.quizDesignWidth,
            designHeight: _T.contentHeight + contentShift,
            backgroundColor: _T.background,
            // 퀴즈는 한 화면에 다 보여야 해서 스크롤 대신 세로에도 맞춰 줄인다.
            fit: FigmaCanvasFit.viewport,
            scrollable: false,
            alignment: Alignment.topCenter,
            builder: (context, figma) => _layers(
              figma,
              layout: layout,
              questionHeight: questionHeight,
              contentShift: contentShift,
            ),
          );
        },
      ),
    );
  }

  /// 60자 이하이면서 말풍선 세 줄에 들어가면 말풍선, 아니면 박스.
  _QuestionLayout _layoutFor(
    BoxConstraints constraints,
    TextScaler textScaler,
  ) {
    if (showExplanation) return _QuestionLayout.explanation;
    if (question.characters.length > _T.shortQuestionMaxLength) {
      return _QuestionLayout.box;
    }
    final widthScale = constraints.maxWidth / FigmaScale.quizDesignWidth;
    final scale = constraints.hasBoundedHeight
        ? math.min(widthScale, constraints.maxHeight / _T.contentHeight)
        : widthScale;
    final height = QuizQuestionLayout.textHeight(
      text: question,
      width: _T.bubbleTextWidth,
      fontSize: _T.bubbleFontSize,
      lineHeight: _T.questionLineHeight,
      letterSpacing: _T.bubbleLetterSpacing,
      minimumHeight: 0,
      fontFamily: FigmaQuizFonts.pretendard,
      textAlign: TextAlign.left,
      textScaler: textScaler,
      scale: scale,
    );
    final maxHeight =
        _T.bubbleFontSize * _T.questionLineHeight * _T.bubbleTextMaxLines + 1;
    return height <= maxHeight ? _QuestionLayout.bubble : _QuestionLayout.box;
  }

  List<Widget> _layers(
    FigmaScale figma, {
    required _QuestionLayout layout,
    required double questionHeight,
    required double contentShift,
  }) {
    final progress = questionNumber / totalQuestions.clamp(1, 999);
    final fillWidth = _T.progressWidth * progress.clamp(0.0, 1.0);
    final highlightWidth =
        (fillWidth -
                _T.progressHighlightLeftInset -
                _T.progressHighlightRightInset)
            .clamp(0.0, fillWidth);
    final canNext = selectedIndex != null && !submitting;

    return [
      FigmaTapArea(
        figma: figma,
        left: _T.backTapLeft,
        top: _T.backTapTop,
        width: _T.backTapSize,
        height: _T.backTapSize,
        onTap: onBack,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: figma.s(_T.backLeft - _T.backTapLeft),
            ),
            child: FigmaSvg(
              FigmaAssets.quizBackChevronQuestion,
              width: figma.s(_T.backWidth),
              height: figma.s(_T.backHeight),
            ),
          ),
        ),
      ),
      FigmaPill(
        figma: figma,
        left: _T.progressLeft,
        top: _T.progressTop,
        width: _T.progressWidth,
        height: _T.progressHeight,
        color: _T.progressTrack,
        radius: _T.progressRadius,
      ),
      if (fillWidth > 0)
        FigmaPill(
          figma: figma,
          left: _T.progressLeft,
          top: _T.progressTop,
          width: fillWidth,
          height: _T.progressHeight,
          color: _T.progressFill,
          radius: _T.progressRadius,
        ),
      if (highlightWidth > 0)
        FigmaPill(
          figma: figma,
          left: _T.progressHighlightLeft,
          top: _T.progressHighlightTop,
          width: highlightWidth,
          height: _T.progressHighlightHeight,
          color: _T.progressHighlight.withValues(
            alpha: _T.progressHighlightOpacity,
          ),
        ),
      FigmaBox(
        figma: figma,
        left: _T.qIconLeft,
        top: _T.qIconTop,
        width: _T.qIconWidth,
        height: _T.qIconHeight,
        child: FigmaSvg(
          showExplanation
              ? FigmaAssets.quizQuestionIconExplain
              : FigmaAssets.quizQuestionIcon,
          width: figma.s(_T.qIconWidth),
          height: figma.s(_T.qIconHeight),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: _T.numberLeft,
        top: _T.numberTop,
        width: _T.numberWidth,
        height: _T.numberHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$questionNumber',
            style: TextStyle(
              fontFamily: FigmaQuizFonts.suit,
              fontSize: figma.s(_T.numberFontSize),
              fontWeight: FontWeight.w100,
              color: showExplanation ? _T.explainNumber : _T.questionNumber,
              height: 1.3,
            ),
          ),
        ),
      ),
      ...switch (layout) {
        _QuestionLayout.bubble => _bubbleLayers(figma),
        _QuestionLayout.box => _boxLayers(figma, questionHeight, contentShift),
        _QuestionLayout.explanation => _explanationLayers(figma),
      },
      if (showAnswer)
        ..._answerToggle(figma, switch (layout) {
          _QuestionLayout.bubble => _T.bubbleToggle,
          _QuestionLayout.box => _T.boxToggle + Offset(0, contentShift),
          _QuestionLayout.explanation => _T.explainToggle,
        }),
      for (var i = 0; i < _T.optionTops.length; i++)
        FigmaTapArea(
          figma: figma,
          left: _T.optionLeft,
          top: _T.optionTops[i] + contentShift,
          width: _T.optionWidth,
          height: _T.optionHeight,
          onTap: locked || i >= options.length ? null : () => onSelect(i),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _optionFill(i),
              borderRadius: BorderRadius.circular(figma.s(_T.optionRadius)),
              border: Border.all(
                color: _optionBorder(i),
                width: figma.s(_T.optionBorderWidth),
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
                    fontSize: figma.s(_T.optionFontSize),
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
        left: _T.ctaLeft,
        top: _T.ctaTop + contentShift,
        width: _T.ctaWidth,
        height: _T.ctaHeight,
        onTap: canNext ? onNext : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _T.cta.withValues(alpha: canNext ? 1 : 0.4),
            borderRadius: BorderRadius.circular(figma.s(_T.ctaRadius)),
          ),
          child: Center(
            child: Text(
              submitting ? '제출 중…' : '다음으로',
              style: TextStyle(
                fontFamily: FigmaQuizFonts.pretendard,
                fontSize: figma.s(_T.ctaFontSize),
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

  /// Figma `632:1982` — 햄핀이 그림자·햄핀이·말풍선·질문·코인 순서.
  List<Widget> _bubbleLayers(FigmaScale figma) {
    return [
      FigmaBox(
        figma: figma,
        left: _T.characterShadowLeft,
        top: _T.characterShadowTop,
        width: _T.characterShadowWidth,
        height: _T.characterShadowHeight,
        child: const FigmaSvg(
          FigmaAssets.quizCharacterShadow,
          fit: BoxFit.fill,
        ),
      ),
      FigmaBox(
        figma: figma,
        left: _T.characterLeft,
        top: _T.characterTop,
        width: _T.characterWidth,
        height: _T.characterHeight,
        child: const FigmaSvg(FigmaAssets.quizCharacter, fit: BoxFit.fill),
      ),
      FigmaBox(
        figma: figma,
        left: _T.bubbleLeft,
        top: _T.bubbleTop,
        width: _T.bubbleWidth,
        height: _T.bubbleHeight,
        child: Transform.flip(
          flipX: true,
          child: const FigmaSvg(FigmaAssets.quizSpeechBubble, fit: BoxFit.fill),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: _T.bubbleTextLeft,
        top: _T.bubbleTop,
        width: _T.bubbleTextWidth,
        height: _T.bubbleBodyHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            question,
            style: QuizQuestionLayout.textStyle(
              fontFamily: FigmaQuizFonts.pretendard,
              fontSize: figma.s(_T.bubbleFontSize),
              lineHeight: _T.questionLineHeight,
              letterSpacing: figma.s(_T.bubbleLetterSpacing),
            ),
          ),
        ),
      ),
      ..._bubbleCoins(figma),
    ];
  }

  /// Figma `632:1090` — 꼬리 없는 박스와 오른쪽 위 코인.
  List<Widget> _boxLayers(
    FigmaScale figma,
    double questionHeight,
    double contentShift,
  ) {
    final boxHeight = (showAnswer ? _T.boxAnswerHeight : _T.boxHeight);
    return [
      FigmaBox(
        figma: figma,
        left: _T.boxLeft,
        top: _T.boxTop,
        width: _T.boxWidth,
        height: boxHeight + contentShift,
        child: Transform.flip(
          flipX: true,
          child: _StretchedSvg(
            figma: figma,
            asset: showAnswer
                ? FigmaAssets.quizQuestionBoxAnswer
                : FigmaAssets.quizQuestionBox,
            width: _T.boxWidth,
            height: boxHeight,
            extraHeight: contentShift,
          ),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: _T.boxTextLeft,
        top: _T.boxTextTop,
        width: _T.boxTextWidth,
        height: questionHeight,
        child: Text(
          question,
          style: QuizQuestionLayout.textStyle(
            fontFamily: FigmaQuizFonts.pretendard,
            fontSize: figma.s(_boxFontSize),
            lineHeight: _T.questionLineHeight,
          ),
        ),
      ),
      ..._boxCoins(figma, boxShift: contentShift),
    ];
  }

  /// Figma `632:1795` — 노란 해설 박스. 길면 박스 안에서만 스크롤한다.
  List<Widget> _explanationLayers(FigmaScale figma) {
    return [
      FigmaBox(
        figma: figma,
        left: _T.boxLeft,
        top: _T.boxTop,
        width: _T.boxWidth,
        height: _T.boxAnswerHeight,
        child: Transform.flip(
          flipX: true,
          child: const FigmaSvg(FigmaAssets.quizExplainBox, fit: BoxFit.fill),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: _T.boxTextLeft,
        top: _T.boxTextTop,
        width: _T.boxTextWidth,
        height: _T.boxTextHeight,
        child: SingleChildScrollView(
          child: Text(
            explanation.isEmpty ? question : explanation,
            style: QuizQuestionLayout.textStyle(
              fontFamily: FigmaQuizFonts.pretendard,
              fontSize: figma.s(_T.explainFontSize),
              lineHeight: _T.questionLineHeight,
            ),
          ),
        ),
      ),
      ..._boxCoins(figma, boxShift: 0),
    ];
  }

  /// 햄핀이 옆 코인 (Ellipse 228·Rectangle 808/810·Group 620·Vector·그림자).
  List<Widget> _bubbleCoins(FigmaScale figma) {
    return [
      _rotatedArt(
        figma,
        box: const Rect.fromLTWH(324, 311, 24.257, 24.257),
        inner: const Size(23, 23),
        degrees: -3.22,
        asset: FigmaAssets.quizCoin,
        assetRect: const Rect.fromLTWH(-10.2994, -9.2989, 43.6, 43.6),
      ),
      QuizCoinBar(
        figma: figma,
        box: const Rect.fromLTWH(213.84, 338.15, 22.086, 15.276),
        size: const Size(8.049, 20.57),
        degrees: -67.62,
        radius: 13.415,
        opacity: 0.53,
        glowOffsetY: 1,
        glowBlur: 8.3,
        glowSpread: 2,
      ),
      QuizCoinBar(
        figma: figma,
        box: const Rect.fromLTWH(274, 301, 23.557, 21.437),
        size: const Size(9, 23),
        degrees: 51.15,
        radius: 15,
        opacity: 0.77,
        glowOffsetY: 1,
        glowBlur: 8.3,
        glowSpread: 2,
      ),
      _art(
        figma,
        FigmaAssets.quizCoinStack,
        const Rect.fromLTWH(136.6987, 333.708, 49.6, 62.5971),
      ),
      _rotatedArt(
        figma,
        box: const Rect.fromLTWH(330, 317, 11.878, 13.037),
        inner: const Size(7, 11),
        degrees: -33.17,
        asset: FigmaAssets.quizCoinMark,
        assetRect: const Rect.fromLTWH(0, 0, 7, 11),
      ),
      _art(
        figma,
        FigmaAssets.quizCoinShadowSmall,
        const Rect.fromLTWH(214, 364, 19, 7),
      ),
      _art(
        figma,
        FigmaAssets.quizCoinShadowMedium,
        const Rect.fromLTWH(274, 335, 24, 9),
      ),
      _art(
        figma,
        FigmaAssets.quizCoinShadowLarge,
        const Rect.fromLTWH(322, 351.42, 27, 10),
      ),
    ];
  }

  /// 긴 질문·해설 박스 아래 코인 (Ellipse 231·Group 629/630/631, Figma `639:2721`).
  /// 토글이 있으면 그 왼쪽으로 옮긴다 (`639:2820`·`639:3380`).
  List<Widget> _boxCoins(FigmaScale figma, {required double boxShift}) {
    final shift =
        Offset(0, boxShift) +
        (showAnswer || showExplanation ? _togglePairShift : Offset.zero);
    Rect at(double left, double top, double width, double height) =>
        Rect.fromLTWH(left, top, width, height).shift(shift);

    return [
      _art(figma, FigmaAssets.quizBoxCoinShadow, at(288, 381, 15, 5)),
      _art(figma, FigmaAssets.quizBoxCoinStack, at(308.7, 345.7, 48.6, 51.6)),
      _art(
        figma,
        FigmaAssets.quizBoxCoin,
        at(246.329, 352.328, 43.6006, 43.6006),
      ),
      _rotatedArt(
        figma,
        box: at(283, 359, 23.982, 23.982),
        inner: const Size(17.251, 17.251),
        degrees: 55.59,
        asset: FigmaAssets.quizBoxCoinSmall,
        assetRect: const Rect.fromLTWH(-6.878, -6.167, 31.0085, 31.0085),
      ),
    ];
  }

  /// 문제/해설 토글이 박스 아래 오른쪽을 차지하면 코인은 그 왼쪽에 선다.
  static const _togglePairShift = Offset(-92, 12);

  Widget _art(FigmaScale figma, String asset, Rect rect) {
    return FigmaBox(
      figma: figma,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: FigmaSvg(asset, fit: BoxFit.fill),
    );
  }

  /// 회전한 레이어. [box]는 회전 후 바운딩 박스, [inner]는 회전 전 크기,
  /// [assetRect]는 그림자 여백을 포함한 SVG의 [inner] 기준 자리다.
  Widget _rotatedArt(
    FigmaScale figma, {
    required Rect box,
    required Size inner,
    required double degrees,
    required String asset,
    required Rect assetRect,
  }) {
    return FigmaBox(
      figma: figma,
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      child: Center(
        child: Transform.rotate(
          angle: degrees * math.pi / 180,
          child: SizedBox(
            width: figma.s(inner.width),
            height: figma.s(inner.height),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: figma.s(assetRect.left),
                  top: figma.s(assetRect.top),
                  width: figma.s(assetRect.width),
                  height: figma.s(assetRect.height),
                  child: FigmaSvg(asset, fit: BoxFit.fill),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _optionFill(int index) {
    // 해설을 보는 동안에도 정답·오답 색을 그대로 둔다.
    if (!showAnswer || index >= options.length) return Colors.white;
    if (index == correctIndex) return _T.optionCorrectFill;
    if (index == selectedIndex) return _T.optionWrongFill;
    return Colors.white;
  }

  Color _optionBorder(int index) {
    if (index >= options.length) return _T.optionBorder;
    if (showAnswer) {
      if (index == correctIndex) return _T.optionCorrectBorder;
      if (index == selectedIndex) return _T.optionWrongBorder;
      return _T.optionBorder;
    }
    if (selectedIndex == index) return _T.optionSelectedBorder;
    return _T.optionBorder;
  }

  /// 문제/해설 토글. [origin]은 토글 알약의 왼쪽 위.
  List<Widget> _answerToggle(FigmaScale figma, Offset origin) {
    final explain = showExplanation;
    final questionColor = explain ? _T.toggleInactive : _T.toggleActive;
    final explainColor = explain ? _T.toggleExplainActive : _T.toggleInactive;
    final labelTop = origin.dy + _T.toggleLabelDy;

    Widget label(
      String text,
      double dx,
      double width,
      Color color,
      VoidCallback? onTap,
    ) {
      return FigmaTapArea(
        figma: figma,
        left: origin.dx + dx,
        top: labelTop,
        width: width,
        height: _T.toggleLabelHeight,
        onTap: onTap,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FigmaQuizFonts.pretendard,
            fontSize: figma.s(_T.toggleFontSize),
            fontWeight: FontWeight.w600,
            color: color,
            height: 15 / 14,
          ),
        ),
      );
    }

    return [
      FigmaBox(
        figma: figma,
        left: origin.dx,
        top: origin.dy,
        width: _T.toggleWidth,
        height: _T.toggleHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _T.toggleFill,
            borderRadius: BorderRadius.circular(figma.s(_T.toggleRadius)),
            border: Border.all(
              color: _T.toggleBorder,
              width: figma.s(_T.toggleBorderWidth),
            ),
          ),
        ),
      ),
      label(
        '문제',
        _T.toggleQuestionDx,
        _T.toggleQuestionWidth,
        questionColor,
        onQuestionTap,
      ),
      FigmaBox(
        figma: figma,
        left: origin.dx + _T.toggleDividerDx,
        top: origin.dy + _T.toggleDividerDy,
        width: _T.toggleDividerWidth,
        height: _T.toggleDividerHeight,
        child: const ColoredBox(color: _T.toggleBorder),
      ),
      label(
        '해설',
        _T.toggleExplainDx,
        _T.toggleExplainWidth,
        explainColor,
        onExplanationTap,
      ),
    ];
  }
}

/// 박스가 늘어날 때 SVG 전체를 BoxFit.fill로 늘리면 둥근 모서리가 세로로
/// 찌그러진다. 위·아래는 원래 비율로 그리고, 모서리 사이 곧은 구간의 한 줄만
/// 세로로 늘려 늘어난 높이를 채운다.
class _StretchedSvg extends StatelessWidget {
  const _StretchedSvg({
    required this.figma,
    required this.asset,
    required this.width,
    required this.height,
    required this.extraHeight,
  });

  final FigmaScale figma;
  final String asset;
  final double width;
  final double height;
  final double extraHeight;

  /// 늘린 줄이 위·아래 조각 밑으로 겹쳐 들어가 이음새가 보이지 않게 한다.
  static const _overlap = 1.0;

  /// 모서리 반지름(13)보다 충분히 아래인 세로 가운데는 좌우 테두리가 곧다.
  double get _split => height / 2;

  @override
  Widget build(BuildContext context) {
    if (extraHeight <= 0) {
      return _slice(top: 0, sourceTop: 0, sourceHeight: height);
    }
    return SizedBox(
      width: figma.s(width),
      height: figma.s(height + extraHeight),
      child: Stack(
        children: [
          _slice(
            top: _split - _overlap,
            sourceTop: _split,
            sourceHeight: 1,
            drawHeight: extraHeight + _overlap * 2,
          ),
          _slice(top: 0, sourceTop: 0, sourceHeight: _split),
          _slice(
            top: _split + extraHeight,
            sourceTop: _split,
            sourceHeight: height - _split,
          ),
        ],
      ),
    );
  }

  /// SVG의 [sourceTop]부터 [sourceHeight]만큼을 [drawHeight] 높이로 그린다.
  Widget _slice({
    required double top,
    required double sourceTop,
    required double sourceHeight,
    double? drawHeight,
  }) {
    final drawn = drawHeight ?? sourceHeight;
    final stretch = drawn / sourceHeight;
    final slice = SizedBox(
      width: figma.s(width),
      height: figma.s(drawn),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: 0,
            top: -figma.s(sourceTop * stretch),
            width: figma.s(width),
            height: figma.s(height * stretch),
            child: FigmaSvg(
              asset,
              width: figma.s(width),
              height: figma.s(height * stretch),
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
    if (extraHeight <= 0) return slice;
    return Positioned(left: 0, top: figma.s(top), child: slice);
  }
}
