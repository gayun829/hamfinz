import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/quiz_question.dart';
import 'package:testapp/screens/quiz/quiz_reward_screen.dart';

void main() {
  testWidgets('completion reward retains seeds without XP or unlocks', (
    tester,
  ) async {
    const result = QuizSessionResult(
      answers: [
        QuizAnswer(questionId: 'q1', selectedIndex: 0, isCorrect: true),
      ],
      seedsEarned: 5,
      newStreak: 4,
      energyEarned: 0,
      advancedLearningStage: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizRewardScreen(
          correctCount: 1,
          totalCount: result.answers.length,
          seedsEarned: result.seedsEarned,
          energyEarned: result.energyEarned,
          onClaim: () {},
        ),
      ),
    );

    expect(result.newStreak, 4);
    expect(result.advancedLearningStage, 2);
    expect(find.text('+5'), findsOneWidget);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('레벨'), findsNothing);
    expect(find.text('새 햄스터 획득!'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
