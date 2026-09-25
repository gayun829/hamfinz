import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/home/home_screen.dart';
import 'package:testapp/screens/quiz/quiz_screen.dart';

void main() {
  testWidgets('햄핀이가 땅을 다 파고 들어간 뒤 학습을 시작하고, 돌아오면 다시 올라온다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profile: UserProfile(
            email: 'dig@test.dev',
            nickname: '파기',
            energy: 100,
            interestCategories: const ['saving'],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('오늘의 학습'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(QuizScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byType(QuizScreen), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsNothing);
    expect(find.text('오늘의 학습'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
