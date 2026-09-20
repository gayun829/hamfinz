import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/auth/social_profile_setup_screen.dart';
import 'package:testapp/theme/app_theme.dart';

void main() {
  Future<void> pumpSetup(
    WidgetTester tester,
    Size size, {
    String suggestedNickname = '김햄핀이',
    VoidCallback? onCancelled,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQueryData(size: size),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: SocialProfileSetupScreen(
          suggestedNickname: suggestedNickname,
          onCompleted: () {},
          onCancelled: onCancelled ?? () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('제공자 닉네임을 그대로 쓰지 않고 고칠 수 있게 입력칸에 채워준다', (tester) async {
    await pumpSetup(tester, const Size(393, 852));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '김햄핀이');
    expect(find.text('닉네임'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('약관·개인정보 동의는 둘 다 필수다', (tester) async {
    await pumpSetup(tester, const Size(393, 852));

    expect(find.text('이용약관'), findsOneWidget);
    expect(find.text('개인정보 처리방침'), findsOneWidget);
    for (final checkbox in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
      expect(checkbox.value, isFalse);
    }

    // 동의 없이 누르면 Firestore까지 가지 않고 화면에서 막힌다.
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    expect(find.text('이용약관과 개인정보 처리방침에 동의해 주세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('제안할 닉네임이 없으면 빈 칸으로 둔다', (tester) async {
    await pumpSetup(tester, const Size(360, 740), suggestedNickname: '');

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.text('닉네임을 입력하세요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
