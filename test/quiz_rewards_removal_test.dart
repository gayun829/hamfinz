import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/quiz_question.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/quiz/quiz_result_screen.dart';

void main() {
  testWidgets('results retain seeds, streak and stage without XP or unlocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuizResultScreen(
          profile: UserProfile(
            email: 'test@example.com',
            nickname: '테스트',
            energy: 75,
          ),
          result: const QuizSessionResult(
            answers: [
              QuizAnswer(questionId: 'q1', selectedIndex: 0, isCorrect: true),
            ],
            seedsEarned: 5,
            newStreak: 4,
            advancedLearningStage: 2,
          ),
        ),
      ),
    );
    expect(find.text('획득 씨앗'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(find.text('4일'), findsOneWidget);
    expect(find.textContaining('넘어갔어요!'), findsOneWidget);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('레벨'), findsNothing);
    expect(find.text('새 햄스터 획득!'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
