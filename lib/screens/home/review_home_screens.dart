import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/home_tier_theme.dart';
import 'home_screen.dart';

/// Figma `268:3644` — 초급 복습 집 단계 홈.
class BeginnerReviewHomeScreen extends StatelessWidget {
  const BeginnerReviewHomeScreen({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) => HomeScreen(
    profile: profile,
    showReviewStage: true,
    tierOverride: HomeTierTheme.beginner,
  );
}

/// Figma `268:3808` — 중급 복습 집 단계 홈.
class IntermediateReviewHomeScreen extends StatelessWidget {
  const IntermediateReviewHomeScreen({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) => HomeScreen(
    profile: profile,
    showReviewStage: true,
    tierOverride: HomeTierTheme.intermediate,
  );
}

/// Figma `137:1610` — 고급 복습 집 단계 홈.
class AdvancedReviewHomeScreen extends StatelessWidget {
  const AdvancedReviewHomeScreen({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) => HomeScreen(
    profile: profile,
    showReviewStage: true,
    tierOverride: HomeTierTheme.advanced,
  );
}
