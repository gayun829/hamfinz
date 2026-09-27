import '../data/interest_categories.dart';
import '../data/learning_steps.dart';
import '../data/quiz_data.dart';
import '../models/user_profile.dart';

/// 카테고리별 고유 오답 수 갱신 규칙.
///
/// 같은 문제는 `incorrectQuestions/{questionId}` 문서 하나로 추적하고,
/// 개수는 `users/{uid}.incorrectQuestionCounts.{categoryId}`에 둔다.
int nextIncorrectQuestionCount({
  required int currentCount,
  required bool isCorrect,
  required bool alreadyTracked,
}) {
  if (isCorrect) {
    if (!alreadyTracked) return currentCount;
    return currentCount > 0 ? currentCount - 1 : 0;
  }
  if (alreadyTracked) return currentCount;
  return currentCount + 1;
}

Map<String, int> readIncorrectQuestionCounts(Map<String, dynamic>? data) =>
    _readIntMap(data?['incorrectQuestionCounts']);

Map<String, int> readReviewArrivals(Map<String, dynamic>? data) =>
    _readIntMap(data?['reviewArrivals']);

Map<String, int> _readIntMap(Object? raw) {
  if (raw is! Map) return {};
  final counts = <String, int>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is num) counts[entry.key.toString()] = value.toInt();
  }
  return counts;
}

/// 한 문제의 정오답으로 해당 카테고리 개수만 바꾼 맵을 돌려준다.
/// 0이 된 카테고리 키는 뺀다.
Map<String, int> nextIncorrectQuestionCounts({
  required Map<String, int> counts,
  required String categoryId,
  required bool isCorrect,
  required bool alreadyTracked,
}) {
  final next = Map<String, int>.from(counts);
  final updated = nextIncorrectQuestionCount(
    currentCount: next[categoryId] ?? 0,
    isCorrect: isCorrect,
    alreadyTracked: alreadyTracked,
  );
  if (updated <= 0) {
    next.remove(categoryId);
  } else {
    next[categoryId] = updated;
  }
  return next;
}

int totalIncorrectQuestionCount(Map<String, int> counts) =>
    counts.values.fold(0, (sum, value) => sum + value);

/// 예전 오답 문서에는 `categoryId`가 없을 수 있다. 그때는 용돈 관리로 본다.
const legacyIncorrectQuestionCategoryId = 'allowance';

String incorrectQuestionCategoryId(Map<String, dynamic> data) =>
    data['categoryId'] as String? ?? legacyIncorrectQuestionCategoryId;

/// `incorrectQuestions` 문서들을 카테고리별로 센다 (예전 계정 백필용).
Map<String, int> aggregateIncorrectQuestionCounts(
  Iterable<Map<String, dynamic>> docs,
) {
  final counts = <String, int>{};
  for (final data in docs) {
    final categoryId = incorrectQuestionCategoryId(data);
    counts[categoryId] = (counts[categoryId] ?? 0) + 1;
  }
  return counts;
}

/// 세션에서 제출한 답 하나.
typedef SessionAnswer = ({
  String questionId,
  bool isCorrect,
  String categoryId,
});

/// 오답 목록에 새로 넣거나 갱신할 문제.
typedef WrongAnswerPlan = ({
  String questionId,
  String categoryId,
  bool isNew,
  int previousWrongCount,
});

/// 끝까지 푼 세션의 답을 정답(mastered)·오답(incorrectQuestions)에 반영할 계획.
///
/// 세션을 완료할 때만 쓴다 — 중간에 나간 세션의 답은 반영하지 않으므로 그 문제들은
/// 안 푼 문제로 남는다. [trackedById]는 이미 오답 목록에 있는 문제의 오답 문서다.
({
  Map<String, int> counts,
  List<String> masteredIds,
  List<String> removeIds,
  List<WrongAnswerPlan> wrong,
})
planSessionIncorrectQuestions({
  required Map<String, int> counts,
  required List<SessionAnswer> answers,
  required Map<String, Map<String, dynamic>> trackedById,
}) {
  var next = counts;
  final masteredIds = <String>[];
  final removeIds = <String>[];
  final wrong = <WrongAnswerPlan>[];
  for (final answer in answers) {
    final tracked = trackedById[answer.questionId];
    // 이미 오답 목록에 있는 문제는 기록된 카테고리로 센다. 문제의 카테고리가
    // 나중에 바뀌어도 오답 수와 오답 문서가 같은 카테고리에 남아야 한다.
    final categoryId = tracked != null
        ? incorrectQuestionCategoryId(tracked)
        : answer.categoryId;
    next = nextIncorrectQuestionCounts(
      counts: next,
      categoryId: categoryId,
      isCorrect: answer.isCorrect,
      alreadyTracked: tracked != null,
    );
    if (answer.isCorrect) {
      masteredIds.add(answer.questionId);
      if (tracked != null) removeIds.add(answer.questionId);
    } else {
      wrong.add((
        questionId: answer.questionId,
        categoryId: categoryId,
        isNew: tracked == null,
        previousWrongCount: (tracked?['wrongCount'] as num?)?.toInt() ?? 0,
      ));
    }
  }
  return (
    counts: next,
    masteredIds: masteredIds,
    removeIds: removeIds,
    wrong: wrong,
  );
}

/// 복습에 낼 수 있는 문제인지. 삭제·비활성화되었거나 카테고리가 바뀐 문제는
/// 복습에 나오지 않으므로 오답 수에도 남기면 안 된다 (복습 홈에 갇힘).
/// [question]이 null이면 없는 문제(또는 규칙상 읽을 수 없는 비활성 문제)다.
bool isReviewableQuestion(Map<String, dynamic>? question, String categoryId) {
  if (question == null || question['isActive'] != true) return false;
  return incorrectQuestionCategoryId(question) == categoryId;
}

/// [categoryId] 오답 수를 [available]로 맞춘 맵. 0이면 키를 지운다.
Map<String, int> withCategoryIncorrectCount(
  Map<String, int> counts,
  String categoryId,
  int available,
) {
  final next = Map<String, int>.from(counts);
  if (available > 0) {
    next[categoryId] = available;
  } else {
    next.remove(categoryId);
  }
  return next;
}

bool sameIncorrectQuestionCounts(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// 지금 고른 카테고리의 고유 오답이 기준 개수 이상이면 복습 홈을 연다.
bool activeCategoryNeedsReview(UserProfile profile) {
  final categoryId = resolveActiveInterestCategoryId(
    profile.interestCategories,
  );
  if (categoryId == null) return false;
  final count = profile.incorrectQuestionCounts[categoryId] ?? 0;
  return count >= QuizData.reviewQuestionThreshold;
}

/// 복습을 마친 뒤 다음 학습을 끝내기 전까지는 햄핀이가 복습 집에 도착한 홈을 연다.
bool activeCategoryReviewArrived(UserProfile profile) {
  final categoryId = resolveActiveInterestCategoryId(
    profile.interestCategories,
  );
  if (categoryId == null || activeCategoryNeedsReview(profile)) return false;
  return profile.reviewArrivals[categoryId] ==
      completedSessionsFor(profile, categoryId);
}
