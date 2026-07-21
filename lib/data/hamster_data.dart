import '../models/user_profile.dart';

class HamsterData {
  static const items = <HamsterItem>[
    HamsterItem(
      id: 'hamster_basic',
      name: '기본 햄스터',
      emoji: '🐹',
      unlockDescription: '회원가입 시 기본 제공',
    ),
    HamsterItem(
      id: 'hamster_study',
      name: '공부 햄스터',
      emoji: '📚',
      unlockDescription: '첫 퀴즈 완료 시 획득',
    ),
    HamsterItem(
      id: 'hamster_streak',
      name: '불꽃 햄스터',
      emoji: '🔥',
      unlockDescription: '3일 연속 학습 달성',
    ),
    HamsterItem(
      id: 'hamster_level3',
      name: '저축 햄스터',
      emoji: '💰',
      unlockDescription: '레벨 3 달성',
    ),
    HamsterItem(
      id: 'hamster_level5',
      name: '중수 햄스터',
      emoji: '🎓',
      unlockDescription: '레벨 5 달성',
    ),
    HamsterItem(
      id: 'hamster_master',
      name: '고수 햄스터',
      emoji: '👑',
      unlockDescription: '레벨 10 달성',
    ),
  ];

  static HamsterItem? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
