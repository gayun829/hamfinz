/// 퀴즈 제출·완료 백엔드 모드.
///
/// 배포 절차: [docs/quiz-production-deployment.md](../../docs/quiz-production-deployment.md)
enum QuizSubmitBackend {
  /// 개발 — Blaze 없이 Firestore 클라이언트 트랜잭션 (`firestore.rules`)
  clientTransaction,

  /// 배포 — Cloud Functions Callable + Admin SDK (`firestore.rules.production`)
  cloudFunctions,
}

/// 퀴즈 §3(submitAnswer · completeSession) 백엔드 전환 설정.
///
/// **배포 전** [QuizSubmitBackend.cloudFunctions] 로 변경하고
/// [docs/quiz-production-deployment.md] 체크리스트를 따른다.
class QuizBackendConfig {
  QuizBackendConfig._();

  /// 제출·세션 완료 구현 선택. `QuizService`가 이 값으로 라우팅한다.
  static const submitBackend = QuizSubmitBackend.clientTransaction;

  static bool get usesClientTransaction =>
      submitBackend == QuizSubmitBackend.clientTransaction;

  static bool get usesCloudFunctions =>
      submitBackend == QuizSubmitBackend.cloudFunctions;
}
