import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 뉴스 용어 퀴즈 보상 — 맞히면 씨앗 +3.
///
/// 홈 퀴즈(`QuizSessionRepository`)처럼 개발은 클라이언트 트랜잭션이고,
/// 배포 Rules(`firestore.rules.production`)는 seeds를 Functions만 쓰게 막아
/// 두었으니 그때는 Callable로 옮겨야 한다.
class NewsQuizRepository {
  NewsQuizRepository._();

  static final instance = NewsQuizRepository._();

  static const seedsPerCorrect = 3;

  /// 같은 용어를 다시 풀어 씨앗을 반복해서 받지 못하게, 앱 실행당 용어별 1회만 준다.
  final _rewarded = <String>{};

  /// 이미 받은 용어인지. 화면에서 `+3` 배지를 보여줄지 정하는 데 쓴다.
  bool isRewarded(String term) => _rewarded.contains(term);

  /// 맞혔을 때 부른다. 실제로 씨앗이 늘었으면 늘어난 양을, 이미 받았거나
  /// 로그인이 없으면 0을 돌려준다. 저장 실패는 조용히 0으로 — 보상은 곁다리라
  /// 퀴즈 화면을 오류로 덮을 이유가 없다.
  Future<int> rewardCorrect(String term) async {
    if (_rewarded.contains(term)) return 0;
    _rewarded.add(term);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 0;
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) return;
        final seeds = (snap.data()?['seeds'] as num?)?.toInt() ?? 0;
        tx.update(userRef, {'seeds': seeds + seedsPerCorrect});
      });
      return seedsPerCorrect;
    } catch (_) {
      _rewarded.remove(term);
      return 0;
    }
  }
}
