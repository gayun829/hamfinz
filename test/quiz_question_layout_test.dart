import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/constants/figma_assets.dart';
import 'package:testapp/theme/figma_quiz_fonts.dart';
import 'package:testapp/theme/figma_quiz_ox_tokens.dart';
import 'package:testapp/theme/figma_quiz_question_tokens.dart';
import 'package:testapp/widgets/figma/figma_asset_image.dart';
import 'package:testapp/widgets/figma/figma_quiz_ox_view.dart';
import 'package:testapp/widgets/figma/figma_quiz_question_view.dart';
import 'package:testapp/widgets/figma/quiz_question_layout.dart';

/// 큰 글자일수록 배율이 커진다. Android 비선형 글꼴 확대와 같은 형태다.
class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize * (1 + fontSize / 80);

  @override
  double get textScaleFactor => 1;
}

void main() {
  const longQuestion =
      '향후 1~3년 지급액 2,000,000원, 2,500,000원, 3,000,000원, '
      '할인율 4%의 준비금 현재가치는 6,500,000원보다 크다.';
  // 긴 질문 박스(여섯 줄)에도 다 들어가지 않아 박스가 늘어나는 질문.
  const overflowingQuestion = '$longQuestion $longQuestion $longQuestion';

  double oxHeight(String text, {TextScaler scaler = TextScaler.noScaling}) {
    return QuizQuestionLayout.textHeight(
      text: text,
      width: FigmaQuizOxTokens.questionWidth,
      fontSize: FigmaQuizOxTokens.questionFontSize,
      lineHeight: FigmaQuizOxTokens.questionLineHeight,
      minimumHeight: FigmaQuizOxTokens.questionHeight,
      fontFamily: FigmaQuizFonts.pretendard,
      textScaler: scaler,
    );
  }

  test('짧은 질문은 Figma 최소 높이를 유지한다', () {
    expect(oxHeight('금리는 돈의 가격이다.'), FigmaQuizOxTokens.questionHeight);
  });

  test('긴 질문은 말줄임 없이 영역을 늘린다', () {
    final height = oxHeight(longQuestion);
    expect(height, greaterThan(FigmaQuizOxTokens.questionHeight));
  });

  testWidgets('시스템 글자 확대 시 질문 영역이 더 커진다', (tester) async {
    const scaler = TextScaler.linear(1.4);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: scaler),
        child: const SizedBox.shrink(),
      ),
    );

    expect(
      oxHeight(longQuestion, scaler: scaler),
      greaterThan(oxHeight(longQuestion)),
    );
  });

  const widths = [360.0, 393.0, 786.0];

  for (final width in widths) {
    testWidgets('OX 짧은 질문은 폭 $width에서 CTA를 카드 바로 아래에 둔다', (tester) async {
      await _pumpQuiz(tester, width: width, child: _oxView('금리는 돈의 가격이다.'));

      _expectQuestionNotClipped(tester, '금리는 돈의 가격이다.');
      _expectCtaInDesignSlot(
        tester,
        width: width,
        ctaTop: FigmaQuizOxTokens.ctaTop,
        ctaHeight: FigmaQuizOxTokens.ctaHeight,
        contentHeight: FigmaQuizOxTokens.contentHeight,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('OX 긴 질문은 폭 $width에서 잘리지 않고 CTA가 내려간다', (tester) async {
      await _pumpQuiz(tester, width: width, child: _oxView('금리는 돈의 가격이다.'));
      final shortTop = tester.getTopLeft(find.text('다음으로')).dy;

      await _pumpQuiz(tester, width: width, child: _oxView(longQuestion));

      _expectQuestionNotClipped(tester, longQuestion);
      expect(
        tester.getTopLeft(find.text('다음으로')).dy,
        greaterThan(shortTop + 1),
      );
      _expectFitsWithoutScroll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 짧은 질문은 폭 $width에서 CTA를 보기 바로 아래에 둔다', (tester) async {
      await _pumpQuiz(tester, width: width, child: _choiceView('금리는 돈의 가격이다.'));

      _expectQuestionNotClipped(tester, '금리는 돈의 가격이다.');
      _expectCtaInDesignSlot(
        tester,
        width: width,
        ctaTop: FigmaQuizQuestionTokens.ctaTop,
        ctaHeight: FigmaQuizQuestionTokens.ctaHeight,
        contentHeight: FigmaQuizQuestionTokens.contentHeight,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 짧은 질문은 폭 $width에서 말풍선과 햄핀이·코인을 쓴다', (tester) async {
      await _pumpQuiz(tester, width: width, child: _choiceView('금리는 돈의 가격이다.'));

      expect(_svgCount(tester, FigmaAssets.quizSpeechBubble), 1);
      expect(_svgCount(tester, FigmaAssets.quizCharacter), 1);
      expect(_svgCount(tester, FigmaAssets.quizCoinStack), 1);
      expect(_svgCount(tester, FigmaAssets.quizQuestionBox), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 61자 이상 질문은 폭 $width에서 햄핀이 없는 박스에 18로 쓴다', (tester) async {
      await _pumpQuiz(tester, width: width, child: _choiceView(longQuestion));

      expect(_svgCount(tester, FigmaAssets.quizQuestionBox), 1);
      expect(_svgCount(tester, FigmaAssets.quizCharacter), 0);
      expect(_svgCount(tester, FigmaAssets.quizBoxCoinStack), 1);
      // 코인은 박스 오른쪽 위가 아니라 박스 아래에 선다 (Figma `639:2721`).
      expect(
        tester.getTopLeft(_svgFinder(FigmaAssets.quizBoxCoinStack)).dy,
        greaterThan(
          tester.getBottomLeft(_svgFinder(FigmaAssets.quizQuestionBox)).dy,
        ),
      );
      final style = tester.widget<Text>(find.text(longQuestion)).style!;
      expect(
        style.fontSize! /
            (math.min(
              width / 393,
              _viewportHeight / FigmaQuizQuestionTokens.contentHeight,
            )),
        closeTo(FigmaQuizQuestionTokens.longQuestionFontSize, 0.01),
      );
      _expectQuestionNotClipped(tester, longQuestion);
      _expectCtaInDesignSlot(
        tester,
        width: width,
        ctaTop: FigmaQuizQuestionTokens.ctaTop,
        ctaHeight: FigmaQuizQuestionTokens.ctaHeight,
        contentHeight: FigmaQuizQuestionTokens.contentHeight,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 박스에도 넘치는 질문은 폭 $width에서 잘리지 않고 CTA가 내려간다', (tester) async {
      await _pumpQuiz(tester, width: width, child: _choiceView(longQuestion));
      final boxTop = tester.getTopLeft(find.text('다음으로')).dy;

      await _pumpQuiz(
        tester,
        width: width,
        child: _choiceView(overflowingQuestion),
      );

      _expectQuestionNotClipped(tester, overflowingQuestion);
      expect(tester.getTopLeft(find.text('다음으로')).dy, greaterThan(boxTop + 1));
      _expectFitsWithoutScroll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 박스가 늘어나도 폭 $width에서 모서리를 찌그러뜨리지 않는다', (tester) async {
      await _pumpQuiz(
        tester,
        width: width,
        child: _choiceView(overflowingQuestion),
      );

      final boxes = tester
          .widgetList<FigmaSvg>(find.byType(FigmaSvg))
          .where((svg) => svg.asset == FigmaAssets.quizQuestionBox)
          .toList();
      final undistorted = boxes.where(
        (svg) =>
            (svg.height! / svg.width! -
                    FigmaQuizQuestionTokens.boxHeight /
                        FigmaQuizQuestionTokens.boxWidth)
                .abs() <
            0.001,
      );
      // 위·아래 조각(모서리)은 원래 비율, 가운데 한 줄만 늘린다.
      expect(boxes, hasLength(3));
      expect(undistorted, hasLength(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 긴 질문 정답·해설은 폭 $width에서 코인을 토글 왼쪽에 둔다', (tester) async {
      for (final explain in [false, true]) {
        await _pumpQuiz(
          tester,
          width: width,
          child: _choiceView(
            longQuestion,
            showAnswer: true,
            showExplanation: explain,
            explanation: '해설',
          ),
        );

        // Figma `639:2820`·`639:3380` — Group 630(코인 더미) 224,367 / 토글 270·272,368.
        final scale = math.min(
          width / 393,
          _viewportHeight / FigmaQuizQuestionTokens.contentHeight,
        );
        final left = (width - 393 * scale) / 2;
        final stack = tester.getTopLeft(
          _svgFinder(FigmaAssets.quizBoxCoinStack),
        );
        expect(stack.dx, closeTo(left + 216.7 * scale, 1));
        expect(stack.dy, closeTo(357.7 * scale, 1));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('객관식 해설을 봐도 폭 $width에서 정답 보기 색이 남는다', (tester) async {
      await _pumpQuiz(
        tester,
        width: width,
        child: _choiceView(
          '금리는 돈의 가격이다.',
          showAnswer: true,
          showExplanation: true,
          explanation: '해설',
        ),
      );

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('가'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, FigmaQuizQuestionTokens.optionCorrectFill);
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 해설은 폭 $width에서 노란 박스와 해설 토글을 쓴다', (tester) async {
      await _pumpQuiz(
        tester,
        width: width,
        child: _choiceView(
          '금리는 돈의 가격이다.',
          showAnswer: true,
          showExplanation: true,
          explanation: '돈을 빌리는 값이 금리다.',
        ),
      );

      expect(_svgCount(tester, FigmaAssets.quizExplainBox), 1);
      expect(_svgCount(tester, FigmaAssets.quizCharacter), 0);
      expect(find.text('돈을 빌리는 값이 금리다.'), findsOneWidget);
      expect(find.text('해설'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('비선형 글자 확대에서 OX 질문이 폭 $width에서 잘리지 않는다', (tester) async {
      await _pumpQuiz(
        tester,
        width: width,
        scaler: const _NonlinearTextScaler(),
        child: _oxView(longQuestion),
      );

      _expectQuestionNotClipped(tester, longQuestion);
      _expectFitsWithoutScroll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('비선형 글자 확대에서 객관식 질문이 폭 $width에서 잘리지 않는다', (tester) async {
      await _pumpQuiz(
        tester,
        width: width,
        scaler: const _NonlinearTextScaler(),
        child: _choiceView(longQuestion),
      );

      _expectQuestionNotClipped(tester, longQuestion);
      _expectFitsWithoutScroll(tester);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpQuiz(
  WidgetTester tester, {
  required double width,
  required Widget child,
  TextScaler scaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(Size(width, _viewportHeight));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: widget!,
        );
      },
      home: child,
    ),
  );
  await tester.pump();
}

void _expectQuestionNotClipped(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final needed = paragraph.getMinIntrinsicHeight(paragraph.size.width);
  expect(paragraph.size.height + 0.5, greaterThanOrEqualTo(needed));
}

void _expectCtaInDesignSlot(
  WidgetTester tester, {
  required double width,
  required double ctaTop,
  required double ctaHeight,
  required double contentHeight,
}) {
  final scale = math.min(width / 393, _viewportHeight / contentHeight);
  final dy = tester.getTopLeft(find.text('다음으로')).dy;
  final slotTop = ctaTop * scale;
  expect(dy, greaterThanOrEqualTo(slotTop - 1));
  expect(dy, lessThan(slotTop + ctaHeight * scale));
}

/// 퀴즈는 스크롤 없이 한 화면에 들어가고, 다음으로 버튼이 화면 안에 있어야 한다.
void _expectFitsWithoutScroll(WidgetTester tester) {
  expect(find.byType(Scrollable), findsNothing);
  expect(
    tester.getBottomLeft(find.text('다음으로')).dy,
    lessThanOrEqualTo(_viewportHeight),
  );
}

const _viewportHeight = 852.0;

Widget _oxView(String question) {
  return FigmaQuizOxView(
    questionNumber: 1,
    totalQuestions: 10,
    question: question,
    options: const ['O', 'X'],
    selectedIndex: null,
    submitting: false,
    locked: false,
    onBack: () {},
    onSelect: (_) {},
    onNext: () {},
  );
}

Finder _svgFinder(String asset) => find.byWidgetPredicate(
  (widget) => widget is FigmaSvg && widget.asset == asset,
);

int _svgCount(WidgetTester tester, String asset) => tester
    .widgetList<FigmaSvg>(find.byType(FigmaSvg))
    .where((svg) => svg.asset == asset)
    .length;

Widget _choiceView(
  String question, {
  bool showAnswer = false,
  bool showExplanation = false,
  String explanation = '',
}) {
  return FigmaQuizQuestionView(
    showAnswer: showAnswer,
    showExplanation: showExplanation,
    explanation: explanation,
    correctIndex: showAnswer ? 0 : null,
    questionNumber: 1,
    totalQuestions: 10,
    question: question,
    options: const ['가', '나', '다', '라'],
    selectedIndex: null,
    submitting: false,
    locked: false,
    onBack: () {},
    onSelect: (_) {},
    onNext: () {},
  );
}
