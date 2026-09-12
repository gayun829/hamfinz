class UserProfile {
  UserProfile({
    required this.email,
    required this.nickname,
    this.bio = '',
    this.xp = 0,
    this.streak = 0,
    this.lastQuizCompletedDate,
    this.todayQuizCompleted = false,
    this.energy = 100,
    this.lastEnergyResetDate,
    this.unlockedHamsterIds = const ['hamster_basic'],
    this.selectedHamsterId = 'hamster_basic',
    this.learningHistory = const [],
    this.categoryStats = const {},
    this.interestCategories = const [],
    this.learningStage = 1,
    this.incorrectQuestionCount = 0,
    this.seeds = 0,
    this.ownedShopItemIds = const [],
    this.studyGuardCount = 0,
    this.equippedSkinId,
    this.equippedPatternId,
    this.equippedBackgroundId,
    this.equippedAccessoryIds = const [],
  });

  final String email;
  final String nickname;

  /// 마이페이지 한줄소개. [AuthService.updateBio]로만 저장한다.
  String bio;
  int xp;
  int streak;
  String? lastQuizCompletedDate;
  bool todayQuizCompleted;

  /// 학습에 쓰는 에너지. 문제 1개당 10 소모 (최대 100).
  int energy;
  String? lastEnergyResetDate;

  List<String> unlockedHamsterIds;
  String selectedHamsterId;
  List<LearningRecord> learningHistory;
  Map<String, CategoryStat> categoryStats;

  /// 현재 학습 카테고리 id (1개).
  /// QuizCategory enum의 name과 동일한 문자열을 저장한다.
  /// (allowance / saving / stock / insurance / tax / credit)
  List<String> interestCategories;

  /// 학습과정 1~10 — `quizQuestions.difficulty`와 동일.
  int learningStage;

  /// `users/{uid}/incorrectQuestions`에 저장된 고유 오답 문제 수.
  int incorrectQuestionCount;

  /// 상점 해바라기씨 잔액.
  int seeds;

  /// 상점에서 구매한 아이템 id 목록.
  List<String> ownedShopItemIds;

  /// 연속 학습 방어권 보유 개수 (최대 3)
  int studyGuardCount;

  /// 현재 프로필에 장착된 스킨/패턴/배경/악세서리 id들 (저장된 상태)
  String? equippedSkinId;
  String? equippedPatternId;
  String? equippedBackgroundId;
  List<String> equippedAccessoryIds;

  int get level => LevelUtils.levelFromXp(xp);
  String get levelTitle => LevelUtils.titleForLevel(level);
  double get levelProgress => LevelUtils.progressInLevel(xp);
  int get xpForNextLevel => LevelUtils.xpForNextLevel(xp);
  int get xpInCurrentLevel => LevelUtils.xpInCurrentLevel(xp);
}

class LearningRecord {
  LearningRecord({
    required this.date,
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
  });

  final String date;
  final int correctCount;
  final int totalCount;
  final int xpEarned;

  Map<String, dynamic> toJson() => {
    'date': date,
    'correctCount': correctCount,
    'totalCount': totalCount,
    'xpEarned': xpEarned,
  };

  factory LearningRecord.fromJson(Map<String, dynamic> json) => LearningRecord(
    date: json['date'] as String,
    correctCount: json['correctCount'] as int,
    totalCount: json['totalCount'] as int,
    xpEarned: json['xpEarned'] as int,
  );
}

class CategoryStat {
  CategoryStat({this.correct = 0, this.total = 0, this.completedSessions = 0});

  int correct;
  int total;

  /// 에너지 학습 세션 완료 횟수. 홈 맵 step(1~200)의 기준.
  int completedSessions;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
    'correct': correct,
    'total': total,
    'completedSessions': completedSessions,
  };

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
    correct: json['correct'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
    completedSessions: (json['completedSessions'] as num?)?.toInt() ?? 0,
  );
}

class HamsterItem {
  const HamsterItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.unlockDescription,
  });

  final String id;
  final String name;
  final String emoji;
  final String unlockDescription;
}

class LevelUtils {
  static const int maxLevel = 10;
  static const int xpPerLevel = 100;

  static int levelFromXp(int xp) {
    final level = (xp ~/ xpPerLevel) + 1;
    return level.clamp(1, maxLevel);
  }

  static int xpInCurrentLevel(int xp) => xp % xpPerLevel;

  static int xpForNextLevel(int xp) => xpPerLevel - xpInCurrentLevel(xp);

  static double progressInLevel(int xp) => xpInCurrentLevel(xp) / xpPerLevel;

  static String titleForLevel(int level) {
    switch (level) {
      case 1:
        return '금융 새싹';
      case 2:
        return '용돈 관리생';
      case 3:
        return '저축 입문자';
      case 4:
        return '금융 탐험가';
      case 5:
        return '금융 중수';
      case 6:
        return '재테크 학습자';
      case 7:
        return '금융 실무자';
      case 8:
        return '재무 전략가';
      case 9:
        return '금융 멘토';
      case 10:
        return '금융 고수';
      default:
        return '금융 새싹';
    }
  }
}
