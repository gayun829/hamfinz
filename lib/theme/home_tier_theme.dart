import 'package:flutter/material.dart';

import '../data/learning_stages.dart';

/// Figma 홈 화면 티어 — `526:2699` 초급 / `526:1740` 중급 / `526:1936` 고급.
enum HomeTier {
  beginner,
  intermediate,
  advanced;

  static HomeTier forStage(int stage) {
    switch (tierForStage(stage)) {
      case LearningStageTier.beginner:
        return HomeTier.beginner;
      case LearningStageTier.intermediate:
        return HomeTier.intermediate;
      case LearningStageTier.advanced:
        return HomeTier.advanced;
    }
  }
}

/// 학습과정 티어별 색상·에셋 경로.
class HomeTierTheme {
  const HomeTierTheme._({
    required this.tier,
    required this.assetFolder,
    required this.learningCtaColor,
    required this.reviewAheadShadowColor,
    required this.reviewArrivalShadowColor,
    required this.learningCtaLeft,
    required this.learningCtaTop,
    required this.hasLearningCtaShadow,
    required this.platformShadow,
    required this.hamsterSeat,
    required this.hamsterSeatTop,
    required this.node1Fill,
    required this.node1Shadow,
    required this.node3Fill,
    required this.node3Shadow,
    required this.starOuter,
    required this.starMid,
    required this.starTiny,
    required this.sparkle,
    required this.node1LabelShadow,
    required this.node3LabelShadow,
    required this.backgroundBottom,
  });

  final HomeTier tier;
  final String assetFolder;
  final Color learningCtaColor;

  /// 복습 집(Ellipse 218/219) 아래 multiply 그림자.
  final Color reviewAheadShadowColor;

  /// 복습 집에 도착한 햄핀이(Ellipse 217) 아래 그림자.
  final Color reviewArrivalShadowColor;
  final double learningCtaLeft;
  final double learningCtaTop;
  final bool hasLearningCtaShadow;

  /// Ellipse 156/157 — 맵 발판의 아래쪽 두께.
  final Color platformShadow;

  /// Ellipse 100 — 햄스터 자리 아랫면(3D 두께).
  final Color hamsterSeat;

  /// Subtract 166×53 — 햄스터 자리 윗면 크레센트.
  final Color hamsterSeatTop;

  /// 회전 전 Vector 오각형 채움·box-shadow.
  final Color node1Fill;
  final Color node1Shadow;
  final Color node3Fill;
  final Color node3Shadow;
  final Color starOuter;
  final Color starMid;
  final Color starTiny;
  final Color sparkle;
  final Color node1LabelShadow;
  final Color node3LabelShadow;

  /// 홈 배경 그라데이션(#FBFBFB 27.758% → 이 색 115.61%)의 끝색.
  final Color backgroundBottom;

  static const beginner = HomeTierTheme._(
    tier: HomeTier.beginner,
    assetFolder: 'beginner',
    learningCtaColor: Color(0xFF3CC6FF),
    reviewAheadShadowColor: Color(0xFFF7F4D9),
    reviewArrivalShadowColor: Color(0xFFF2EFDF),
    learningCtaLeft: 34,
    learningCtaTop: 666,
    hasLearningCtaShadow: false,
    platformShadow: Color(0xFFF5BE67),
    hamsterSeat: Color(0xFF754C24),
    hamsterSeatTop: Color(0xFFEE9841),
    node1Fill: Color(0xFFFFDA89),
    node1Shadow: Color(0xFFF5BE67),
    node3Fill: Color(0xFFFFD579),
    node3Shadow: Color(0xFFF6B246),
    starOuter: Color.fromRGBO(249, 224, 141, 0.74),
    starMid: Color(0xFFFDD47C),
    starTiny: Color(0xFFF9E08D),
    sparkle: Color.fromRGBO(249, 224, 141, 0.72),
    node1LabelShadow: Color.fromRGBO(205, 85, 0, 0.25),
    node3LabelShadow: Color.fromRGBO(205, 85, 0, 0.25),
    backgroundBottom: Color(0xFFFFFCC7),
  );

