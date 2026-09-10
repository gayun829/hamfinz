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
