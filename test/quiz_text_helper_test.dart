import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/utils/quiz_text_helper.dart';

void main() {
  test('문제 앞뒤의 xlsx 메타 꼬리표를 뗀다', () {
    expect(
      stripQuizMetadataPrefix('[난이도 1·OX·첫 월급 사례 001] 예산은 계획이다.'),
      '예산은 계획이다.',
    );
    expect(
      stripQuizMetadataPrefix("'보험수익자'의 뜻은? (난이도 1 사례 90)"),
      "'보험수익자'의 뜻은?",
    );
    expect(
      stripQuizMetadataPrefix('예산은 계획이다. (1번째 사례)'),
      '예산은 계획이다.',
    );
    expect(stripQuizMetadataPrefix('금리(연 3%)는 얼마?'), '금리(연 3%)는 얼마?');
    // 수식으로 시작하는 해설(stock_1401 등)은 그대로 둔다.
    expect(
      stripQuizMetadataPrefix('[(1+r1)(1+r2)]^(1/2)-1≈3.92%이다.'),
      '[(1+r1)(1+r2)]^(1/2)-1≈3.92%이다.',
    );
  });
}