  static const intermediate = HomeTierTheme._(
    tier: HomeTier.intermediate,
    assetFolder: 'intermediate',
    learningCtaColor: Color(0xFFB3EA70),
    reviewAheadShadowColor: Color(0xFFF7F4D9),
    reviewArrivalShadowColor: Color(0xFFE3EDE1),
    learningCtaLeft: 32,
    learningCtaTop: 665,
    hasLearningCtaShadow: true,
    platformShadow: Color(0xFFA6D46E),
    hamsterSeat: Color(0xFF667850),
    hamsterSeatTop: Color(0xFFA6D46E),
    node1Fill: Color(0xFFC7EE97),
    node1Shadow: Color(0xFFB1D883),
    node3Fill: Color(0xFFB5EB72),
    node3Shadow: Color(0xFF9BC964),
    starOuter: Color.fromRGBO(199, 238, 151, 0.74),
    starMid: Color(0xFFAFE66D),
    starTiny: Color(0xFFC7EE97),
    sparkle: Color.fromRGBO(199, 238, 151, 0.72),
    node1LabelShadow: Color(0xFFB1D883),
    node3LabelShadow: Color(0xFF9BC964),
    backgroundBottom: Color(0xFFDEFFC4),
  );

  static const advanced = HomeTierTheme._(
    tier: HomeTier.advanced,
    assetFolder: 'advanced',
    learningCtaColor: Color(0xFFFD9068),
    reviewAheadShadowColor: Color(0xFFFFF2ED),
    reviewArrivalShadowColor: Color(0xFFF4E1E1),
    learningCtaLeft: 32,
    learningCtaTop: 665,
    hasLearningCtaShadow: true,
    platformShadow: Color(0xFFFD9068),
    hamsterSeat: Color(0xFF8F5C49),
    hamsterSeatTop: Color(0xFFFD9068),
    node1Fill: Color(0xFFFFBCA4),
    node1Shadow: Color(0xFFFD9068),
    node3Fill: Color(0xFFFFB194),
    node3Shadow: Color(0xFFF5835A),
    starOuter: Color.fromRGBO(255, 193, 170, 0.74),
    starMid: Color(0xFFFDB094),
    starTiny: Color(0xFFFFC1AA),
    sparkle: Color.fromRGBO(255, 193, 170, 0.71),
    node1LabelShadow: Color(0xFFFD9068),
    node3LabelShadow: Color(0xFFF5835A),
    backgroundBottom: Color(0xFFFFDBC4),
  );

  static HomeTierTheme forStage(int stage) {
    switch (HomeTier.forStage(stage)) {
      case HomeTier.beginner:
        return beginner;
      case HomeTier.intermediate:
        return intermediate;
      case HomeTier.advanced:
        return advanced;
    }
  }

  String _asset(String file) => 'assets/figma/home/$assetFolder/$file';

  String get pathMap => _asset('path_map.svg');
  String get hamsterMap => _asset('hamster_map.svg');
  String get ellipse154 => _asset('ellipse_154.svg');
  String get ellipse155 => _asset('ellipse_155.svg');
  String get learningQ => _asset('learning_q.svg');
  String get chevronLearning => _asset('chevron_learning.svg');
  String get reviewHouseBody => _asset('review_house_body.svg');
  String get reviewHouseDot => _asset('review_house_dot.svg');
  String get reviewHouseRoof => _asset('review_house_roof.svg');
  String get reviewArrivalHat => _asset('review_arrival_hat.svg');
  String get reviewArrivalHouse => _asset('review_arrival_house.svg');

  /// 초급·중급은 구멍에서 고개를 내민 햄스터, 고급은 몸통이 보이는 [hamsterMap].
  bool get usesPeekHamster => tier != HomeTier.advanced;
}
