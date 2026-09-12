import '../models/user_profile.dart';

class HamsterData {
  static const items = <HamsterItem>[
    HamsterItem(
      id: 'hamster_basic',
      name: '기본 햄스터',
      emoji: '🐹',
    ),
    HamsterItem(
      id: 'hamster_study',
      name: '공부 햄스터',
      emoji: '📚',
    ),
    HamsterItem(
      id: 'hamster_streak',
      name: '불꽃 햄스터',
      emoji: '🔥',
    ),
    HamsterItem(
      id: 'hamster_level3',
      name: '저축 햄스터',
      emoji: '💰',
    ),
    HamsterItem(
      id: 'hamster_level5',
      name: '중수 햄스터',
      emoji: '🎓',
    ),
    HamsterItem(
      id: 'hamster_master',
      name: '고수 햄스터',
      emoji: '👑',
    ),
  ];

  static HamsterItem? findById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
