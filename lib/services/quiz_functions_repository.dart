import 'package:cloud_functions/cloud_functions.dart';

import '../models/quiz_question.dart';
import '../models/quiz_session.dart';

/// Cloud Functions — submitAnswer · completeSession
class QuizFunctionsRepository {
  QuizFunctionsRepository._();

  static final instance = QuizFunctionsRepository._();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  Future<SubmitAnswerResult> submitAnswer({
    required String sessionId,
    required String questionId,
    required int selectedIndex,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitAnswer');
      final response = await callable.call<Map<String, dynamic>>({
        'sessionId': sessionId,
        'questionId': questionId,
        'selectedIndex': selectedIndex,
      });
      final data = response.data;
      return SubmitAnswerResult(
        isCorrect: data['isCorrect'] as bool? ?? false,
        correctIndex: (data['correctIndex'] as num?)?.toInt() ?? 0,
        energyRemaining: (data['energyRemaining'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      throw QuizSessionException(_functionsErrorMessage(e, '답안 제출에 실패했어요.'));
    } catch (e) {
      throw QuizSessionException('답안 제출에 실패했어요. Cloud Functions 배포·설정을 확인해 주세요.');
    }
  }

  Future<QuizSessionResult> completeSession({
    required String sessionId,
  }) async {
    try {
      final callable = _functions.httpsCallable('completeSession');
      final response = await callable.call<Map<String, dynamic>>({
        'sessionId': sessionId,
      });
      final data = response.data;

      final answersRaw = (data['answers'] as List? ?? [])
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e));

      return QuizSessionResult(
        answers: answersRaw
            .map(
              (a) => QuizAnswer(
                questionId: a['questionId'] as String,
                selectedIndex: (a['selectedIndex'] as num).toInt(),
                isCorrect: a['isCorrect'] as bool? ?? false,
              ),
            )
            .toList(),
        xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
        seedsEarned: (data['seedsEarned'] as num?)?.toInt() ?? 0,
        leveledUp: data['leveledUp'] as bool? ?? false,
        newLevel: (data['newLevel'] as num?)?.toInt() ?? 1,
        previousLevel: (data['previousLevel'] as num?)?.toInt() ?? 1,
        unlockedItems: List<String>.from(data['unlockedItems'] as List? ?? []),
        newStreak: (data['newStreak'] as num?)?.toInt() ?? 0,
        energyRemaining: (data['energyRemaining'] as num?)?.toInt(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw QuizSessionException(_functionsErrorMessage(e, '세션 완료 처리에 실패했어요.'));
    } catch (e) {
      throw QuizSessionException('세션 완료에 실패했어요. Cloud Functions 배포·설정을 확인해 주세요.');
    }
  }

  String _functionsErrorMessage(FirebaseFunctionsException e, String fallback) {
    final detail = e.message?.trim();
    if (detail != null && detail.isNotEmpty && detail != 'internal') {
      return detail;
    }
    if (e.code == 'unavailable' || e.code == 'internal') {
      return '$fallback (Functions 연결 실패 — firebase deploy --only functions 후 cloudFunctions 전환)';
    }
    return fallback;
  }
}
