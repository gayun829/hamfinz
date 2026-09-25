import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/home_tier_theme.dart';
import 'home_screen.dart';

/// Figma `526:3093` — 초급 복습 집 단계 홈.
class BeginnerReviewHomeScreen extends StatelessWidget {
  const BeginnerReviewHomeScreen({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) => HomeScreen(
    profile: profile,
    reviewStageOverride: HomeReviewStage.ahead,
    tierOverride: HomeTierTheme.beginner,
  );
}

/// Figma `526:2892` — 중급 복습 집 단계 홈.
class IntermediateReviewHomeScreen extends StatelessWidget {
  const IntermediateReviewHomeScreen({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) => HomeScreen(
    profile: profile,
    reviewStageOverride: HomeReviewStage.ahead,
    tierOverride: HomeTierTheme.intermediate,
  );
}

/// Figma `526:3291` — 고급 복습 집 단계 홈.
class AdvancedReviewHomeScreen extends StatelessWidget {
  const AdvancedReviewHomeScreen({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) => HomeScreen(
    profile: profile,
    reviewStageOverride: HomeReviewStage.ahead,
    tierOverride: HomeTierTheme.advanced,
  );
}
