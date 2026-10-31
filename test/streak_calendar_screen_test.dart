import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/calendar/streak_calendar_screen.dart';
import 'package:testapp/services/friend_service.dart';
import 'package:testapp/utils/date_helper.dart';
import 'package:testapp/widgets/shop/shop_widgets.dart';

void main() {
  testWidgets('guard count uses pieces and friend entry remains available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StreakCalendarScreen(studyGuardCount: 4)),
    );
    expect(find.text('방어권 보유'), findsOneWidget);
    expect(find.bySemanticsLabel('방어권 보유 4개'), findsOneWidget);
    expect(find.byTooltip('친구 추가'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('consecutive study days are joined by a band', (tester) async {
    // Figma `1006:2899`처럼 한 주 중간에서 시작해 다음 줄로 넘어가는 연속.
    final now = DateTime(2025, 8, 20);
    String daysAgo(int n) =>
        DateHelper.dateKey(DateTime(now.year, now.month, now.day - n));
    final today = daysAgo(0);

    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(
          today: now,
          completedDates: {daysAgo(4), daysAgo(2), daysAgo(1), today},
        ),
      ),
    );
    expect(find.byKey(ValueKey('today-hamster-$today')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-$today')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-${daysAgo(1)}')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-${daysAgo(2)}')), findsOneWidget);
    // 하루만 공부한 날은 띠 없이 동그라미만.
    expect(find.byKey(ValueKey('streak-band-${daysAgo(4)}')), findsNothing);
    expect(find.byKey(ValueKey('study-circle-${daysAgo(4)}')), findsOneWidget);

    // 오늘 아직 안 했으면 어제까지 잇고 햄스터는 어제에 얹는다.
    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(
          today: now,
          completedDates: {daysAgo(2), daysAgo(1)},
        ),
      ),
    );
    expect(find.byKey(ValueKey('today-hamster-$today')), findsNothing);
    expect(find.byKey(ValueKey('today-hamster-${daysAgo(1)}')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-${daysAgo(1)}')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-${daysAgo(2)}')), findsOneWidget);

    // 이미 끊긴 지난 연속도 띠로 잇되, 햄스터는 얹지 않는다.
    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(
          today: now,
          completedDates: {daysAgo(4), daysAgo(3)},
        ),
      ),
    );
    expect(find.byKey(ValueKey('streak-band-${daysAgo(4)}')), findsOneWidget);
    expect(find.byKey(ValueKey('streak-band-${daysAgo(3)}')), findsOneWidget);
    expect(find.byKey(ValueKey('today-hamster-${daysAgo(3)}')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the hamster covers the end of the band like the Figma frame', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: StreakCalendarScreen(
          today: DateTime(2025, 8, 20),
          completedDates: {
            for (var d = 12; d <= 20; d++)
              '2025-08-${d.toString().padLeft(2, '0')}',
          },
        ),
      ),
    );
    final hamster = tester.getRect(
      find.byKey(const ValueKey('today-hamster-2025-08-20')),
    );
    final band = tester.getRect(
      find.byKey(const ValueKey('streak-band-2025-08-20')),
    );
    expect(hamster.size.width, closeTo(39.2248, 0.01));
    expect(hamster.size.height, closeTo(27.2814, 0.01));
    // 띠는 23 높이이고 햄스터 아랫변과 같은 선에서 끝난다.
    expect(band.height, closeTo(23, 0.01));
    expect(hamster.bottom, closeTo(band.bottom, 0.01));
    // 띠 끝은 햄스터 가운데 직전이라 햄스터가 덮는다.
    expect(band.right, lessThan(hamster.center.dx));
    expect(band.right, greaterThan(hamster.left));
    // 주가 바뀌면 띠가 끊기고 다음 줄에서 다시 시작한다.
    final saturday = tester.getRect(
      find.byKey(const ValueKey('streak-band-2025-08-16')),
    );
    final sunday = tester.getRect(
      find.byKey(const ValueKey('streak-band-2025-08-17')),
    );
    expect(sunday.top, greaterThan(saturday.bottom));
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
              FriendRankEntry(
                rank: 3,
                nickname: '다람',
                streak: 0,
                isMe: false,
                look: FriendLook(skinId: 'skin_black'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('친구가 아직 없어요..'), findsNothing);
    expect(find.bySemanticsLabel('1위 김기니, 연속학습 9일'), findsOneWidget);
    expect(find.text('연속학습 9일'), findsOneWidget);
    expect(find.bySemanticsLabel('2위 나, 연속학습 4일'), findsOneWidget);
    expect(find.bySemanticsLabel('3위 다람, 연속학습 0일'), findsOneWidget);
    // 목록 아바타는 각자 입은 스킨으로 그린다.
    final faces = tester.widgetList<HamsterFace>(find.byType(HamsterFace));
    expect(faces.map((f) => f.skinId), [null, null, 'skin_black']);
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
