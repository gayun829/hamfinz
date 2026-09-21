import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/services/auth_service.dart';

void main() {
  test('클라이언트 저장은 퀴즈가 쓰는 필드를 덮지 않는다', () {
    final profile = UserProfile(
      email: 'a@b.com',
      nickname: '햄찌',
      streak: 4,
      energy: 30,
      seeds: 12,
      incorrectQuestionCount: 11,
      selectedHamsterId: 'hamster_streak',
    );

    final json = AuthService.clientOwnedJson(profile);

    // 아래 필드는 퀴즈 트랜잭션·Functions(학습 기록 등) 또는 상점 구매(seeds 등)만 쓴다.
    // 여기 섞이면 진행도·재화가 되돌아간다.
    for (final key in [
      'streak',
      'energy',
      'lastEnergyResetDate',
      'lastQuizCompletedDate',
      'todayQuizCompleted',
      'learningDates',
      'categoryStats',
      'incorrectQuestionCount',
      'seeds',
      'ownedShopItemIds',
      'studyGuardCount',
    ]) {
      expect(json.containsKey(key), isFalse, reason: key);
    }

    expect(json['nickname'], '햄찌');
    expect(json['selectedHamsterId'], 'hamster_streak');
  });
}
