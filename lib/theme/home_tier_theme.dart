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
  });

  final HomeTier tier;
  final String assetFolder;
  final Color learningCtaColor;

  static const beginner = HomeTierTheme._(
    tier: HomeTier.beginner,
    assetFolder: 'beginner',
    learningCtaColor: Color(0xFF3CC6FF),
  );

  static const intermediate = HomeTierTheme._(
    tier: HomeTier.intermediate,
    assetFolder: 'intermediate',
    learningCtaColor: Color(0xFFB3EA70),
  );

  static const advanced = HomeTierTheme._(
    tier: HomeTier.advanced,
    assetFolder: 'advanced',
    learningCtaColor: Color(0xFFFD9068),
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
}
