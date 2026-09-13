import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/calendar/streak_calendar_screen.dart';
import 'package:testapp/utils/date_helper.dart';

void main() {
  testWidgets('guard count uses pieces and friend entry remains available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StreakCalendarScreen(studyGuardCount: 4)),
    );
    expect(find.text('방어권 보유'), findsOneWidget);
    expect(find.text('4 개', findRichText: true), findsOneWidget);
    expect(find.byTooltip('친구 추가'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('only a completed today gets hamster ears', (tester) async {
    final now = DateHelper.koreaNow();
    final today = DateHelper.dateKey(now);
    final yesterday = DateHelper.dateKey(
      DateTime(now.year, now.month, now.day - 1),
    );
    await tester.pumpWidget(
      MaterialApp(home: StreakCalendarScreen(completedDates: {yesterday})),
    );
    expect(find.byKey(ValueKey('today-hamster-$yesterday')), findsNothing);
    expect(find.byKey(ValueKey('today-hamster-$today')), findsNothing);
    if (now.day > 1) {
      expect(find.byKey(ValueKey('study-circle-$yesterday')), findsOneWidget);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(completedDates: {yesterday, today}),
      ),
    );
    expect(find.byKey(ValueKey('today-hamster-$today')), findsOneWidget);
    expect(find.byKey(ValueKey('today-hamster-$yesterday')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Future<void> pumpCalendar(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQueryData(size: size),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const StreakCalendarScreen(streak: 12),
      ),
    );
    await tester.pump();
  }

  testWidgets('calendar fits a small phone', (tester) async {
    await pumpCalendar(tester, const Size(360, 740));
    expect(find.textContaining('연속학습'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar fits a large phone', (tester) async {
    await pumpCalendar(tester, const Size(430, 932));
    expect(find.textContaining('이번 달 친구와의 경쟁'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
