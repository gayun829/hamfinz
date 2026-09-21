import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/finance_terms.dart';
import 'package:testapp/screens/news/term_quiz_screen.dart';

void main() {
  final term = kFinanceTerms.firstWhere((t) => t.hasLesson);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TermQuizScreen(term: term, headline: '테스트 기사 제목'),
      ),
    );
    await tester.pump();
  }

  testWidgets('문제보다 용어 뜻이 먼저 나온다', (tester) async {
    await pump(tester);

    // 학습 단계: 용어 이름과 뜻은 보이고, 문제와 보기는 아직 안 보인다.
    expect(find.text(term.term), findsOneWidget);
    expect(find.text(term.summary), findsOneWidget);
    expect(find.text(term.forMe), findsOneWidget);
    expect(find.text(term.quiz!.question), findsNothing);
    for (final option in term.quiz!.options) {
      expect(find.text(option), findsNothing);
    }
    expect(find.text('퀴즈 풀기'), findsOneWidget);
  });

  testWidgets('「퀴즈 풀기」를 누르면 문제로 넘어간다', (tester) async {
    await pump(tester);

    await tester.tap(find.text('퀴즈 풀기'));
    await tester.pumpAndSettle();

    expect(find.text(term.quiz!.question), findsOneWidget);
    for (final option in term.quiz!.options) {
      expect(find.text(option), findsOneWidget);
    }
    // 보기를 고르기 전에는 채점 버튼이 잠겨 있다.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('틀리게 골라도 해설까지 간다', (tester) async {
    await pump(tester);
    await tester.tap(find.text('퀴즈 풀기'));
    await tester.pumpAndSettle();

    // 정답이 아닌 보기를 고른다 — 보상 경로(Firebase)를 안 타는 쪽이다.
    final quiz = term.quiz!;
    final wrong = quiz.options.indexOf(
      quiz.options.firstWhere((o) => o != quiz.options[quiz.answer]),
    );
    await tester.tap(find.text(quiz.options[wrong]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('정답 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('해설 보기'));
    await tester.pumpAndSettle();

    expect(find.text(quiz.why), findsOneWidget);
    expect(find.text('나가기'), findsOneWidget);
  });
}
