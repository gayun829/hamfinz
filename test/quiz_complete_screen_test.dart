import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/quiz/quiz_complete_screen.dart';
import 'package:testapp/theme/app_theme.dart';

void main() {
  Future<void> pumpComplete(
    WidgetTester tester,
    Size size, {
    required VoidCallback onContinue,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: QuizCompleteScreen(onContinue: onContinue),
      ),
    );
    await tester.pump();
  }

  testWidgets('축하창이 작은 화면에서도 넘치지 않는다', (tester) async {
    await pumpComplete(tester, const Size(360, 740), onContinue: () {});
    await tester.pumpAndSettle();

    expect(find.text('Lesson\ncomplete!'), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('아무 곳이나 터치하면 다음으로 넘어간다', (tester) async {
    var continued = 0;
    await pumpComplete(
      tester,
      const Size(393, 852),
      onContinue: () => continued++,
    );

    // 등장 애니메이션 중에 눌러도 바로 넘어가야 한다.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(QuizCompleteScreen));
    expect(continued, 1);

    // 연타해도 한 번만 넘긴다.
    await tester.tap(find.byType(QuizCompleteScreen));
    expect(continued, 1);

    await tester.pumpAndSettle();
  });
}
