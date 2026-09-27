/// 학습과정 1~10단계 — Firestore `quizQuestions.difficulty`와 1:1 대응.
const int kMinLearningStage = 1;
const int kMaxLearningStage = 10;

enum LearningStageTier {
  beginner('초급'),
  intermediate('중급'),
  advanced('고급');

  const LearningStageTier(this.label);
  final String label;
}

LearningStageTier tierForStage(int stage) {
  final s = stage.clamp(kMinLearningStage, kMaxLearningStage);
  if (s <= 3) return LearningStageTier.beginner;
  if (s <= 7) return LearningStageTier.intermediate;
  return LearningStageTier.advanced;
}

/// 티어별 단계 — 초급 1~3, 중급 4~7, 고급 8~10.
List<int> stagesInTier(LearningStageTier tier) => switch (tier) {
      LearningStageTier.beginner => const [1, 2, 3],
      LearningStageTier.intermediate => const [4, 5, 6, 7],
      LearningStageTier.advanced => const [8, 9, 10],
    };

/// 현재 티어 안에서 몇 단계까지 왔는지 (0~1). 중급 5단계 → 2/4 = 0.5.
double tierProgress(int stage) {
  final s = normalizeLearningStage(stage);
  final stages = stagesInTier(tierForStage(s));
  return (s - stages.first + 1) / stages.length;
}

String learningStageLabel(int stage) {
  final s = stage.clamp(kMinLearningStage, kMaxLearningStage);
  return '${tierForStage(s).label} $s단계';
}

int normalizeLearningStage(int? stage) =>
    (stage ?? kMinLearningStage).clamp(kMinLearningStage, kMaxLearningStage);

/// Firestore `learningStage` — int·double·문자열 모두 허용.
int? readLearningStageField(Object? raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}
