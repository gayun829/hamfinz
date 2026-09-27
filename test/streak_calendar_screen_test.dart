import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/calendar/streak_calendar_screen.dart';
import 'package:testapp/services/friend_service.dart';
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
  testWidgets('only the streak running into today is joined by a band', (
    tester,
  ) async {
    final now = DateHelper.koreaNow();
    // 한 달 안에서만 확인하도록 월 초에는 건너뛴다.
    if (now.day < 5) return;
    String daysAgo(int n) =>
        DateHelper.dateKey(DateTime(now.year, now.month, now.day - n));
    final today = daysAgo(0);

    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(
          completedDates: {daysAgo(4), daysAgo(2), daysAgo(1), today},
        ),
      ),
    );
    expect(find.byKey(ValueKey('today-hamster-$today')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-$today')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-${daysAgo(1)}')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-${daysAgo(2)}')), findsOneWidget);
    // 끊긴 과거 학습일은 띠 없이 동그라미만.
    expect(find.byKey(ValueKey('streak-band-${daysAgo(4)}')), findsNothing);
    expect(find.byKey(ValueKey('study-circle-${daysAgo(4)}')), findsOneWidget);

    // 오늘 아직 안 했으면 띠 없이 동그라미만 보인다.
    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(completedDates: {daysAgo(2), daysAgo(1)}),
      ),
    );
    expect(find.byKey(ValueKey('today-hamster-$today')), findsNothing);
    expect(find.byKey(ValueKey('streak-band-${daysAgo(1)}')), findsNothing);
    expect(find.byKey(ValueKey('study-circle-${daysAgo(1)}')), findsOneWidget);
    expect(find.byKey(ValueKey('study-circle-${daysAgo(2)}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an empty state when there are no friends', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StreakCalendarScreen()));
    await tester.pump();
    expect(find.text('친구가 아직 없어요..'), findsOneWidget);
    expect(find.textContaining('금융마블'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(
          key: UniqueKey(),
          loadFriendsRanking: () async => const FriendsRanking(
            friendCount: 2,
            participants: [
              FriendRankEntry(rank: 1, nickname: '김기니', streak: 9, isMe: false),
              FriendRankEntry(rank: 2, nickname: '햄찌', streak: 4, isMe: true),
              FriendRankEntry(rank: 3, nickname: '다람', streak: 0, isMe: false),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('친구가 아직 없어요..'), findsNothing);
    expect(find.text('1위 김기니'), findsOneWidget);
    expect(find.bySemanticsLabel('2위 나, 연속학습 4일'), findsOneWidget);
    expect(find.bySemanticsLabel('3위 다람, 연속학습 0일'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('says so when the ranking fails to load', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(
          loadFriendsRanking: () async => throw Exception('not deployed'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('친구 순위를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('친구가 아직 없어요..'), findsNothing);
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
