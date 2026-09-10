import 'package:flutter/material.dart';

import '../data/learning_stages.dart';

/// Figma 홈 화면 티어 — `131:5278` 초급 / `137:1312` 중급 / `137:1461` 고급.
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
    required this.reviewHouseShadowColor,
    required this.learningCtaLeft,
    required this.learningCtaTop,
    required this.hasLearningCtaShadow,
  });

  final HomeTier tier;
  final String assetFolder;
  final Color learningCtaColor;
  final Color reviewHouseShadowColor;
  final double learningCtaLeft;
  final double learningCtaTop;
  final bool hasLearningCtaShadow;

  static const beginner = HomeTierTheme._(
    tier: HomeTier.beginner,
    assetFolder: 'beginner',
    learningCtaColor: Color(0xFF3CC6FF),
    reviewHouseShadowColor: Color(0xFFF2EFDF),
    learningCtaLeft: 34,
    learningCtaTop: 666,
    hasLearningCtaShadow: false,
  );

  static const intermediate = HomeTierTheme._(
    tier: HomeTier.intermediate,
    assetFolder: 'intermediate',
    learningCtaColor: Color(0xFFB3EA70),
    reviewHouseShadowColor: Color(0xFFE5EFE2),
    learningCtaLeft: 32,
    learningCtaTop: 665,
    hasLearningCtaShadow: true,
  );

  static const advanced = HomeTierTheme._(
    tier: HomeTier.advanced,
    assetFolder: 'advanced',
    learningCtaColor: Color(0xFFFD9068),
    reviewHouseShadowColor: Color(0xFFF8E5E5),
    learningCtaLeft: 32,
    learningCtaTop: 665,
    hasLearningCtaShadow: true,
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
  String get ellipse100 => _asset('ellipse_100.svg');
  String get ellipse154 => _asset('ellipse_154.svg');
  String get ellipse155 => _asset('ellipse_155.svg');
  String get node1Overlay => _asset('node_1_overlay.svg');
  String get decoVector1 => _asset('deco_vector_1.svg');
  String get decoVector2 => _asset('deco_vector_2.svg');
  String get decoVector3 => _asset('deco_vector_3.svg');
  String get decoVector4 => _asset('deco_vector_4.svg');
  String get node3Overlay => _asset('node_3_overlay.svg');
  String get node3Flag => _asset('node_3_flag.svg');
  String get learningQ => _asset('learning_q.svg');
  String get chevronLearning => _asset('chevron_learning.svg');
  String get reviewHouseBody => _asset('review_house_body.svg');
  String get reviewHouseIcon => _asset('review_house_icon.svg');
  String get reviewHouseDot => _asset('review_house_dot.svg');
  String get reviewHouseRoof => _asset('review_house_roof.svg');
  String get reviewHouseComposite => _asset('review_house_composite.svg');

  bool get hasCompositeReviewHouse => tier == HomeTier.advanced;

  /// Figma PNG export — drop-shadow·3D 두께 포함 (flutter_svg filter 미지원).
  String get node1Pentagon => _asset('node_1_pentagon.png');
  String get node3Pentagon => _asset('node_3_pentagon.png');
}
