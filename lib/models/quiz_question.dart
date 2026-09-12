enum QuizType { ox, multipleChoice }

enum QuizCategory {
  allowance('용돈 관리'),
  saving('저축'),
  stock('주식 기초'),
  insurance('보험'),
  tax('세금'),
  credit('신용');

  const QuizCategory(this.label);
  final String label;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final QuizType type;
  final QuizCategory category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;
}

class QuizAnswer {
  const QuizAnswer({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
  });

  final String questionId;
  final int selectedIndex;
  final bool isCorrect;
}

class QuizSessionResult {
  const QuizSessionResult({
    required this.answers,
    required this.xpEarned,
    required this.seedsEarned,
    required this.leveledUp,
    required this.newLevel,
    required this.previousLevel,
    required this.unlockedItems,
    required this.newStreak,
    this.energyRemaining,
    this.energyEarned = 0,
    this.advancedLearningStage,
  });

  final List<QuizAnswer> answers;
  final int xpEarned;
  final int seedsEarned;
  final bool leveledUp;
  final int newLevel;
  final int previousLevel;
  final List<String> unlockedItems;
  final int newStreak;
  final int? energyRemaining;

  /// 세션 완료 보상으로 실제로 채워진 에너지 (최대치에 걸리면 그만큼 줄어든다).
  final int energyEarned;

  /// 현재 카테고리·단계 문제를 모두 풀어 자동으로 넘어간 학습과정.
  final int? advancedLearningStage;
}
