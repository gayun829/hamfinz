import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/user_profile.dart';
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

  test('오답 수는 문제를 틀린 카테고리만 바뀐다', () {
    final next = nextIncorrectQuestionCounts(
      counts: const {'saving': 11, 'stock': 2},
      categoryId: 'stock',
      isCorrect: false,
      alreadyTracked: false,
    );

    expect(next, {'saving': 11, 'stock': 3});
    expect(totalIncorrectQuestionCount(next), 14);
  });

  test('복습 정답은 그 카테고리 오답만 줄이고 0이면 키를 지운다', () {
    final next = nextIncorrectQuestionCounts(
      counts: const {'saving': 11, 'stock': 1},
      categoryId: 'stock',
      isCorrect: true,
      alreadyTracked: true,
    );

    expect(next, {'saving': 11});
    expect(next.containsKey('stock'), isFalse);
  });

  test('복습 홈은 지금 고른 카테고리의 오답 수로만 열린다', () {
    final profile = UserProfile(
      email: 'review@test.dev',
      nickname: '복습',
      interestCategories: const ['stock'],
      incorrectQuestionCounts: const {'saving': 11, 'stock': 2},
      incorrectQuestionCount: 13,
    );

    expect(activeCategoryNeedsReview(profile), isFalse);

    profile.interestCategories = const ['saving'];
    expect(activeCategoryNeedsReview(profile), isTrue);
  });
}
