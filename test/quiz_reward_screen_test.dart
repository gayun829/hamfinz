import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/quiz/quiz_reward_screen.dart';
import 'package:testapp/theme/app_theme.dart';

void main() {
  Future<void> pumpReward(
    WidgetTester tester,
    Size size, {
    int correctCount = 7,
    int totalCount = 10,
    int seedsEarned = 35,
    int energyEarned = 20,
    VoidCallback? onClaim,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: QuizRewardScreen(
          correctCount: correctCount,
          totalCount: totalCount,
          seedsEarned: seedsEarned,
          energyEarned: energyEarned,
          onClaim: onClaim ?? () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('맞춘 수·씨앗·에너지를 실제 값으로 보여준다', (tester) async {
    await pumpReward(tester, const Size(393, 852));

    expect(find.text('7/10'), findsOneWidget);
    expect(find.text('+35'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('레슨 완료!'), findsOneWidget);
  });

  testWidgets('에너지가 최대치라 보상이 깎이면 그 값을 그대로 쓴다', (tester) async {
    await pumpReward(tester, const Size(393, 852), energyEarned: 5);

    expect(find.text('+5'), findsOneWidget);
    expect(find.text('+20'), findsNothing);
  });

  testWidgets('작은 화면에서도 넘치지 않는다', (tester) async {
    await pumpReward(tester, const Size(360, 740), correctCount: 10);

    expect(find.text('10/10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('보상획득을 누르면 이어서 넘어간다', (tester) async {
    var claimed = 0;
    await pumpReward(tester, const Size(393, 852), onClaim: () => claimed++);

    await tester.tap(find.text('보상획득'));
    await tester.pump();

    expect(claimed, 1);
  });
}
