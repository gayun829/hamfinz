import '../config/quiz_backend_config.dart';
import '../data/quiz_data.dart';
import '../models/quiz_question.dart';
import '../models/quiz_session.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';
import 'quiz_functions_repository.dart';
import 'quiz_session_repository.dart';

class QuizService {
  QuizService._();
  static final instance = QuizService._();

  /// Firestore `quizQuestions` + `mastered` 기반 유저별 10문항 세션.
  Future<QuizSession> startSession({required UserProfile profile}) {
    return QuizSessionRepository.instance.startSession(profile: profile);
  }

  /// 채점 · answers · mastered · energy 차감.
  /// 백엔드: [QuizBackendConfig.submitBackend]
  Future<SubmitAnswerResult> submitAnswer({
    required String sessionId,
    required String questionId,
    required int selectedIndex,
    required UserProfile profile,
  }) async {
    final SubmitAnswerResult result;
    if (QuizBackendConfig.usesCloudFunctions) {
      result = await QuizFunctionsRepository.instance.submitAnswer(
        sessionId: sessionId,
        questionId: questionId,
        selectedIndex: selectedIndex,
      );
    } else {
      result = await QuizSessionRepository.instance.submitAnswer(
        sessionId: sessionId,
        questionId: questionId,
        selectedIndex: selectedIndex,
      );
    }
    profile.energy = result.energyRemaining.clamp(0, QuizData.maxEnergy);
    return result;
  }

  /// XP · 씨앗 · streak · categoryStats · 세션 completed.
  /// 백엔드: [QuizBackendConfig.submitBackend]
  Future<QuizSessionResult> completeSession({
    required UserProfile profile,
    required String sessionId,
  }) async {
    final QuizSessionResult result;
    if (QuizBackendConfig.usesCloudFunctions) {
      result = await QuizFunctionsRepository.instance.completeSession(
        sessionId: sessionId,
      );
    } else {
      result = await QuizSessionRepository.instance.completeSession(
        sessionId: sessionId,
      );
    }

    final refreshed = await AuthService.instance.getCurrentUser();
    if (refreshed != null) {
      _syncProfile(profile, refreshed);
    } else if (result.energyRemaining != null) {
      profile.energy = result.energyRemaining!.clamp(0, QuizData.maxEnergy);
    }

    return result;
  }

  void _syncProfile(UserProfile target, UserProfile source) {
    target.xp = source.xp;
    target.streak = source.streak;
    target.lastQuizCompletedDate = source.lastQuizCompletedDate;
    target.todayQuizCompleted = source.todayQuizCompleted;
    target.energy = source.energy;
    target.lastEnergyResetDate = source.lastEnergyResetDate;
    target.unlockedHamsterIds = List<String>.from(source.unlockedHamsterIds);
    target.selectedHamsterId = source.selectedHamsterId;
    target.learningHistory = List<LearningRecord>.from(source.learningHistory);
    target.categoryStats = Map<String, CategoryStat>.from(source.categoryStats);
    target.seeds = source.seeds;
  }
}
