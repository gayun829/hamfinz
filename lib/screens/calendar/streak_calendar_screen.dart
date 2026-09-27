import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../services/friend_service.dart';
import '../../utils/date_helper.dart';

import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/home_bottom_nav.dart';
import '../friends/add_friend_screen.dart';

const _mint = Color(0xFFDEFDFE);
const _cyan = Color(0xFF65D6F8);
const _band = Color(0xFFE0FEFF);

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({
    super.key,
    this.streak = 0,
    this.studyGuardCount = 0,
    this.completedDates = const <String>{},
    this.goalDays = 16,
    this.onNavTap,
    this.loadFriendsRanking,
  });

  final int streak;
  final int studyGuardCount;
  final Set<String> completedDates;
  final int goalDays;
  final ValueChanged<int>? onNavTap;

  /// 친구 순위를 불러온다. 없으면(테스트 등) 친구가 없는 걸로 본다.
  final Future<FriendsRanking> Function()? loadFriendsRanking;

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  DateTime _month = DateHelper.koreaNow();
  FriendsRanking? _ranking;
  bool _rankingFailed = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final load = widget.loadFriendsRanking;
    var ranking = FriendsRanking.empty;
    var failed = false;
    if (load != null) {
      try {
        ranking = await load();
      } catch (_) {
        // 순위를 못 불러와도 캘린더는 보여야 하니 카드에만 안내를 띄운다.
        failed = true;
      }
    }
    if (!mounted) return;
    setState(() {
      _ranking = ranking;
      _rankingFailed = failed;
    });
  }

  Future<void> _openAddFriend() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddFriendScreen()));
    await _loadFriends();
  }

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
                    _FriendsCard(
                      scale: scale,
                      ranking: _ranking,
                      failed: _rankingFailed,
                      onAddFriend: _openAddFriend,
                    ),
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
    final currentRun = _currentRun(today);
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
                          final isToday = date == today;
                          final todayCompleted = completed && isToday;
                          final inRun = completed && currentRun.contains(key);
                          final runStart =
                              col == 0 ||
                              !currentRun.contains(
                                DateHelper.dateKey(
                                  DateTime(date.year, date.month, date.day - 1),
                                ),
                              ) ||
                              date.day == 1;
                          final runEnd =
                              col == 6 ||
                              isToday ||
                              !currentRun.contains(
                                DateHelper.dateKey(
                                  DateTime(date.year, date.month, date.day + 1),
                                ),
                              ) ||
                              date.day == count;
                          final pill = Radius.circular(s(100));
                          return Semantics(
                            label: '$key${completed ? ', 학습 완료' : ''}',
                            child: SizedBox(
                              height: s(42),
                              child: LayoutBuilder(
                                builder: (context, cell) {
                                  final half = cell.maxWidth / 2;
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 오늘과 이어진 연속학습일은 한 줄의 띠로 잇는다.
                                      // 오늘 칸에서는 띠가 가운데까지만 오고 햄스터가 덮는다.
                                      if (inRun)
                                        Positioned(
                                          key: ValueKey('streak-band-$key'),
                                          left: runStart ? half - s(16) : 0,
                                          right: runEnd
                                              ? (isToday ? half : half - s(18))
                                              : 0,
                                          height: s(23),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: _band,
                                              borderRadius:
                                                  BorderRadius.horizontal(
                                                    left: runStart
                                                        ? pill
                                                        : Radius.zero,
                                                    right: runEnd && !isToday
                                                        ? pill
                                                        : Radius.zero,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      if (todayCompleted)
                                        Transform.translate(
                                          offset: Offset(0, -s(2.1)),
                                          child: FigmaSvg(
                                            FigmaAssets.calendarTodayHamster,
                                            key: ValueKey('today-hamster-$key'),
                                            width: s(39),
                                            height: s(27.3),
                                          ),
                                        )
                                      else if (completed && !inRun)
                                        Container(
                                          key: ValueKey('study-circle-$key'),
                                          width: s(23),
                                          height: s(23),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFB3E5FC),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontSize: s(12),
                                          color: !inMonth
                                              ? const Color(0xFFD8D8D8)
                                              : completed || isToday
                                              ? Colors.black
                                              : const Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  );
                                },
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

  /// 오늘부터 거꾸로 끊김 없이 이어지는 학습일들. 오늘 학습했을 때만 띠로 잇고,
  /// 그 밖의 학습일은 동그라미로 둔다.
  Set<String> _currentRun(DateTime today) {
    var day = today;
    final run = <String>{};
    while (completedDates.contains(DateHelper.dateKey(day))) {
      run.add(DateHelper.dateKey(day));
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return run;
  }
}

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({
    required this.scale,
    required this.ranking,
    required this.failed,
    required this.onAddFriend,
  });
  final double scale;

  /// null이면 아직 불러오는 중.
  final FriendsRanking? ranking;
  final bool failed;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final ranking = this.ranking;
    final people = ranking?.participants ?? const <FriendRankEntry>[];
    // 1위의 연속학습을 꽉 찬 막대로 두고 나머지는 그 대비로 채운다.
    final leaderStreak = people.isEmpty ? 0 : people.first.streak;
    final message = failed
        ? '친구 순위를 불러오지 못했어요'
        : ranking != null && ranking.friendCount == 0
        ? '친구가 아직 없어요..'
        : null;
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
          if (message != null)
            Center(
              child: Text(
                message,
                style: TextStyle(fontSize: s(16), color: Colors.black),
              ),
            )
          else
            for (var i = 0; i < people.length && i < 4; i++)
              Positioned(
                left: s([30.0, 160.0, 230.0, 272.0][i]),
                top: s([46.0, 20.0, 126.0, 60.0][i]),
                width: s([118.0, 78.0, 66.0, 48.0][i]),
                child: _Rank(
                  scale: scale,
                  entry: people[i],
                  leaderStreak: leaderStreak,
                  index: i,
                ),
              ),
          Positioned(
            right: s(4),
            top: 0,
            child: IconButton(
              tooltip: '친구 추가',
              onPressed: onAddFriend,
              icon: Icon(Icons.person_add_alt_1, size: s(21), color: _cyan),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rank extends StatelessWidget {
  const _Rank({
    required this.scale,
    required this.entry,
    required this.leaderStreak,
    required this.index,
  });
  final double scale;
  final FriendRankEntry entry;
  final int leaderStreak;
  final int index;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final height = [128.0, 96.0, 61.0, 46.0][index];
    final name = entry.isMe ? '나' : entry.nickname;
    return Semantics(
      label: '${entry.rank}위 $name, 연속학습 ${entry.streak}일',
      excludeSemantics: true,
      child: Column(
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
              child: Text(
                '1위 $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: s(15)),
              ),
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
                      '${entry.rank}',
                      style: TextStyle(fontSize: s(10), color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: s(3)),
                ],
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fraction = leaderStreak > 0
                          ? (entry.streak / leaderStreak).clamp(0.0, 1.0)
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
                                left:
                                    ((constraints.maxWidth * fraction) - height)
                                        .clamp(
                                          0.0,
                                          constraints.maxWidth - height,
                                        ),
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
      ),
    );
  }
}
