import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/calendar/streak_calendar_screen.dart';

void main() {
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
