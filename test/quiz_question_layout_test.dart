import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/theme/figma_quiz_fonts.dart';
import 'package:testapp/theme/figma_quiz_ox_tokens.dart';
import 'package:testapp/widgets/figma/quiz_question_layout.dart';

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
}
