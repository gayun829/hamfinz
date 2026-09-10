import 'quiz_question.dart';

/// 학습용 문제 — `correctIndex` 미포함 (UI·네트워크 노출 방지).
class QuizQuestionLearning {
  const QuizQuestionLearning({
    required this.id,
    required this.type,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.explanation,
  });

  final String id;
  final QuizType type;
  final QuizCategory category;
  final int difficulty;
  final String question;
  final List<String> options;
  final String explanation;
}

/// `startSession` 결과 — 학습용 문제 목록만 (정답 인덱스 없음).
class QuizSession {
  QuizSession({
    required this.sessionId,
    required this.questions,
    this.source = energySessionSource,
  });

  static const energySessionSource = 'energySession';
  static const reviewSessionSource = 'reviewSession';

  final String sessionId;
  final List<QuizQuestionLearning> questions;
  final String source;

  int get questionCount => questions.length;

  bool get isReview => source == reviewSessionSource;
}

/// `submitAnswer` 서버 응답.
class SubmitAnswerResult {
  const SubmitAnswerResult({
    required this.isCorrect,
    required this.correctIndex,
    required this.energyRemaining,
  });

  final bool isCorrect;
  final int correctIndex;
  final int energyRemaining;
}

class QuizSessionException implements Exception {
  QuizSessionException(this.message);

  final String message;

  @override
  String toString() => message;
}
