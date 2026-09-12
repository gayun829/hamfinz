import '../models/quiz_question.dart';
import '../models/user_profile.dart';
import 'interest_categories.dart';
import 'learning_stages.dart';
import 'quiz_data.dart';

/// 카테고리·단계당 문제 풀 크기. 홈 step과는 1:1로 묶지 않는다.
const int kQuestionsPerCategoryStage = 200;

/// 한 학습 세션(10문제) = 홈 맵 1 step.
/// 단계당 20회 × 10단계 = 200.
const int kSessionsPerLearningStage =
    kQuestionsPerCategoryStage ~/ QuizData.dailyQuestionCount;

const int kMaxLearningSteps = kSessionsPerLearningStage * kMaxLearningStage;

int homeMapCurrentStep(UserProfile profile) {
  final id = resolveActiveInterestCategoryId(profile.interestCategories);
  if (id == null) return 1;
  QuizCategory? category;
  for (final value in QuizCategory.values) {
    if (value.name == id) {
      category = value;
      break;
    }
  }
  final sessions =
      profile.categoryStats[category?.label ?? '']?.completedSessions ?? 0;
  return (sessions + 1).clamp(1, kMaxLearningSteps);
}

/// Figma 홈은 1과 3처럼 현재 step과 +2를 같이 보여 준다.
int homeMapUpcomingStep(int currentStep) {
  return (currentStep + 2).clamp(1, kMaxLearningSteps);
}
