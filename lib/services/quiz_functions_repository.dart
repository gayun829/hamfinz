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
      throw QuizSessionException(
        '답안 제출에 실패했어요. Cloud Functions 배포·설정을 확인해 주세요.',
      );
    }
  }

  /// 끝까지 풀지 않고 나간 세션을 닫고 쓴 에너지를 돌려받는다.
  /// 돌려준 뒤의 에너지를 반환한다.
  Future<int?> abandonSession({required String sessionId}) async {
    try {
      final response = await _functions
          .httpsCallable('abandonSession')
          .call<Map<String, dynamic>>({'sessionId': sessionId});
      return (response.data['energyRemaining'] as num?)?.toInt();
    } on FirebaseFunctionsException catch (e) {
      throw QuizSessionException(_functionsErrorMessage(e, '학습 종료 처리에 실패했어요.'));
    }
  }

  /// 오답 수를 복습할 수 있는 문서 수로 다시 세고, 문제가 삭제된 오답 문서를
  /// 지운다. 다시 센 오답 수를 반환한다.
  /// 오류는 그대로 던진다 — 호출하는 쪽이 복습 시작을 막지 않도록 처리한다.
  Future<int?> reconcileIncorrectQuestions({required String categoryId}) async {
    final response = await _functions
        .httpsCallable('reconcileIncorrectQuestions')
        .call<Map<String, dynamic>>({'categoryId': categoryId});
    return (response.data['available'] as num?)?.toInt();
  }

  Future<QuizSessionResult> completeSession({required String sessionId}) async {
    try {
      final callable = _functions.httpsCallable('completeSession');
      final response = await callable.call<Map<String, dynamic>>({
        'sessionId': sessionId,
      });
      final data = response.data;

      final answersRaw = (data['answers'] as List? ?? []).cast<Map>().map(
        (e) => Map<String, dynamic>.from(e),
      );

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
        seedsEarned: (data['seedsEarned'] as num?)?.toInt() ?? 0,
        newStreak: (data['newStreak'] as num?)?.toInt() ?? 0,
        energyRemaining: (data['energyRemaining'] as num?)?.toInt(),
        energyEarned: (data['energyEarned'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      throw QuizSessionException(_functionsErrorMessage(e, '세션 완료 처리에 실패했어요.'));
    } catch (e) {
      throw QuizSessionException(
        '세션 완료에 실패했어요. Cloud Functions 배포·설정을 확인해 주세요.',
      );
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
