class UserProfile {
  UserProfile({
    required this.email,
    required this.nickname,
    this.xp = 0,
    this.streak = 0,
    this.lastQuizCompletedDate,
    this.todayQuizCompleted = false,
    this.unlockedHamsterIds = const ['hamster_basic'],
    this.selectedHamsterId = 'hamster_basic',
    this.learningHistory = const [],
    this.categoryStats = const {},
  });

  final String email;
  final String nickname;
  int xp;
  int streak;
  String? lastQuizCompletedDate;
  bool todayQuizCompleted;
  List<String> unlockedHamsterIds;
  String selectedHamsterId;
  List<LearningRecord> learningHistory;
  Map<String, CategoryStat> categoryStats;

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
  CategoryStat({this.correct = 0, this.total = 0});

  int correct;
  int total;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {'correct': correct, 'total': total};

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        correct: json['correct'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
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
