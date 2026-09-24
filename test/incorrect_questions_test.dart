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

  test('복습 출제는 categoryId가 없는 예전 오답을 용돈 관리로 본다', () {
    expect(incorrectQuestionCategoryId(const {'categoryId': 'stock'}), 'stock');
    expect(incorrectQuestionCategoryId(const {}), 'allowance');
    expect(
      aggregateIncorrectQuestionCounts(const [
        {'categoryId': 'stock'},
        {},
      ]),
      {'stock': 1, 'allowance': 1},
    );
    expect(aggregateIncorrectQuestionCounts(const []), isEmpty);
  });

  test('삭제·비활성화되었거나 카테고리가 바뀐 문제는 복습에 내지 않는다', () {
    expect(
      isReviewableQuestion(const {
        'isActive': true,
        'categoryId': 'saving',
      }, 'saving'),
      isTrue,
    );
    expect(
      isReviewableQuestion(const {
        'isActive': false,
        'categoryId': 'saving',
      }, 'saving'),
      isFalse,
    );
    expect(isReviewableQuestion(null, 'saving'), isFalse);
    expect(
      isReviewableQuestion(const {
        'isActive': true,
        'categoryId': 'stock',
      }, 'saving'),
      isFalse,
    );
  });

  test('정리 후 복습 기준 아래로 내려가면 복습 홈이 풀린다', () {
    final profile = UserProfile(
      email: 'review@test.dev',
      nickname: '복습',
      interestCategories: const ['saving'],
      incorrectQuestionCounts: const {'saving': 11, 'stock': 2},
      incorrectQuestionCount: 13,
    );
    expect(activeCategoryNeedsReview(profile), isTrue);

    // 11개 중 1개가 비활성화돼 복습할 수 없으면 10개로 다시 센다.
    profile.incorrectQuestionCounts = withCategoryIncorrectCount(
      profile.incorrectQuestionCounts,
      'saving',
      10,
    );
    expect(profile.incorrectQuestionCounts, {'saving': 10, 'stock': 2});
    expect(activeCategoryNeedsReview(profile), isFalse);

    expect(
      withCategoryIncorrectCount(const {'saving': 3}, 'saving', 0),
      isEmpty,
    );
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
