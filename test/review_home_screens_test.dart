import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/home/home_screen.dart';
import 'package:testapp/screens/home/review_home_screens.dart';

void main() {
  final profile = UserProfile(
    email: 'review@test.dev',
    nickname: '복습',
    interestCategories: const ['saving'],
  );

  final screens = <String, Widget>{
    'beginner': BeginnerReviewHomeScreen(profile: profile),
    'intermediate': IntermediateReviewHomeScreen(profile: profile),
    'advanced': AdvancedReviewHomeScreen(profile: profile),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} review home renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(home: entry.value));
      await tester.pump();

      expect(find.text('오늘의 학습'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('review home starts after more than ten unique wrong questions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pumpHome(int incorrectQuestionCount) {
      return tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            key: ValueKey(incorrectQuestionCount),
            profile: UserProfile(
              email: 'threshold@test.dev',
              nickname: '기준',
              incorrectQuestionCount: incorrectQuestionCount,
            ),
          ),
        ),
      );
    }

    await pumpHome(10);
    expect(
      find.byKey(const ValueKey('home-review-house-beginner')),
      findsNothing,
    );

    await pumpHome(11);
    expect(
      find.byKey(const ValueKey('home-review-house-beginner')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
