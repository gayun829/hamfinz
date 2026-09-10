/// `users/{uid}.incorrectQuestionCount` 갱신 규칙.
///
/// 같은 문제는 `incorrectQuestions/{questionId}` 문서 하나로 추적한다.
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
