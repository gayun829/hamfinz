/// 연속학습 캘린더 프론트 목업. DB 연동 전 화면 확인용.
abstract final class StreakCalendarMock {
  /// Figma 예시: 4/14–4/19 연속 학습.
  static final completedDays = <DateTime>{
    DateTime(2025, 4, 14),
    DateTime(2025, 4, 15),
    DateTime(2025, 4, 16),
    DateTime(2025, 4, 17),
    DateTime(2025, 4, 18),
    DateTime(2025, 4, 19),
  };

  static const friends = <StreakFriendMock>[
    StreakFriendMock(
      rank: 1,
      name: '김기니니',
      learned: 15,
      goal: 15,
      spriteCol: 4,
      spriteRow: 2,
    ),
    StreakFriendMock(
      rank: 2,
      name: '2위',
      learned: 7,
      goal: 15,
      spriteCol: 5,
      spriteRow: 0,
    ),
    StreakFriendMock(
      rank: 3,
      name: '3위',
      learned: 3,
      goal: 15,
      spriteCol: 1,
      spriteRow: 0,
    ),
    StreakFriendMock(
      rank: 4,
      name: '',
      learned: 1,
      goal: 15,
      spriteCol: 0,
      spriteRow: 2,
    ),
  ];
}

class StreakFriendMock {
  const StreakFriendMock({
    required this.rank,
    required this.name,
    required this.learned,
    required this.goal,
    required this.spriteCol,
    required this.spriteRow,
  });

  final int rank;
  final String name;
  final int learned;
  final int goal;
  final int spriteCol;
  final int spriteRow;
}
