class UserProfile {
  UserProfile({
    required this.email,
    required this.nickname,
    this.bio = '',
    this.streak = 0,
    this.lastQuizCompletedDate,
    this.todayQuizCompleted = false,
    this.energy = 100,
    this.lastEnergyResetDate,
    this.selectedHamsterId = 'hamster_basic',
    this.learningDates = const [],
    this.categoryStats = const {},
    this.interestCategories = const [],
    this.learningStage = 1,
    this.incorrectQuestionCounts = const {},
    this.incorrectQuestionCount = 0,
    this.reviewArrivals = const {},
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
  int streak;
  String? lastQuizCompletedDate;
  bool todayQuizCompleted;

  /// 학습에 쓰는 에너지. 문제 1개당 10 소모 (최대 100).
  int energy;
  String? lastEnergyResetDate;

  String selectedHamsterId;
  List<String> learningDates;
  Map<String, CategoryStat> categoryStats;

  /// 현재 학습 카테고리 id (1개).
  /// QuizCategory enum의 name과 동일한 문자열을 저장한다.
  /// (allowance / saving / stock / insurance / tax / credit)
  List<String> interestCategories;

  /// 학습과정 1~10 — `quizQuestions.difficulty`와 동일.
  int learningStage;

  /// 카테고리 id별 고유 오답 수. 활성 카테고리가 기준을 넘으면 복습 홈.
  Map<String, int> incorrectQuestionCounts;

  /// [incorrectQuestionCounts]의 합. 복습 여부는 활성 카테고리 개수로 판단한다.
  int incorrectQuestionCount;

  /// 카테고리 id별로 복습을 끝낸 시점의 완료 학습 세션 수.
  /// 다음 학습을 끝내기 전까지 홈에 복습 집에 도착한 햄핀이를 보여 준다.
  Map<String, int> reviewArrivals;

  /// 상점 해바라기씨 잔액.
  int seeds;

  /// 상점에서 구매한 아이템 id 목록.
  List<String> ownedShopItemIds;

  /// 연속 학습 방어권 보유 개수 (최대 4)
  int studyGuardCount;

  /// 현재 프로필에 장착된 스킨/패턴/배경/악세서리 id들 (저장된 상태)
  String? equippedSkinId;
  String? equippedPatternId;
  String? equippedBackgroundId;
  List<String> equippedAccessoryIds;
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
  });

  final String id;
  final String name;
  final String emoji;
}
