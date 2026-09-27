import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/settings/settings_screen.dart';
import 'package:testapp/theme/app_theme.dart';

void main() {
  Future<void> pumpSettings(
    WidgetTester tester,
    Size size, {
    String bio = '',
    int learningStage = 1,
    VoidCallback? onLogout,
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
        home: SettingsScreen(
          profile: UserProfile(
            email: 'ham@test.com',
            nickname: '김햄핀이',
            bio: bio,
          )..learningStage = learningStage,
          onLogout: onLogout ?? () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('my page fits a small phone', (tester) async {
    await pumpSettings(tester, const Size(360, 740));
    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('김햄핀이'), findsOneWidget);
    expect(find.text('친구 목록'), findsOneWidget);
    expect(find.text('연락처 연동'), findsOneWidget);
    expect(find.text('개인정보 설정'), findsOneWidget);
    expect(find.text('학습 과정'), findsOneWidget);
    expect(find.text('열심히 달리는 중이에요~~!'), findsOneWidget);
    expect(find.text('만족도 조사'), findsOneWidget);
    expect(find.text('규정 & 개인정보 처리 방침'), findsOneWidget);
    expect(find.text('로그아웃/ 계정전환'), findsOneWidget);
    expect(find.text('회원탈퇴'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('my page fits a large phone', (tester) async {
    await pumpSettings(tester, const Size(430, 932));
    expect(find.text('터치해서\n한줄소개 입력'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the saved bio in the box', (tester) async {
    await pumpSettings(tester, const Size(393, 852), bio: '저축왕이 될 거예요');
    expect(find.text('저축왕이 될 거예요'), findsOneWidget);
  });

  testWidgets('bio field keeps the blue box, not the themed white input',
      (tester) async {
    // 앱 테마의 InputDecorationTheme은 흰 배경 + 둥근 테두리다. 한줄소개는
    // 하늘색 박스 자체가 입력칸이라 그 스타일이 새어 들어오면 안 된다.
    await pumpSettings(tester, const Size(393, 852));
    final field = tester.widget<TextField>(find.byType(TextField));
    final decoration = field.decoration!;

    expect(decoration.filled, isFalse);
    expect(decoration.fillColor, Colors.transparent);
    expect(decoration.border, InputBorder.none);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
  });

  testWidgets('tapping the bio box starts editing', (tester) async {
    await pumpSettings(tester, const Size(393, 852));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);

    await tester.enterText(find.byType(TextField), '금융 새싹');
    expect(find.text('금융 새싹'), findsOneWidget);
  });

  testWidgets('reverts the bio when saving fails', (tester) async {
    // 테스트에는 Firebase가 없어서 저장이 실패한다 — 이전 값으로 되돌아가야 한다.
    await pumpSettings(tester, const Size(393, 852), bio: '원래 소개');
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '새 소개');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('원래 소개'), findsOneWidget);
    expect(find.text('한줄소개를 저장하지 못했어요.'), findsOneWidget);
  });

  testWidgets('learning card shows the current stage on the flame',
      (tester) async {
    await pumpSettings(tester, const Size(393, 852), learningStage: 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tapping the learning card opens the stage sheet',
      (tester) async {
    await pumpSettings(tester, const Size(393, 852), learningStage: 3);
    await tester.tap(find.text('열심히 달리는 중이에요~~!'));
    await tester.pumpAndSettle();

    expect(find.text('1~10단계 중 하나를 선택하세요.'), findsOneWidget);
    expect(find.text('선택한 단계 난이도 문제가 출제됩니다.'), findsOneWidget);
    expect(find.text('초급'), findsOneWidget);
    expect(find.text('중급'), findsOneWidget);
    expect(find.text('고급'), findsOneWidget);
    for (var stage = 1; stage <= 10; stage++) {
      expect(find.bySemanticsLabel('$stage단계'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping outside the stage sheet closes it', (tester) async {
    await pumpSettings(tester, const Size(393, 852));
    await tester.tap(find.text('열심히 달리는 중이에요~~!'));
    await tester.pumpAndSettle();
    expect(find.text('1~10단계 중 하나를 선택하세요.'), findsOneWidget);

    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    expect(find.text('1~10단계 중 하나를 선택하세요.'), findsNothing);
  });

  testWidgets('logout popup cancels without logging out', (tester) async {
    var loggedOut = false;
    await pumpSettings(
      tester,
      const Size(393, 852),
      onLogout: () => loggedOut = true,
    );
    await tester.ensureVisible(find.text('로그아웃/ 계정전환'));
    await tester.tap(find.text('로그아웃/ 계정전환'));
    await tester.pumpAndSettle();

    expect(find.text('정말 로그아웃하시겠어요?'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    // 제목과 확인 버튼 모두 '로그아웃'.
    expect(find.text('로그아웃'), findsNWidgets(2));

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text('정말 로그아웃하시겠어요?'), findsNothing);
    expect(loggedOut, isFalse);
  });
}
