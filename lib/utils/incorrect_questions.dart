import '../data/interest_categories.dart';
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

Map<String, int> readIncorrectQuestionCounts(Map<String, dynamic>? data) {
  final raw = data?['incorrectQuestionCounts'];
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

bool sameIncorrectQuestionCounts(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// 지금 고른 카테고리의 고유 오답이 기준을 넘었을 때만 복습 홈을 연다.
bool activeCategoryNeedsReview(UserProfile profile) {
  final categoryId = resolveActiveInterestCategoryId(profile.interestCategories);
  if (categoryId == null) return false;
  final count = profile.incorrectQuestionCounts[categoryId] ?? 0;
  return count > QuizData.reviewQuestionThreshold;
}
