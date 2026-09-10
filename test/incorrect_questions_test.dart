import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/utils/incorrect_questions.dart';

void main() {
  test('첫 오답은 고유 개수를 올리고 반복 오답은 그대로 둔다', () {
    expect(
      nextIncorrectQuestionCount(
        currentCount: 10,
        isCorrect: false,
        alreadyTracked: false,
      ),
      11,
    );
    expect(
      nextIncorrectQuestionCount(
        currentCount: 11,
        isCorrect: false,
        alreadyTracked: true,
      ),
      11,
    );
  });

  test('복습에서 맞추면 오답 목록 개수가 줄어든다', () {
    expect(
      nextIncorrectQuestionCount(
        currentCount: 11,
        isCorrect: true,
        alreadyTracked: true,
      ),
      10,
    );
    expect(
      nextIncorrectQuestionCount(
        currentCount: 0,
        isCorrect: true,
        alreadyTracked: true,
      ),
      0,
    );
    expect(
      nextIncorrectQuestionCount(
        currentCount: 11,
        isCorrect: true,
        alreadyTracked: false,
      ),
      11,
    );
  });
}
