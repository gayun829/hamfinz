import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/theme/figma_quiz_fonts.dart';
import 'package:testapp/theme/figma_quiz_ox_tokens.dart';
import 'package:testapp/theme/figma_quiz_question_tokens.dart';
import 'package:testapp/widgets/figma/figma_quiz_ox_view.dart';
import 'package:testapp/widgets/figma/figma_quiz_question_view.dart';
import 'package:testapp/widgets/figma/figma_scale.dart';
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
    testWidgets('OX 짧은 질문은 폭 $width에서 기존 CTA 칸을 유지한다', (tester) async {
      await _pumpQuiz(
        tester,
        width: width,
        child: _oxView('금리는 돈의 가격이다.'),
      );

      _expectQuestionNotClipped(tester, '금리는 돈의 가격이다.');
      _expectCtaInDesignSlot(
        tester,
        width: width,
        ctaTop: FigmaQuizOxTokens.ctaTop,
        ctaHeight: FigmaQuizOxTokens.ctaHeight,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('OX 긴 질문은 폭 $width에서 잘리지 않고 CTA가 내려간다', (tester) async {
      await _pumpQuiz(tester, width: width, child: _oxView('금리는 돈의 가격이다.'));
      final shortTop = tester.getTopLeft(find.text('다음으로')).dy;

      await _pumpQuiz(tester, width: width, child: _oxView(longQuestion));

      _expectQuestionNotClipped(tester, longQuestion);
      expect(tester.getTopLeft(find.text('다음으로')).dy, greaterThan(shortTop + 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 짧은 질문은 폭 $width에서 기존 CTA 칸을 유지한다', (tester) async {
      await _pumpQuiz(
        tester,
        width: width,
        child: _choiceView('금리는 돈의 가격이다.'),
      );

      _expectQuestionNotClipped(tester, '금리는 돈의 가격이다.');
      _expectCtaInDesignSlot(
        tester,
        width: width,
        ctaTop: FigmaQuizQuestionTokens.ctaTop,
        ctaHeight: FigmaQuizQuestionTokens.ctaHeight,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('객관식 긴 질문은 폭 $width에서 잘리지 않고 CTA가 내려간다', (tester) async {
      await _pumpQuiz(
        tester,
        width: width,
        child: _choiceView('금리는 돈의 가격이다.'),
      );
      final shortTop = tester.getTopLeft(find.text('다음으로')).dy;

      await _pumpQuiz(tester, width: width, child: _choiceView(longQuestion));

      _expectQuestionNotClipped(tester, longQuestion);
      expect(tester.getTopLeft(find.text('다음으로')).dy, greaterThan(shortTop + 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('비선형 글자 확대에서 OX 질문이 폭 $width에서 잘리지 않는다', (
      tester,
    ) async {
      await _pumpQuiz(
        tester,
        width: width,
        scaler: const _NonlinearTextScaler(),
        child: _oxView(longQuestion),
      );

      _expectQuestionNotClipped(tester, longQuestion);
      expect(tester.takeException(), isNull);
    });

    testWidgets('비선형 글자 확대에서 객관식 질문이 폭 $width에서 잘리지 않는다', (
      tester,
    ) async {
      await _pumpQuiz(
        tester,
        width: width,
        scaler: const _NonlinearTextScaler(),
        child: _choiceView(longQuestion),
      );

      _expectQuestionNotClipped(tester, longQuestion);
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
  await tester.binding.setSurfaceSize(Size(width, 852));
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
}) {
  final scale = width / 393;
  const viewportHeight = 852.0;
  final contentHeight = FigmaScale.quizDesignHeight * scale;
  final topInset = contentHeight <= viewportHeight + 0.5
      ? viewportHeight - contentHeight
      : 0.0;
  final dy = tester.getTopLeft(find.text('다음으로')).dy;
  final slotTop = topInset + ctaTop * scale;
  expect(dy, greaterThanOrEqualTo(slotTop - 1));
  expect(dy, lessThan(slotTop + ctaHeight * scale));
}

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

Widget _choiceView(String question) {
  return FigmaQuizQuestionView(
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
