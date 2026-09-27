import 'package:firebase_core/firebase_core.dart';

import '../utils/incorrect_questions.dart';

/// 카테고리별 오답 수 맵(`users.incorrectQuestionCounts`)이 없는 예전 계정을
/// `incorrectQuestions` 문서로 채운다.
///
/// - 맵이 저장된 것을 한 번 확인한 계정은 이 세션 동안 다시 읽지 않는다.
/// - 클라이언트가 쓸 수 없는 모드(프로덕션 규칙)에서는 저장을 시도하지 않고
///   집계값을 기억해 둔다. 맵은 첫 제출 때 Functions가 저장한다.
class IncorrectQuestionCountsBackfill {
  IncorrectQuestionCountsBackfill({
    required this.loadIncorrectDocs,
    required this.storeIfMissing,
    required this.canWrite,
  });

  /// `users/{uid}/incorrectQuestions` 문서 데이터.
  final Future<List<Map<String, dynamic>>> Function(String uid)
  loadIncorrectDocs;

  /// 맵이 아직 없을 때만 [counts]를 저장한다. 그 사이 다른 제출이 맵을
  /// 만들었으면 덮어쓰지 않고 저장된 값을 돌려준다.
  final Future<Map<String, int>> Function(String uid, Map<String, int> counts)
  storeIfMissing;

  final bool Function() canWrite;

  final _stored = <String>{};
  final _unsaved = <String, Map<String, int>>{};

  bool isStored(String uid) => _stored.contains(uid);

  /// 사용자 문서에서 맵을 봤을 때 호출한다.
  void markStored(String uid) {
    _stored.add(uid);
    _unsaved.remove(uid);
  }

  Future<Map<String, int>> run(String uid) async {
    final unsaved = _unsaved[uid];
    if (unsaved != null) return Map.of(unsaved);

    final counts = aggregateIncorrectQuestionCounts(
      await loadIncorrectDocs(uid),
    );
    if (!canWrite()) {
      _unsaved[uid] = counts;
      return Map.of(counts);
    }

    try {
      final stored = await storeIfMissing(uid, counts);
      markStored(uid);
      return stored;
    } on FirebaseException {
      // 저장이 거절돼도 화면에는 집계값을 쓴다. 다음 호출에서 다시 시도한다.
      return counts;
    }
  }
}
