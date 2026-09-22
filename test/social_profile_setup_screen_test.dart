import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/auth/social_profile_setup_screen.dart';
import 'package:testapp/services/auth_service.dart';
import 'package:testapp/theme/app_theme.dart';
import 'package:testapp/widgets/figma_auth_widgets.dart';

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

  testWidgets('이메일 가입과 같은 닉네임 규칙으로 막는다', (tester) async {
    await pumpSetup(tester, const Size(393, 852), suggestedNickname: 'a/b');

    // 문서 id로 못 쓰는 문자는 Firestore까지 가지 않고 화면에서 걸린다.
    await tester.tap(find.byType(FigmaDuplicateCheckButton));
    await tester.pump();
    expect(find.text('닉네임에 쓸 수 없는 문자가 들어 있어요.'), findsOneWidget);

    // 제공자 이름이 1자여도 그대로 가입되지 않는다.
    await tester.enterText(find.byType(TextField), '햄');
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    expect(find.text(AuthService.nicknameLengthHint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 테스트에는 Firebase가 없어서 AuthService를 부르는 순간 예외가 난다 —
  // 네트워크 오류로 Firestore 호출이 실패하는 상황과 같다.
  testWidgets('중복 확인이 실패해도 버튼이 다시 풀린다', (tester) async {
    await pumpSetup(tester, const Size(393, 852));

    await tester.tap(find.byType(FigmaDuplicateCheckButton));
    await tester.pump();
    await tester.pump();

    expect(find.text('중복 확인에 실패했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    final button = tester.widget<FigmaDuplicateCheckButton>(
      find.byType(FigmaDuplicateCheckButton),
    );
    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('가입이 실패해도 화면에 갇히지 않고 취소할 수 있다', (tester) async {
    var cancelled = false;
    await pumpSetup(
      tester,
      const Size(393, 852),
      onCancelled: () => cancelled = true,
    );

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    await tester.pump();
    expect(find.text('가입을 마치지 못했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);

    // 예전에는 여기서 _loading이 풀리지 않아 취소·뒤로가기가 모두 막혔다.
    await tester.ensureVisible(find.text('취소'));
    await tester.tap(find.text('취소'));
    await tester.pump();
    await tester.pump();
    expect(cancelled, isTrue);
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
