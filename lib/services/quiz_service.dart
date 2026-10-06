import 'package:flutter/foundation.dart'
    show kDebugMode, debugPrint, visibleForTesting;

import '../config/quiz_backend_config.dart';
import '../models/quiz_question.dart';
import '../models/quiz_session.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';
import 'friend_service.dart';
import 'quiz_functions_repository.dart';
import 'quiz_session_repository.dart';

class QuizService {
  QuizService._();
  static final instance = QuizService._();

  /// Firestore `quizQuestions` + `mastered` 기반 유저별 10문항 세션.
  Future<QuizSession> startSession({required UserProfile profile}) {
    return QuizSessionRepository.instance.startSession(profile: profile);
  }

  /// 저장된 오답에서 최대 10문항을 다시 출제한다.
  Future<QuizSession> startReviewSession({required UserProfile profile}) {
    return QuizSessionRepository.instance.startReviewSession(profile: profile);
  }

  /// 채점 · answers · mastered · energy 차감.
  /// 백엔드: [QuizBackendConfig.submitBackend]
  Future<SubmitAnswerResult> submitAnswer({
    required String sessionId,
    required String questionId,
    required int selectedIndex,
    required UserProfile profile,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'Quiz submit backend: ${QuizBackendConfig.submitBackend.name}',
      );
    }
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
    profile.energy = result.energyRemaining;
    return result;
  }

  /// 끝까지 풀지 않고 나간 세션을 닫는다. 그 세션에서 푼 문제는 안 푼 문제로
  /// 남고, 쓴 에너지는 돌려받는다.
  Future<void> abandonSession({
    required UserProfile profile,
    required String sessionId,
  }) async {
    final energy = QuizBackendConfig.usesCloudFunctions
        ? await QuizFunctionsRepository.instance.abandonSession(
            sessionId: sessionId,
          )
        : await QuizSessionRepository.instance.abandonSession(
            sessionId: sessionId,
          );
    if (energy != null) {
      profile.energy = energy;
    }
  }

  /// 앱이 종료돼 닫지 못한 세션을 닫고 에너지를 돌려받는다.
  /// 실패해도 학습 시작은 막지 않는다 — 다음 시작에서 다시 시도한다.
  Future<void> abandonOpenSessions({required UserProfile profile}) {
    return closeOpenSessions(
      // 저장소 생성(Firebase 초기화) 오류도 closeOpenSessions가 잡도록 호출을 미룬다.
      openSessionIds: () => QuizSessionRepository.instance.openSessionIds(),
      abandon: (id) => abandonSession(profile: profile, sessionId: id),
    );
  }

  /// 씨앗 · streak · categoryStats · 세션 completed.
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
      profile.energy = result.energyRemaining!;
    }

    // 친구 경쟁 순위에 오늘 학습이 바로 보이도록. 실패해도 결과 화면은 막지 않는다.
    try {
      await FriendService.instance.publishMyStreak();
    } catch (e) {
      if (kDebugMode) debugPrint('Streak publish failed: $e');
    }

    return result;
  }

  void _syncProfile(UserProfile target, UserProfile source) {
    target.streak = source.streak;
    target.lastQuizCompletedDate = source.lastQuizCompletedDate;
    target.todayQuizCompleted = source.todayQuizCompleted;
    target.energy = source.energy;
    target.lastEnergyResetDate = source.lastEnergyResetDate;
    target.selectedHamsterId = source.selectedHamsterId;
    target.learningDates = List<String>.from(source.learningDates);
    target.categoryStats = Map<String, CategoryStat>.from(source.categoryStats);
    target.incorrectQuestionCounts = Map<String, int>.from(
      source.incorrectQuestionCounts,
    );
    target.incorrectQuestionCount = source.incorrectQuestionCount;
    target.reviewArrivals = Map<String, int>.from(source.reviewArrivals);
    target.seeds = source.seeds;
  }
}

/// 열린 세션을 모두 닫는다. 한 세션을 닫지 못해도 나머지는 계속 닫는다.
@visibleForTesting
Future<void> closeOpenSessions({
  required Future<List<String>> Function() openSessionIds,
  required Future<void> Function(String sessionId) abandon,
}) async {
  final List<String> ids;
  try {
    ids = await openSessionIds();
  } catch (e) {
    if (kDebugMode) debugPrint('Open session lookup failed: $e');
    return;
  }
  for (final id in ids) {
    try {
      await abandon(id);
    } catch (e) {
      if (kDebugMode) debugPrint('Open session cleanup failed ($id): $e');
    }
  }
}
