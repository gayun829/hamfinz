import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/streak_calendar_data.dart';
import '../../theme/figma_calendar_tokens.dart';
import '../../theme/figma_shop_tokens.dart';
import '../../utils/date_helper.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';
import '../friends/add_friend_screen.dart';

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({
    super.key,
    this.streak = 0,
    this.studyGuardCount = 0,
    this.completedDates = const <String>{},
  });

  final int streak;
  final int studyGuardCount;
  final Set<String> completedDates;

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
  }

  int get _streakDisplay => widget.streak;

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final clampedScaler = TextScaler.linear(
      textScaler.scale(1).clamp(0.9, 1.1),
    );

    return Scaffold(
      backgroundColor: FigmaCalendarTokens.background,
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final figma = FigmaScale.ofLayout(
                constraints,
                designWidth: FigmaCalendarTokens.designWidth,
              );
              final s = figma.s;
              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Text(
                        '<',
                        style: TextStyle(
                          fontSize: s(28).clamp(22, 32),
                          fontWeight: FontWeight.w600,
                          color: FigmaShopTokens.seed,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(s(16), 0, s(16), s(20)),
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FigmaCalendarTokens.panel,
                            borderRadius: BorderRadius.circular(
                              s(FigmaCalendarTokens.panelRadius),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeaderSection(
                                figma: figma,
                                streak: _streakDisplay,
                                studyGuardCount: widget.studyGuardCount,
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  s(12),
                                  s(8),
                                  s(12),
                                  0,
                                ),
                                child: _MonthCalendar(
                                  figma: figma,
                                  month: _month,
                                  completedDates: widget.completedDates,
                                  onPrev: () => _shiftMonth(-1),
                                  onNext: () => _shiftMonth(1),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: s(12)),
                                child: const Divider(
                                  height: 24,
                                  thickness: 1,
                                  color: Color(0xFFE5E5E5),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  s(12),
                                  0,
                                  s(12),
                                  s(16),
                                ),
                                child: _FriendsCard(figma: figma),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.figma, required this.streak, required this.studyGuardCount});

  final FigmaScale figma;
  final int streak;
  final int studyGuardCount;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final peekW = s(FigmaCalendarTokens.peekHamster.width).clamp(56.0, 80.0);
    final peekH = s(FigmaCalendarTokens.peekHamster.height).clamp(48.0, 68.0);
    return SizedBox(
      width: double.infinity,
      child: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: s(168).clamp(120, 190),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(s(FigmaCalendarTokens.panelRadius)),
              ),
              gradient: const LinearGradient(
                begin: Alignment(-0.6, -0.4),
                end: Alignment(0.8, 1),
                colors: [
                  FigmaCalendarTokens.headerGradientStart,
                  FigmaCalendarTokens.headerGradientEnd,
                ],
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(s(16), s(20), s(12), s(8)),
              child: Row(
                children: [
                  FigmaSvg(
                    FigmaAssets.statStreak,
                    width: s(FigmaCalendarTokens.headerFlame.width).clamp(16, 24),
                    height: s(FigmaCalendarTokens.headerFlame.height).clamp(20, 28),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: s(8)),
                  Expanded(
                    child: Text(
                      '목표일까지 D-${StreakCalendarMock.daysUntilGoal} !',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: s(12).clamp(11, 14),
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                  FigmaPng(
                    FigmaAssets.calendarPeekHamster,
                    width: peekW,
                    height: peekH,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(s(12), 0, s(12), s(12)),
              child: Container(
                padding: EdgeInsets.all(s(10).clamp(8, 14)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    s(FigmaCalendarTokens.cardRadius),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _StreakStat(figma: figma, streak: streak),
                    ),
                    SizedBox(width: s(8).clamp(6, 10)),
                    Expanded(
                      flex: 2,
                      child: _PauseStat(figma: figma, studyGuardCount: studyGuardCount),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({required this.figma, required this.streak});

  final FigmaScale figma;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return Container(
      padding: EdgeInsets.fromLTRB(s(8), s(8), s(8), s(8)),
      decoration: BoxDecoration(
        color: FigmaCalendarTokens.panel,
        borderRadius: BorderRadius.circular(s(FigmaCalendarTokens.cardRadius)),
      ),
      child: Row(
        children: [
          _VerticalBar(
            figma: figma,
            width: 10,
            height: 48,
            fillHeight: 36,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                FigmaCalendarTokens.streakBarTop,
                FigmaCalendarTokens.streakBarBottom,
              ],
            ),
          ),
          SizedBox(width: s(6)),
          FigmaSvg(
            FigmaAssets.statStreak,
            width: s(28).clamp(22.0, 34.0).toDouble(),
            height: s(36).clamp(28.0, 44.0).toDouble(),
            fit: BoxFit.contain,
          ),
          SizedBox(width: s(6)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '연속학습',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: s(10).clamp(9, 12),
                    color: FigmaCalendarTokens.muted,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$streak',
                        style: TextStyle(
                          fontSize: s(28).clamp(20, 32),
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: s(2), left: s(2)),
                        child: Text(
                          '일',
                          style: TextStyle(
                            fontSize: s(12).clamp(10, 14),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseStat extends StatelessWidget {
  const _PauseStat({required this.figma, required this.studyGuardCount});

  final FigmaScale figma;
  final int studyGuardCount;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return Container(
      padding: EdgeInsets.all(s(8).clamp(6, 12)),
      decoration: BoxDecoration(
        color: FigmaCalendarTokens.panel,
        borderRadius: BorderRadius.circular(s(FigmaCalendarTokens.cardRadius)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '일시멈춤',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: s(10).clamp(9, 12),
              color: FigmaCalendarTokens.muted,
              height: 1.1,
            ),
          ),
          SizedBox(height: s(6)),
          Row(
            children: List.generate(3, (index) {
              final remaining = studyGuardCount.clamp(0, 3);
              final isAvailable = index >= 3 - remaining;
              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : s(4)),
                child: FigmaSvg(
                  isAvailable
                      ? FigmaAssets.calendarDropOn
                      : FigmaAssets.calendarDropOff,
                  width: s(FigmaCalendarTokens.dropFilled.width).clamp(8, 12),
                  height: s(FigmaCalendarTokens.dropFilled.height).clamp(12, 16),
                  fit: BoxFit.contain,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _VerticalBar extends StatelessWidget {
  const _VerticalBar({
    required this.figma,
    required this.width,
    required this.height,
    required this.fillHeight,
    required this.gradient,
  });

  final FigmaScale figma;
  final double width;
  final double height;
  final double fillHeight;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return SizedBox(
      width: s(width),
      height: s(height),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: s(width),
            height: s(height),
            decoration: BoxDecoration(
              color: FigmaCalendarTokens.barTrack,
              borderRadius: BorderRadius.circular(s(FigmaCalendarTokens.barRadius)),
            ),
          ),
          Container(
            width: s(width),
            height: s(fillHeight),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(s(FigmaCalendarTokens.barRadius)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlexibleBar extends StatelessWidget {
  const _FlexibleBar({
    required this.fillFraction,
    required this.height,
    required this.color,
    this.label,
  });

  final double fillFraction;
  final double height;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFE5E5E5)),
            FractionallySizedBox(
              widthFactor: fillFraction.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: ColoredBox(color: color),
            ),
            if (label != null)
              Center(
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: height >= 10 ? 8 : 6,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.figma,
    required this.month,
    required this.completedDates,
    required this.onPrev,
    required this.onNext,
  });

  final FigmaScale figma;
  final DateTime month;
  final Set<String> completedDates;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  bool _completed(DateTime day) {
    return completedDates.contains(DateHelper.todayKey(day));
  }

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = leading + daysInMonth;
    final rows = ((cells + 6) ~/ 7);
    final latest = completedDates
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, date) {
      if (latest == null || date.isAfter(latest)) return date;
      return latest;
    });

    return Container(
      padding: EdgeInsets.fromLTRB(s(10), s(12), s(10), s(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(FigmaCalendarTokens.cardRadius)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onPrev,
                icon: Icon(Icons.chevron_left, size: s(22), color: Colors.black54),
              ),
              Expanded(
                child: Text(
                  '${month.year}년 ${month.month}월',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: s(16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onNext,
                icon: Icon(Icons.chevron_right, size: s(22), color: Colors.black54),
              ),
            ],
          ),
          SizedBox(height: s(4)),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    _weekdays[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: s(11),
                      color: i == 0
                          ? FigmaCalendarTokens.sunday
                          : i == 6
                              ? FigmaCalendarTokens.saturday
                              : Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: s(8)),
          for (var r = 0; r < rows; r++)
            Padding(
              padding: EdgeInsets.only(bottom: s(6)),
              child: Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(
                      child: _DayCell(
                        figma: figma,
                        day: _dayFor(leading, r, c, daysInMonth),
                        completed: _dayFor(leading, r, c, daysInMonth) != null &&
                            _completed(
                              DateTime(
                                month.year,
                                month.month,
                                _dayFor(leading, r, c, daysInMonth)!,
                              ),
                            ),
                        latest: latest != null &&
                          _dayFor(leading, r, c, daysInMonth) != null &&
                            month.year == latest.year &&
                            month.month == latest.month &&
                            _dayFor(leading, r, c, daysInMonth) == latest.day,
                        connectLeft: _connect(leading, r, c, daysInMonth, -1),
                        connectRight: _connect(leading, r, c, daysInMonth, 1),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int? _dayFor(int leading, int row, int col, int daysInMonth) {
    final index = row * 7 + col - leading + 1;
    if (index < 1 || index > daysInMonth) return null;
    return index;
  }

  bool _connect(int leading, int row, int col, int daysInMonth, int delta) {
    final day = _dayFor(leading, row, col, daysInMonth);
    final neighbor = _dayFor(leading, row, col + delta, daysInMonth);
    if (day == null || neighbor == null) return false;
    return _completed(DateTime(month.year, month.month, day)) &&
        _completed(DateTime(month.year, month.month, neighbor));
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.figma,
    required this.day,
    required this.completed,
    required this.latest,
    required this.connectLeft,
    required this.connectRight,
  });

  final FigmaScale figma;
  final int? day;
  final bool completed;
  final bool latest;
  final bool connectLeft;
  final bool connectRight;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    if (day == null) return SizedBox(height: s(36));

    final circle = latest
        ? Container(
            width: s(26),
            height: s(26),
            decoration: const BoxDecoration(
              color: FigmaCalendarTokens.streakTeal,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.check, size: s(14), color: Colors.white),
          )
        : completed
            ? Container(
                width: s(26),
                height: s(26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FigmaCalendarTokens.streakTeal,
                    width: s(1.5),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(fontSize: s(11), color: Colors.black87),
                ),
              )
            : SizedBox(
                width: s(26),
                height: s(26),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(fontSize: s(11), color: Colors.black87),
                  ),
                ),
              );

    return SizedBox(
      height: s(36),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (connectLeft)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: s(2),
                width: s(18),
                color: FigmaCalendarTokens.streakTeal.withValues(alpha: 0.7),
              ),
            ),
          if (connectRight)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: s(2),
                width: s(18),
                color: FigmaCalendarTokens.streakTeal.withValues(alpha: 0.7),
              ),
            ),
          circle,
          if (completed && !latest)
            Positioned(
              bottom: 0,
              child: Icon(
                Icons.check,
                size: s(8),
                color: FigmaCalendarTokens.streakTeal,
              ),
            ),
        ],
      ),
    );
  }
}

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({required this.figma});

  final FigmaScale figma;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final friends = StreakCalendarMock.friends;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s(12), s(12), s(12), s(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(FigmaCalendarTokens.cardRadius)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '이번 달 친구와의 경쟁!',
                  style: TextStyle(
                    fontSize: s(12).clamp(11, 14),
                    color: Colors.black,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(s(14)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                ),
                child: Padding(
                  padding: EdgeInsets.all(s(4)),
                  child: Icon(
                    Icons.person_add_alt_1,
                    size: s(18).clamp(16, 22),
                    color: FigmaCalendarTokens.streakTeal,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < friends.length; i++) ...[
                if (i > 0) SizedBox(width: s(6)),
                Expanded(
                  flex: i == 0 ? 3 : 2,
                  child: _FriendRank(
                    figma: figma,
                    friend: friends[i],
                    podium: switch (i) {
                      0 => FigmaAssets.calendarPodium1,
                      1 => FigmaAssets.calendarPodium2,
                      2 => FigmaAssets.calendarPodium3,
                      _ => FigmaAssets.calendarPodium4,
                    },
                    large: i == 0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendRank extends StatelessWidget {
  const _FriendRank({
    required this.figma,
    required this.friend,
    required this.podium,
    required this.large,
  });

  final FigmaScale figma;
  final StreakFriendMock friend;
  final String podium;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final hamster = (large ? s(72).clamp(56.0, 88.0) : s(48).clamp(40.0, 60.0))
        .toDouble();
    final podiumH = (large ? s(56).clamp(44.0, 68.0) : s(40).clamp(32.0, 52.0))
        .toDouble();
    final label = friend.rank == 1
        ? '1위. ${friend.name}'
        : '${friend.rank}위';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: hamster + podiumH * 0.45,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              FigmaSvg(
                podium,
                width: hamster,
                height: podiumH,
                fit: BoxFit.contain,
              ),
              Positioned(
                top: 0,
                child: SizedBox(
                  width: hamster,
                  height: hamster,
                  child: ShopHamsterSprite(
                    column: friend.spriteCol,
                    row: friend.spriteRow,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: s(4)),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: s(large ? 11 : 9).clamp(8, 12),
            color: Colors.black,
          ),
        ),
        SizedBox(height: s(4)),
        _FlexibleBar(
          fillFraction: friend.learned / friend.goal,
          height: large ? 10 : 7,
          color: FigmaCalendarTokens.streakTeal,
          label: '${friend.learned}/${friend.goal}',
        ),
      ],
    );
  }
}
