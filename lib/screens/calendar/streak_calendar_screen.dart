import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/streak_calendar_data.dart';
import '../../utils/date_helper.dart';

import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/home_bottom_nav.dart';
import '../friends/add_friend_screen.dart';

const _mint = Color(0xFFDEFDFE);
const _cyan = Color(0xFF65D6F8);

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({
    super.key,
    this.streak = 0,
    this.studyGuardCount = 0,
    this.completedDates = const <String>{},
    this.goalDays = 16,
    this.onNavTap,
  });

  final int streak;
  final int studyGuardCount;
  final Set<String> completedDates;
  final int goalDays;
  final ValueChanged<int>? onNavTap;

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  DateTime _month = DateHelper.koreaNow();

  void _navigate(int index) {
    Navigator.of(context).maybePop();
    widget.onNavTap?.call(index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFAFA),
    bottomNavigationBar: SafeArea(
      top: false,
      child: HomeBottomNav(currentIndex: 1, onTap: _navigate),
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / 393;
        double s(double value) => value * scale;
        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xFFB8F0EF), Color(0xFF36C2FA)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: s(304),
                    child: Stack(
                      children: [
                        Positioned(
                          left: s(14),
                          top: s(20),
                          child: IconButton(
                            tooltip: '뒤로가기',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: s(26),
                              color: const Color(0xFFD5FAFC),
                            ),
                          ),
                        ),
                        Positioned(
                          left: s(44),
                          top: s(88),
                          child: Row(
                            children: [
                              FigmaSvg(
                                FigmaAssets.statStreak,
                                width: s(28),
                                height: s(39),
                              ),
                              SizedBox(width: s(9)),
                              Text(
                                '목표까지 D-${(widget.goalDays - widget.streak).clamp(0, widget.goalDays)}',
                                style: TextStyle(
                                  fontSize: s(18),
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: s(24),
                          right: s(24),
                          top: s(142),
                          height: s(138),
                          child: Container(
                            padding: EdgeInsets.all(s(20)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(s(14)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 177,
                                  child: _Stat(
                                    scale: scale,
                                    label: '연속학습',
                                    value: widget.streak,
                                    flame: true,
                                    progress: widget.goalDays > 0
                                        ? widget.streak / widget.goalDays
                                        : 0,
                                  ),
                                ),
                                SizedBox(width: s(20)),
                                Expanded(
                                  flex: 101,
                                  child: _Stat(
                                    scale: scale,
                                    label: '방어권 보유',
                                    unit: '개',
                                    value: widget.studyGuardCount,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: s(38),
                          top: s(58),
                          width: s(118),
                          height: s(91),
                          child: const FigmaPng(
                            'assets/figma/calendar/hamster_header.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        for (final right in [121.0, 47.0])
                          Positioned(
                            right: s(right),
                            top: s(134),
                            width: s(23),
                            height: s(18),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD47C),
                                borderRadius: BorderRadius.circular(s(14)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(s(26), s(32), s(22), s(28)),
                child: Column(
                  children: [
                    _Calendar(
                      scale: scale,
                      month: _month,
                      completedDates: widget.completedDates,
                      onShift: (delta) => setState(
                        () => _month = DateTime(
                          _month.year,
                          _month.month + delta,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: s(11),
                        vertical: s(30),
                      ),
                      child: const Divider(height: 1, color: Color(0xFFE6E6E6)),
                    ),
                    _FriendsCard(scale: scale, onOpen: () => _navigate(1)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

BoxDecoration _card(double scale) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14 * scale),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.065),
      blurRadius: 14 * scale,
      offset: Offset(0, 2 * scale),
    ),
  ],
);

class _Stat extends StatelessWidget {
  const _Stat({
    required this.scale,
    required this.label,
    required this.value,
    this.flame = false,
    this.unit = '일',
    this.progress = 0,
  });
  final double scale;
  final String label;
  final int value;
  final bool flame;
  final String unit;
  final double progress;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    return Container(
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(s(7)),
      ),
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (flame) ...[
            Container(
              width: s(16),
              height: s(65),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(s(20)),
              ),
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(s(20)),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFF5B18), Color(0xFFFF994C)],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: s(8)),
            FigmaSvg(FigmaAssets.statStreak, width: s(43), height: s(59)),
            SizedBox(width: s(12)),
          ],
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: s(12),
                      color: const Color(0xFF999999),
                    ),
                  ),
                  SizedBox(height: s(10)),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$value',
                          style: TextStyle(
                            fontSize: s(32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' $unit',
                          style: TextStyle(fontSize: s(12)),
                        ),
                      ],
                    ),
                    style: const TextStyle(color: Colors.black, height: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.scale,
    required this.month,
    required this.completedDates,
    required this.onShift,
  });
  final double scale;
  final DateTime month;
  final Set<String> completedDates;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final leading = DateTime(month.year, month.month).weekday % 7;
    final count = DateTime(month.year, month.month + 1, 0).day;
    final rows = (leading + count + 6) ~/ 7;
    final now = DateHelper.koreaNow();
    final today = DateTime(now.year, now.month, now.day);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 100) onShift(velocity < 0 ? 1 : -1);
      },
      child: Container(
        decoration: _card(scale),
        padding: EdgeInsets.fromLTRB(s(16), s(20), s(16), s(18)),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: s(10)),
                Expanded(
                  child: Text(
                    '${month.year}년 ${month.month}월',
                    style: TextStyle(
                      fontSize: s(20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '이전 달',
                  onPressed: () => onShift(-1),
                  constraints: BoxConstraints.tightFor(
                    width: s(28),
                    height: 48,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.chevron_left,
                    size: s(18),
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
                IconButton(
                  tooltip: '다음 달',
                  onPressed: () => onShift(1),
                  constraints: BoxConstraints.tightFor(
                    width: s(28),
                    height: 48,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.chevron_right,
                    size: s(18),
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
            SizedBox(height: s(40)),
            Row(
              children: [
                for (final label in ['일', '월', '화', '수', '목', '금', '토'])
                  Expanded(
                    child: Center(
                      child: Text(label, style: TextStyle(fontSize: s(12))),
                    ),
                  ),
              ],
            ),
            SizedBox(height: s(10)),
            for (var row = 0; row < rows; row++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final date = DateTime(
                            month.year,
                            month.month,
                            row * 7 + col - leading + 1,
                          );
                          final key = DateHelper.dateKey(date);
                          final inMonth = date.month == month.month;
                          final completed =
                              inMonth && completedDates.contains(key);
                          final todayCompleted = completed && date == today;
                          return Semantics(
                            label: '$key${completed ? ', 학습 완료' : ''}',
                            child: SizedBox(
                              height: s(42),
                              child: Center(
                                child: SizedBox(
                                  width: s(29),
                                  height: s(27),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (todayCompleted) ...[
                                        Positioned(
                                          left: 0,
                                          top: 2,
                                          child: _dot(s(9)),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 2,
                                          child: _dot(s(9)),
                                        ),
                                      ],
                                      Container(
                                        key: completed
                                            ? ValueKey(
                                                '${todayCompleted ? 'today-hamster' : 'study-circle'}-$key',
                                              )
                                            : null,
                                        width: s(23),
                                        height: s(23),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: completed
                                              ? const Color(0xFFB3E5FC)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            s(todayCompleted ? 7 : 20),
                                          ),
                                        ),
                                        child: Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            fontSize: s(12),
                                            color: !inMonth
                                                ? const Color(0xFFD8D8D8)
                                                : completed || date == today
                                                ? Colors.black
                                                : const Color(0xFF999999),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0xFFB3E5FC),
      shape: BoxShape.circle,
    ),
  );
}

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({required this.scale, required this.onOpen});
  final double scale;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final friends = StreakCalendarMock.friends;
    return Container(
      decoration: _card(scale),
      height: s(246),
      child: Stack(
        children: [
          Positioned(
            left: s(18),
            top: s(16),
            child: Text(
              '이번 달 친구와의 경쟁!',
              style: TextStyle(fontSize: s(16), color: Colors.black),
            ),
          ),
          if (friends.isEmpty)
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                ),
                child: const Text('친구 추가하기'),
              ),
            ),
          for (var i = 0; i < friends.length && i < 4; i++)
            Positioned(
              left: s([30.0, 160.0, 230.0, 272.0][i]),
              top: s([46.0, 20.0, 126.0, 60.0][i]),
              width: s([118.0, 78.0, 66.0, 48.0][i]),
              child: _Rank(scale: scale, friend: friends[i], index: i),
            ),
          Positioned(
            right: s(22),
            bottom: s(19),
            width: s(154),
            height: s(24),
            child: TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFB2EFF2),
                foregroundColor: const Color(0xFF344447),
                padding: EdgeInsets.symmetric(horizontal: s(6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '이번 달 금융마블 바로가기',
                        style: TextStyle(fontSize: s(9)),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: s(13),
                    color: const Color(0xFFD5D9CD),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: s(4),
            top: 0,
            child: IconButton(
              tooltip: '친구 추가',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddFriendScreen()),
              ),
              icon: Icon(Icons.person_add_alt_1, size: s(21), color: _cyan),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rank extends StatelessWidget {
  const _Rank({required this.scale, required this.friend, required this.index});
  final double scale;
  final StreakFriendMock friend;
  final int index;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final height = [128.0, 96.0, 61.0, 46.0][index];
    return Column(
      children: [
        SizedBox(
          height: s(height),
          child: Stack(
            children: [
              Positioned.fill(
                top: s(height * 0.3),
                child: FigmaSvg(
                  [
                    FigmaAssets.calendarPodium1,
                    FigmaAssets.calendarPodium2,
                    FigmaAssets.calendarPodium3,
                    FigmaAssets.calendarPodium4,
                  ][index],
                  fit: BoxFit.contain,
                ),
              ),
              if (index != 2)
                Positioned.fill(
                  bottom: s(8),
                  child: FigmaPng(
                    'assets/figma/calendar/hamster_rank_${index == 0
                        ? 1
                        : index == 1
                        ? 2
                        : 4}.png',
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
        if (index == 0)
          Padding(
            padding: EdgeInsets.only(top: s(4), bottom: s(3)),
            child: Text('1위 ${friend.name}', style: TextStyle(fontSize: s(15))),
          ),
        SizedBox(
          height: s(index == 0 ? 16 : 13),
          child: Row(
            children: [
              if (index == 1 || index == 2) ...[
                Container(
                  width: s(14),
                  height: s(14),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB2EFF2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${friend.rank}',
                    style: TextStyle(fontSize: s(10), color: Colors.grey),
                  ),
                ),
                SizedBox(width: s(3)),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fraction = friend.goal > 0
                        ? (friend.learned / friend.goal).clamp(0.0, 1.0)
                        : 0.0;
                    final height = s(
                      index == 0
                          ? 16
                          : index == 3
                          ? 6
                          : 12,
                    );
                    return Container(
                      height: height,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(height),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: fraction,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _cyan,
                                borderRadius: BorderRadius.circular(height),
                              ),
                            ),
                          ),
                          if (fraction > 0)
                            Positioned(
                              left: ((constraints.maxWidth * fraction) - height)
                                  .clamp(0.0, constraints.maxWidth - height),
                              top: height * 0.18,
                              child: Container(
                                width: height * .64,
                                height: height * .64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF36C3FA),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
