import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../services/friend_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_calendar_tokens.dart';
import '../../theme/figma_home_fonts.dart';
import '../../utils/date_helper.dart';

import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/stroked_text.dart';
import '../../widgets/home_bottom_nav.dart';
import '../../widgets/shop/shop_widgets.dart';
import '../friends/add_friend_screen.dart';

typedef _T = FigmaCalendarTokens;

// Figma `1006:2899` 연속학습 캘린더_친구경쟁 없는 버전.
const _mint = Color(0xFFE0FEFF);
const _cyan = Color(0xFF65D6F8);

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({
    super.key,
    this.streak = 0,
    this.studyGuardCount = 0,
    this.completedDates = const <String>{},
    this.goalDays = 16,
    this.onNavTap,
    this.loadFriendsRanking,
    this.today,
  });

  final int streak;
  final int studyGuardCount;
  final Set<String> completedDates;
  final int goalDays;
  final ValueChanged<int>? onNavTap;

  /// 친구 순위를 불러온다. 없으면(테스트 등) 친구가 없는 걸로 본다.
  final Future<FriendsRanking> Function()? loadFriendsRanking;

  /// 오늘 날짜. 테스트에서 날짜를 고정할 때만 넘기고, 없으면 한국 시간 오늘이다.
  final DateTime? today;

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  late DateTime _month = widget.today ?? DateHelper.koreaNow();
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
    backgroundColor: const Color(0xFFFBFBFB),
    bottomNavigationBar: SafeArea(
      top: false,
      child: HomeBottomNav(currentIndex: 1, onTap: _navigate),
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / 393;
        double s(double value) => value * scale;
        final safeTop = MediaQuery.paddingOf(context).top;
        return DefaultTextStyle.merge(
          style: const TextStyle(height: AppTheme.figmaAutoLineHeight),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    // CSS `linear-gradient(54.41deg, ...)`를 393x304 상자의 시작·끝점으로 옮긴 값.
                    gradient: LinearGradient(
                      begin: Alignment(-1.0275, 0.9507),
                      end: Alignment(1.0275, -0.9507),
                      stops: [0.13104, 0.98552],
                      colors: [Color(0xFFB7F0F2), Color(0xFF3CC6FF)],
                    ),
                  ),
                  // Figma 좌표는 상태바를 포함한 프레임 기준이라 SafeArea로 또 밀지 않는다.
                  child: SizedBox(
                    height: s(304),
                    child: Stack(
                      children: [
                        Positioned(
                          // 화살표(Group 345) 가운데는 (32.32, 42.53)이다.
                          left: s(32.322) - 24,
                          // 상태바가 높은 기기에서도 화살표가 상태바 위로 올라가지 않게 한다.
                          top: math.max(s(42.535), safeTop) - 24,
                          child: IconButton(
                            tooltip: '뒤로가기',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 48,
                              height: 48,
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                            // SVG는 선 두께만큼 바깥 여백을 포함한 크기다.
                            icon: FigmaSvg(
                              FigmaAssets.friendsBackChevron,
                              width: s(13.6514),
                              height: s(24.0617),
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFD9FAFF),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: s(44),
                          top: s(89),
                          child: FigmaSvg(
                            FigmaAssets.calendarGoalFlame,
                            width: s(27.6372),
                            height: s(36.9771),
                          ),
                        ),
                        Positioned(
                          left: s(82),
                          top: s(100),
                          child: Text(
                            '목표까지 D-${(widget.goalDays - widget.streak).clamp(0, widget.goalDays)}',
                            style: TextStyle(
                              fontSize: s(20),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          left: s(24),
                          top: s(142),
                          width: s(345),
                          height: s(138),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(s(13)),
                            ),
                          ),
                        ),
                        Positioned(
                          left: s(44),
                          top: s(162),
                          width: s(182),
                          height: s(98),
                          child: _StreakStat(
                            scale: scale,
                            value: widget.streak,
                            progress: widget.goalDays > 0
                                ? widget.streak / widget.goalDays
                                : 0,
                          ),
                        ),
                        Positioned(
                          left: s(246),
                          top: s(162),
                          width: s(103),
                          height: s(97.684),
                          child: _GuardStat(
                            scale: scale,
                            value: widget.studyGuardCount,
                          ),
                        ),
                        Positioned(
                          left: s(240),
                          top: s(59),
                          child: FigmaSvg(
                            FigmaAssets.calendarHeaderHamster,
                            width: s(115),
                            height: s(84.285),
                          ),
                        ),
                        // 햄스터 앞발은 흰 카드 위에 걸친다.
                        for (final left in [249.0, 323.0])
                          Positioned(
                            left: s(left),
                            top: s(132),
                            width: s(23),
                            height: s(18),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD27E),
                                borderRadius: BorderRadius.all(
                                  Radius.elliptical(s(11.5), s(9)),
                                ),
                              ),
                            ),
                          ),
                      ],
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
                        today: widget.today,
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
                        child: const Divider(
                          height: 1,
                          color: Color(0xFFE6E6E6),
                        ),
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
          ),
        );
      },
    ),
  );
}

