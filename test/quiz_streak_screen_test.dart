import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/quiz/quiz_streak_screen.dart';
import 'package:testapp/theme/app_theme.dart';

void main() {
  Future<void> pumpStreak(
    WidgetTester tester,
    Size size, {
    required int streak,
    VoidCallback? onContinue,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: QuizStreakScreen(streak: streak, onContinue: onContinue ?? () {}),
      ),
    );
    await tester.pump();
  }

  testWidgets('디자인 목업(14)이 아니라 실제 연속학습일을 보여준다', (tester) async {
    await pumpStreak(tester, const Size(393, 852), streak: 3);

    // 숫자와 day는 외곽선 층과 채움 층, 두 번 그린다.
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('14'), findsNothing);
    expect(find.text('day'), findsNWidgets(2));
    expect(find.text('streak!'), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
  });

  testWidgets('자릿수가 늘어도 작은 화면에서 넘치지 않는다', (tester) async {
    await pumpStreak(tester, const Size(360, 740), streak: 365);

    expect(find.text('365'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('streak 묶음이 Figma 좌표(top 501, 중심 191)에 놓인다', (tester) async {
    await pumpStreak(tester, const Size(393, 852), streak: 14);

    // FigmaSvg 내부에도 FittedBox가 있어서 streak 묶음의 것만 골라낸다.
    final block = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is FittedBox && w.fit == BoxFit.scaleDown,
      ),
    );
    expect(block.top, moreOrLessEquals(501, epsilon: 0.5));
    expect(block.center.dx, moreOrLessEquals(191, epsilon: 0.5));
  });

  testWidgets('다음으로를 누르면 이어서 넘어간다', (tester) async {
    var continued = 0;
    await pumpStreak(
      tester,
      const Size(393, 852),
      streak: 14,
      onContinue: () => continued++,
    );

    await tester.tap(find.text('다음으로'));
    await tester.pump();

    expect(continued, 1);
  });
}
