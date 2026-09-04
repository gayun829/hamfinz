/// 퀴즈 세션 상수. 문제 본문은 Firestore `quizQuestions`에서만 읽는다.
class QuizData {
  QuizData._();

  static const int dailyQuestionCount = 10;
  static const int correctXp = 10;
  static const int wrongXp = 2;

  /// 정답 1개당 지급하는 해바라기씨.
  static const int seedsPerCorrect = 5;

  /// 에너지 최대치. 하루가 바뀌면 이 값으로 회복한다.
  static const int maxEnergy = 100;

  /// 문제 1개 제출 시 소모하는 에너지 (잠정 — 변동 가능).
  static const int energyCostPerQuestion = 5;

  /// 한 학습 세션(10문제) 시작에 필요한 에너지.
  static const int sessionEnergyCost =
      dailyQuestionCount * energyCostPerQuestion;
}
