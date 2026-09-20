import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/auth/onboarding/nickname_step_screen.dart';
import 'package:testapp/screens/auth/onboarding/password_step_screen.dart';
import 'package:testapp/screens/auth/onboarding/signup_draft.dart';
import 'package:testapp/screens/auth/onboarding/terms_step_screen.dart';
import 'package:testapp/theme/app_theme.dart';
import 'package:testapp/theme/figma_onboarding_tokens.dart';

void main() {
  Future<void> pump(WidgetTester tester, Size size, Widget home) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(size: size),
          child: child ?? const SizedBox.shrink(),
        ),
        home: home,
      ),
    );
    await tester.pump();
  }

  group('닉네임 단계', () {
    testWidgets('말풍선과 도움말을 디자인 문구대로 보여준다', (tester) async {
      await pump(
        tester,
        const Size(393, 852),
        NicknameStepScreen(draft: SignupDraft()),
      );

      expect(find.text('닉네임을 입력해조~'), findsOneWidget);
      expect(find.text('닉네임'), findsOneWidget);
      expect(find.text('닉네임을 입력해 주세요'), findsOneWidget);
      expect(find.text(NicknameStepScreen.hint), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2자 미만이면 중복 확인까지 가지 않고 막는다', (tester) async {
      await pump(
        tester,
        const Size(393, 852),
        NicknameStepScreen(draft: SignupDraft()),
      );

      await tester.enterText(find.byType(TextField), '햄');
      await tester.tap(find.text('다음'));
      await tester.pump();

      // 길이에서 걸리면 Firestore를 건드리지 않는다 — 예외 없이 도움말만 빨개진다.
      expect(find.text(NicknameStepScreen.hint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('작은 화면에서도 넘치지 않는다', (tester) async {
      await pump(
        tester,
        const Size(360, 640),
        NicknameStepScreen(draft: SignupDraft()),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('비밀번호 단계', () {
    testWidgets('입력에 따라 규칙 4개가 채워진다', (tester) async {
      await pump(
        tester,
        const Size(393, 852),
        PasswordStepScreen(draft: SignupDraft()..email = 'ham@test.com'),
      );

      expect(find.text('8자리 이상'), findsOneWidget);
      expect(find.text('숫자 포함'), findsOneWidget);
      expect(find.text('영문 포함'), findsOneWidget);
      expect(find.text('특수문자 포함'), findsOneWidget);
      expect(find.text('인증번호 전송'), findsOneWidget);

      Color colorOf(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;

      final before = colorOf('8자리 이상');
      await tester.enterText(find.byType(TextField), 'hamfinz1!');
      await tester.pump();

      expect(colorOf('8자리 이상'), isNot(before));
      expect(colorOf('숫자 포함'), colorOf('8자리 이상'));
      expect(colorOf('특수문자 포함'), colorOf('8자리 이상'));
      expect(tester.takeException(), isNull);
    });
  });

  group('약관 단계', () {
    testWidgets('전체 동의가 네 줄을 한 번에 켜고 끈다', (tester) async {
      await pump(
        tester,
        const Size(393, 852),
        TermsStepScreen(draft: SignupDraft()),
      );

      expect(find.text('가입약관을 확인해조~'), findsOneWidget);
      expect(find.text('이용 약관 동의(필수)'), findsOneWidget);
      expect(find.text('개인정보 수집 및 이용(필수)'), findsOneWidget);
      expect(find.text('광고성 정보, 마케팅 활용 동의(선택)'), findsOneWidget);

      List<Color> circleColors() => tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.shape == BoxShape.circle)
          .map((d) => d.color!)
          .toList();

      expect(circleColors(), everyElement(FigmaOnboardingTokens.checkOff));

      await tester.tap(find.text('전체 동의'));
      await tester.pump();
      expect(circleColors(), everyElement(FigmaOnboardingTokens.accent));

      await tester.tap(find.text('전체 동의'));
      await tester.pump();
      expect(circleColors(), everyElement(FigmaOnboardingTokens.checkOff));
      expect(tester.takeException(), isNull);
    });

    testWidgets('동의 없이 누르면 필수 안내를 띄운다', (tester) async {
      await pump(
        tester,
        const Size(393, 852),
        TermsStepScreen(draft: SignupDraft()),
      );

      await tester.tap(find.text('회원가입'));
      await tester.pump();

      expect(find.text('필수 약관에 동의해 주세요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