/// 카드 그림자: Figma는 같은 크기의 `#E5E5E5` 사각형을 왼쪽으로 2 밀어 흐린다(6.1).
/// 내보낸 화면의 번짐이 시그마 약 5.5라 Flutter blurRadius로 8.7이다.
BoxDecoration _card(double scale) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(13.036 * scale),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFFE5E5E5),
      blurRadius: 8.7 * scale,
      offset: Offset(-2 * scale, 0),
    ),
  ],
);

TextStyle _statLabel(double scale) => TextStyle(
  fontSize: 12 * scale,
  fontWeight: FontWeight.w400,
  color: const Color(0xFF898989),
);

/// 큰 숫자 옆 단위. Figma는 숫자 윗변에서 16.48 아래에 단위 윗변을 둔다.
class _StatValue extends StatelessWidget {
  const _StatValue({
    required this.scale,
    required this.value,
    required this.unit,
    required this.gap,
  });
  final double scale;
  final int value;
  final String unit;
  final double gap;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: s(32.088),
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(width: s(gap)),
        Padding(
          padding: EdgeInsets.only(top: s(16.484)),
          child: Text(
            unit,
            style: TextStyle(
              fontSize: s(12.033),
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

/// `1006:2915` 연속학습 상자(182x98): 막대, 불꽃, 일수.
class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.scale,
    required this.value,
    required this.progress,
  });
  final double scale;
  final int value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    return Semantics(
      label: '연속학습 $value일',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(s(6.5)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: s(18.758),
              top: s(16.422),
              child: Container(
                width: s(_T.streakBar.width),
                height: s(_T.streakBar.height),
                decoration: BoxDecoration(
                  color: _T.barTrack,
                  borderRadius: BorderRadius.circular(s(_T.barRadius)),
                ),
                alignment: Alignment.bottomCenter,
                // 채움은 최소 트랙 폭만큼의 원으로 시작해야 둥근 트랙 밖으로
                // 납작하게 삐져나오지 않는다.
                child: progress > 0
                    ? Container(
                        width: s(_T.streakBar.width),
                        height:
                            (s(_T.streakBar.height) * progress.clamp(0.0, 1.0))
                                .clamp(
                                  s(_T.streakBar.width),
                                  s(_T.streakBar.height),
                                ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(s(_T.barRadius)),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [_T.streakBarTopStop, 1],
                            colors: [_T.streakBarTop, _T.streakBarBottom],
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              left: s(43.22),
              top: s(24.46),
              child: FigmaSvg(
                FigmaAssets.calendarStreakFlame,
                width: s(_T.streakFlame.width),
                height: s(_T.streakFlame.height),
              ),
            ),
            Positioned(
              left: s(104.732),
              top: s(20.721),
              child: Text('연속학습', style: _statLabel(scale)),
            ),
            Positioned(
              left: s(105),
              top: s(44),
              child: _StatValue(
                scale: scale,
                value: value,
                unit: '일',
                gap: 2.346,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `1006:2932` 오른쪽 상자(103x97.7): 글자는 상자 가운데에 맞춘다.
class _GuardStat extends StatelessWidget {
  const _GuardStat({required this.scale, required this.value});
  final double scale;
  final int value;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    return Semantics(
      label: '방어권 보유 $value개',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(s(6.5)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: s(21),
              child: Text(
                '방어권 보유',
                textAlign: TextAlign.center,
                style: _statLabel(scale),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: s(44),
              child: Center(
                child: _StatValue(
                  scale: scale,
                  value: value,
                  unit: '개',
                  gap: 0.346,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `1006:2939` 캘린더 카드(345 폭). 날짜 칸은 Figma 요일 글자 가운데에 맞춘
/// 44.37 간격이고, 줄 간격은 41.976이다.
class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.scale,
    required this.month,
    required this.today,
    required this.completedDates,
    required this.onShift,
  });
  final double scale;
  final DateTime month;
  final DateTime? today;
  final Set<String> completedDates;
  final ValueChanged<int> onShift;

  static const _rowHeight = 41.976;
  static const _bandHeight = 23.0;

  /// 띠 윗변: 숫자 가운데보다 0.27 아래로 띠 가운데가 온다.
  static const _bandTop = _rowHeight / 2 - _bandHeight / 2 + 0.27;

  /// `1006:2943` 햄스터(39.22x27.28)는 아랫변을 띠 아랫변에 맞춘다.
  static const _hamster = Size(39.2248, 27.2814);
  static const _hamsterTop = _bandTop + _bandHeight - 27.2814;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final leading = DateTime(month.year, month.month).weekday % 7;
    final count = DateTime(month.year, month.month + 1, 0).day;
    final rows = (leading + count + 6) ~/ 7;
    final now = this.today ?? DateHelper.koreaNow();
    final today = DateTime(now.year, now.month, now.day);
    final streakHead = _streakHead(today);
    final textStyle = TextStyle(
      fontSize: s(11.448),
      fontWeight: FontWeight.w500,
    );
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 100) onShift(velocity < 0 ? 1 : -1);
      },
      child: Container(
        decoration: _card(scale),
        padding: EdgeInsets.fromLTRB(s(15.62), s(27), s(18.82), s(16.82)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: s(20 * AppTheme.figmaAutoLineHeight),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: s(10.38),
                    top: 0,
                    child: Text(
                      '${month.year}년 ${month.month}월',
                      style: TextStyle(
                        fontSize: s(20),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // 시안에는 없는 달 이동 버튼. 제목 줄 높이는 그대로 둔다.
                  Positioned(
                    right: 0,
                    top: s(10 * AppTheme.figmaAutoLineHeight) - 24,
                    child: Row(
                      children: [
                        for (final (delta, tooltip, icon) in [
                          (-1, '이전 달', Icons.chevron_left),
                          (1, '다음 달', Icons.chevron_right),
                        ])
                          IconButton(
                            tooltip: tooltip,
                            onPressed: () => onShift(delta),
                            constraints: BoxConstraints.tightFor(
                              width: s(28),
                              height: 48,
                            ),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              icon,
                              size: s(18),
                              color: const Color(0xFFAAAAAA),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: s(52.2)),
            Row(
              children: [
                for (final label in ['일', '월', '화', '수', '목', '금', '토'])
                  Expanded(
                    child: Center(child: Text(label, style: textStyle)),
                  ),
              ],
            ),
            SizedBox(height: s(9.68)),
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
                          final isHead = completed && key == streakHead;
                          final prevCompleted = completedDates.contains(
                            DateHelper.dateKey(
                              DateTime(date.year, date.month, date.day - 1),
                            ),
                          );
                          final nextCompleted = completedDates.contains(
                            DateHelper.dateKey(
                              DateTime(date.year, date.month, date.day + 1),
                            ),
                          );
                          final inRun =
                              completed && (prevCompleted || nextCompleted);
                          final runStart =
                              col == 0 || !prevCompleted || date.day == 1;
                          final runEnd =
                              col == 6 ||
                              isHead ||
                              !nextCompleted ||
                              date.day == count;
                          final pill = Radius.circular(s(100));
                          return Semantics(
                            label: '$key${completed ? ', 학습 완료' : ''}',
                            child: SizedBox(
                              height: s(_rowHeight),
                              child: LayoutBuilder(
                                builder: (context, cell) {
                                  final half = cell.maxWidth / 2;
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // 이어진 학습일은 한 줄의 띠로 잇는다. 끝은 숫자
                                      // 가운데에서 왼쪽 16.9, 오른쪽 18만큼 나간다.
                                      // 햄스터 칸에서는 햄스터 가운데 직전에서 끝나고
                                      // 햄스터가 그 끝을 덮는다.
                                      if (inRun)
                                        Positioned(
                                          key: ValueKey('streak-band-$key'),
                                          left: runStart ? half - s(16.9) : 0,
                                          right: runEnd
                                              ? half - s(isHead ? -1.28 : 18)
                                              : 0,
                                          top: s(_bandTop),
                                          height: s(_bandHeight),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: _mint,
                                              borderRadius:
                                                  BorderRadius.horizontal(
                                                    left: runStart
                                                        ? pill
                                                        : Radius.zero,
                                                    right: runEnd
                                                        ? pill
                                                        : Radius.zero,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      if (isHead)
                                        Positioned(
                                          left:
                                              half -
                                              s(_hamster.width / 2 - 0.33),
                                          top: s(_hamsterTop),
                                          child: FigmaSvg(
                                            FigmaAssets.calendarTodayHamster,
                                            key: ValueKey('today-hamster-$key'),
                                            width: s(_hamster.width),
                                            height: s(_hamster.height),
                                          ),
                                        )
                                      else if (completed && !inRun)
                                        Positioned(
                                          key: ValueKey('study-circle-$key'),
                                          left: half - s(_bandHeight / 2),
                                          top: s(_bandTop),
                                          width: s(_bandHeight),
                                          height: s(_bandHeight),
                                          child: const DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: _mint,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      Center(
                                        child: Text(
                                          '${date.day}',
                                          style: textStyle.copyWith(
                                            color: !inMonth
                                                ? const Color(0xFFD9D9D9)
                                                : completed || isToday
                                                ? Colors.black
                                                : const Color(0xFF8C8C8C),
                                          ),
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

  /// 햄스터를 얹을 날: 오늘 학습했으면 오늘, 아직이면 연속이 살아 있는 어제.
  /// 자정이 지나 학습 전이어도 어제까지의 연속 표시가 사라지지 않는다.
  String? _streakHead(DateTime today) {
    final todayKey = DateHelper.dateKey(today);
    if (completedDates.contains(todayKey)) return todayKey;
    final yesterdayKey = DateHelper.dateKey(
      DateTime(today.year, today.month, today.day - 1),
    );
    return completedDates.contains(yesterdayKey) ? yesterdayKey : null;
  }
}

/// Figma 「이번 달 친구와의 경쟁!」: 위에 1~3위 단상, 아래에 전체 순위 목록.
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
    final textStyle = TextStyle(
      fontFamily: FigmaHomeFonts.pretendard,
      fontSize: s(16),
      fontWeight: FontWeight.w500,
      color: Colors.black,
    );
    return Container(
      decoration: _card(scale),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(s(18), s(6), s(4), 0),
            child: Row(
              children: [
                Expanded(child: Text('이번 달 친구와의 경쟁!', style: textStyle)),
                IconButton(
                  tooltip: '친구 추가',
                  onPressed: onAddFriend,
                  icon: Icon(Icons.person_add_alt_1, size: s(21), color: _cyan),
                ),
              ],
            ),
          ),
          if (message != null)
            SizedBox(
              height: s(190),
              child: Center(child: Text(message, style: textStyle)),
            )
          else if (people.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(s(20), s(4), s(20), s(18)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < people.length && i < 3; i++)
                    _Podium(
                      scale: scale,
                      entry: people[i],
                      leaderStreak: leaderStreak,
                      index: i,
                    ),
                  // 2·3위 자리가 비어도 1위는 왼쪽에 그대로 둔다.
                  for (var i = people.length; i < 3; i++)
                    SizedBox(width: s(_Podium.widths[i])),
                ],
              ),
            ),
            Divider(
              height: 1,
              indent: s(18),
              endIndent: s(18),
              color: const Color(0xFFE6E6E6),
            ),
            SizedBox(height: s(8)),
            for (var i = 0; i < people.length; i++)
              _RankRow(scale: scale, entry: people[i], index: i),
            SizedBox(height: s(10)),
          ] else
            SizedBox(height: s(190)),
        ],
      ),
    );
  }
}

/// 1~3위 단상 하나: 햄스터, 이름, 순위 동그라미와 연속학습 막대.
class _Podium extends StatelessWidget {
  const _Podium({
    required this.scale,
    required this.entry,
    required this.leaderStreak,
    required this.index,
  });
  final double scale;
  final FriendRankEntry entry;
  final int leaderStreak;
  final int index;

  static const widths = [118.0, 78.0, 66.0];
  static const _heights = [128.0, 82.0, 66.0];
  static const _podiums = [
    FigmaAssets.calendarPodium1,
    FigmaAssets.calendarPodium2,
    FigmaAssets.calendarPodium3,
  ];
  static const _hamsters = [
    'assets/figma/calendar/hamster_rank_1.png',
    'assets/figma/calendar/hamster_rank_2.png',
    'assets/figma/calendar/hamster_floating.png',
  ];
  static const _nameSizes = [12.815, 10.0, 8.277];

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final height = _heights[index];
    final name = entry.isMe ? '나' : entry.nickname;
    final first = index == 0;
    final barHeight = s(first ? 12 : 9);
    final fraction = leaderStreak > 0
        ? (entry.streak / leaderStreak).clamp(0.0, 1.0)
        : 0.0;
    return Semantics(
      label: '${entry.rank}위 $name, 연속학습 ${entry.streak}일',
      excludeSemantics: true,
      child: SizedBox(
        width: s(widths[index]),
        child: Column(
          children: [
            SizedBox(
              height: s(height),
              child: Stack(
                children: [
                  Positioned.fill(
                    top: s(height * 0.3),
                    child: FigmaSvg(_podiums[index], fit: BoxFit.contain),
                  ),
                  Positioned.fill(
                    bottom: s(8),
                    child: FigmaPng(_hamsters[index], fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
            SizedBox(height: s(first ? 10 : 6)),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: FigmaHomeFonts.pretendard,
                fontSize: s(_nameSizes[index]),
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: s(first ? 6 : 4)),
            Row(
              children: [
                Container(
                  width: s(first ? 18 : 14),
                  height: s(first ? 18 : 14),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB2EFF2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontSize: s(first ? 13.571 : 10),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF636363),
                    ),
                  ),
                ),
                SizedBox(width: s(3)),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Container(
                      height: barHeight,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(barHeight),
                      ),
                      child: fraction == 0
                          ? null
                          : Container(
                              width: (constraints.maxWidth * fraction).clamp(
                                barHeight,
                                constraints.maxWidth,
                              ),
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.all(barHeight * 0.18),
                              decoration: BoxDecoration(
                                color: _cyan,
                                borderRadius: BorderRadius.circular(barHeight),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF36C3FA),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 전체 순위 한 줄. 내 줄은 하늘색 띠로 칠하고, 1~3위는 아바타에 배지를 단다.
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.scale,
    required this.entry,
    required this.index,
  });
  final double scale;
  final FriendRankEntry entry;
  final int index;

  // 아바타는 각자 입은 스킨·악세서리 얼굴이다(`looks/{uid}`). 배경색은 줄마다 바꾼다.
  static const _avatarColors = [
    Color(0xFFA8E27E),
    Color(0xFFFFA98A),
    Color(0xFF5ED3E8),
    Color(0xFF7CC8FA),
  ];

  /// 순위 숫자는 Thin에 같은 색 외곽선(Figma 바깥쪽 0.8)을 둘러 굵어 보인다.
  /// Flutter stroke는 글자선 가운데 정렬이라 두 배로 준다.
  static const _rankStrokeWidth = 1.6;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final color = _avatarColors[index % _avatarColors.length];
    final rank = entry.rank;
    return Container(
      height: s(66),
      color: entry.isMe ? const Color(0xFFDFFBFF) : null,
      padding: EdgeInsets.symmetric(horizontal: s(18)),
      child: Row(
        children: [
          SizedBox(
            width: s(22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StrokedText(
                '$rank',
                style: TextStyle(fontSize: s(16), fontWeight: FontWeight.w100),
                color: entry.isMe
                    ? const Color(0xFF70D9FF)
                    : const Color(0xFFBBBBBB),
                strokeWidth: s(_rankStrokeWidth),
              ),
            ),
          ),
          SizedBox(width: s(12)),
          SizedBox(
            width: s(54),
            height: s(54),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  left: s(4),
                  top: s(4),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, color],
                      ),
                    ),
                    child: HamsterFace(
                      skinId: entry.look.skinId,
                      accessoryIds: entry.look.accessoryIds,
                    ),
                  ),
                ),
                // Figma: 불꽃은 아바타 동그라미 위쪽에 맞춰 왼쪽으로 8 삐져나온다.
                if (rank <= FigmaAssets.calendarRankFlames.length)
                  Positioned(
                    left: -s(4),
                    top: s(4),
                    width: s(23.229),
                    height: s(31.124),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FigmaSvg(
                            FigmaAssets.calendarRankFlames[rank - 1],
                            fit: BoxFit.fill,
                          ),
                        ),
                        Align(
                          // 숫자는 불꽃 아래 둥근 부분 가운데(높이 65%)에 온다.
                          alignment: const Alignment(0, 0.3),
                          child: StrokedText(
                            '$rank',
                            style: TextStyle(
                              fontSize: s(14.596),
                              fontWeight: FontWeight.w100,
                              height: 1.2,
                            ),
                            color: Colors.white,
                            strokeWidth: s(_rankStrokeWidth),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: s(14)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FigmaHomeFonts.pretendard,
                    fontSize: s(16),
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: s(2)),
                Text(
                  '연속학습 ${entry.streak}일',
                  style: TextStyle(
                    fontFamily: FigmaHomeFonts.pretendard,
                    fontSize: s(11),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFBBBBBB),
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
