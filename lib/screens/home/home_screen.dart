import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/interest_categories.dart';
import '../../data/learning_steps.dart';
import '../../data/quiz_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/news_service.dart';
import '../../utils/incorrect_questions.dart';
import '../../theme/home_tier_theme.dart';
import '../../theme/figma_home_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_switcher_sheet.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_canvas.dart';
import '../../widgets/figma/figma_scale.dart';
import '../calendar/streak_calendar_screen.dart';
import '../news/article_screen.dart';
import '../news/term_quiz_screen.dart';
import '../quiz/quiz_screen.dart';
import '../shop/shop_screen.dart';

/// Figma `131:5342` / `137:1375` / `137:1489` 오늘의 학습 CTA.
const _homeLearningCtaDesignHeight = 84.247;
const _homeLearningCtaHeight = _homeLearningCtaDesignHeight * 0.75;
const _homeLearningCtaWidth = 328.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.profile,
    this.showReviewStage,
    this.tierOverride,
    this.onNavTap,
  });

  /// [MainShell]에서 내려주면 학습과정 변경 시 홈 티어가 즉시 반영된다.
  final UserProfile? profile;
  final ValueChanged<int>? onNavTap;

  /// 복습 기능 연결 전, Figma 복습 홈의 집 단계를 표시하는 화면 변형.
  final bool? showReviewStage;

  /// 복습 홈 3종을 학습 진도와 독립적으로 미리 보여주기 위한 티어 지정.
  final HomeTierTheme? tierOverride;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _profile = widget.profile;
      _loading = false;
    }
    _loadNews();
    _newsTimer = Timer.periodic(_newsSlideInterval, (_) => _rotateNews());
    if (widget.profile == null) {
      _loadProfile();
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != null &&
        (widget.profile!.learningStage != oldWidget.profile?.learningStage ||
            widget.profile != oldWidget.profile)) {
      setState(() {
        _profile = widget.profile;
        _loading = false;
      });
    }
  }

  /// 뉴스바에 돌릴 TOP 10. 뉴스 탭과 같은 캐시를 쓴다(1시간 TTL).
  List<NewsItem> _news = const [];
  int _newsIndex = 0;
  Timer? _newsTimer;

  /// 뉴스바가 한 건을 보여주는 시간.
  static const _newsSlideInterval = Duration(seconds: 7);

  @override
  void dispose() {
    _newsTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshHome() async {
    await Future.wait([_loadProfile(), _loadNews()]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.instance.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _startQuiz() async {
    await _loadProfile();
    if (!mounted) return;

    final profile = _profile;
    if (profile == null) return;

    final isReview = activeCategoryNeedsReview(profile);

    if (profile.energy < QuizData.sessionEnergyCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '에너지가 부족해요. 학습 1회(${QuizData.dailyQuestionCount}문제)에 '
            '${QuizData.sessionEnergyCost} 에너지가 필요해요. '
            '(현재 ${profile.energy})',
          ),
        ),
      );
      return;
    }

    if (!isReview &&
        resolveActiveInterestCategoryId(profile.interestCategories) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('학습 카테고리를 먼저 선택해 주세요.')));
      await _openCategorySwitcher();
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(profile: profile, isReview: isReview),
      ),
    );

    if (!mounted) return;
    await _loadProfile();
  }

  Future<void> _openCategorySwitcher() async {
    final profile = _profile;
    if (profile == null) return;

    await showCategorySwitcherSheet(
      context: context,
      interestCategoryIds: profile.interestCategories,
      onCategoriesChanged: (updated) {
        if (!mounted) return;
        setState(() {
          _profile?.interestCategories = List<String>.from(updated);
        });
      },
    );
  }

  /// 뉴스바에 지금 떠 있는 기사를 연다 — 뉴스 탭에서 누른 것과 같은 경로다.
  /// 아직 못 불러왔으면 연합뉴스 경제 섹션으로 보낸다(빈 탭 방지).
  void _openNews() {
    if (_news.isEmpty) {
      ArticleScreen.open(context, NewsService.morePageUri, '금융 뉴스');
      return;
    }
    final item = _news[_newsIndex];
    ArticleScreen.open(
      context,
      Uri.parse(item.url),
      item.title,
      onStartQuiz: item.term.hasLesson
          ? (_, _) => TermQuizScreen.open(context, item.term, item.title)
          : null,
    );
  }

  /// 뉴스바에 보여줄 제목. 못 불러왔을 때도 배너가 비어 보이지 않게 한다.
  String get _newsBarTitle =>
      _news.isEmpty ? '오늘의 금융 뉴스 보러가기' : _news[_newsIndex].title;

  Future<void> _loadNews() async {
    try {
      final items = await NewsService.topFinance();
      if (!mounted) return;
      setState(() {
        _news = items;
        _newsIndex = 0;
      });
      // 목록이 들어온 시점부터 다시 세서 첫 기사도 다른 기사만큼 보이게 한다.
      _newsTimer?.cancel();
      _newsTimer = Timer.periodic(_newsSlideInterval, (_) => _rotateNews());
    } catch (_) {
      // 뉴스는 홈의 곁다리라, 실패해도 홈 전체를 오류로 만들지 않는다.
    }
  }

  void _rotateNews() {
    if (!mounted || _news.length < 2) return;
    setState(() => _newsIndex = (_newsIndex + 1) % _news.length);
  }

  Future<void> _openShop() async {
    final profile = _profile;
    if (profile == null) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ShopScreen(profile: profile)));
    await _loadProfile();
  }

  void _openStreakCalendar() {
    final profile = _profile;
    if (profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StreakCalendarScreen(
          onNavTap: widget.onNavTap,
          streak: profile.streak,
          studyGuardCount: profile.studyGuardCount,
          completedDates: profile.learningDates.toSet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('사용자 정보를 불러올 수 없습니다.')));
    }

    final canStart = profile.energy >= QuizData.sessionEnergyCost;
    final homeTier =
        widget.tierOverride ?? HomeTierTheme.forStage(profile.learningStage);
    final showReviewStage =
        widget.showReviewStage ?? activeCategoryNeedsReview(profile);

    return LayoutBuilder(
      builder: (context, constraints) {
        final figma = FigmaScale.ofWidth(
          constraints.maxWidth,
          designWidth: FigmaScale.homeDesignWidth,
        );

        return RefreshIndicator(
          onRefresh: _refreshHome,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FigmaCanvas(
                designWidth: FigmaScale.homeDesignWidth,
                designHeight: FigmaScale.homeContentHeight,
                backgroundColor: AppTheme.figmaHomeBackground,
                fit: FigmaCanvasFit.widthScroll,
                scrollable: true,
                clipContent: false,
                extraBottomPaddingDesign:
                    FigmaScale.homeContentHeight -
                    (homeTier.learningCtaTop +
                        _homeLearningCtaDesignHeight -
                        _homeLearningCtaHeight),
                builder: (context, figma) => _buildFigmaHomeLayers(
                  figma: figma,
                  tier: homeTier,
                  energy: profile.energy,
                  coin: profile.seeds,
                  streak: profile.streak,
                  currentStep: homeMapCurrentStep(profile),
                  newsTitle: _newsBarTitle,
                  showReviewStage: showReviewStage,
                  onMenu: _openCategorySwitcher,
                  onNews: _openNews,
                  onShop: _openShop,
                  onStreakCalendar: _openStreakCalendar,
                ),
              ),
              Positioned(
                left: figma.s(homeTier.learningCtaLeft),
                bottom: figma.s(
                  FigmaScale.homeContentHeight -
                      homeTier.learningCtaTop -
                      _homeLearningCtaDesignHeight,
                ),
                width: figma.s(_homeLearningCtaWidth),
                height: figma.s(_homeLearningCtaHeight),
                child: _HomeLearningCta(
                  figma: figma,
                  tier: homeTier,
                  canStartLearning: canStart,
                  onTap: _startQuiz,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

List<Widget> _buildFigmaHomeLayers({
  required FigmaScale figma,
  required HomeTierTheme tier,
  required int energy,
  required int coin,
  required int streak,
  required int currentStep,
  required String newsTitle,
  required bool showReviewStage,
  required VoidCallback onMenu,
  required VoidCallback onNews,
  required VoidCallback onShop,
  required VoidCallback onStreakCalendar,
}) {
  final s = figma.s;
  final newsLine = newsTitle.startsWith('HOT 뉴스')
      ? newsTitle
      : 'HOT 뉴스 / $newsTitle';

  return [
    // ── 맵 경로 Subtract + 발판 Ellipse 156/157/154/155/100 ──
    FigmaBox(
      figma: figma,
      left: 139.59765625,
      top: 143,
      width: 485.3046875,
      height: 541.802734375,
      child: FigmaSvg(tier.pathMap, fit: BoxFit.fill),
    ),
    if (!showReviewStage)
      _homeEllipse(
        figma: figma,
        left: 145,
        top: 526,
        width: 210,
        height: 119,
        color: tier.platformShadow,
      ),
    _homeEllipse(
      figma: figma,
      left: 219,
      top: 194,
      width: 131,
      height: 66,
      color: tier.platformShadow,
    ),
    FigmaBox(
      figma: figma,
      left: 219,
      top: 186,
      width: 131,
      height: 66,
      child: FigmaSvg(tier.ellipse154, fit: BoxFit.fill),
    ),
    if (!showReviewStage)
      FigmaBox(
        figma: figma,
        left: 145,
        top: 514,
        width: 210,
        height: 119,
        child: FigmaSvg(tier.ellipse155, fit: BoxFit.fill),
      ),
    // Ellipse 100 + Subtract 크레센트 — 햄스터 자리 3D (CSS 45,373 / 166×95·53).
    _homeEllipse(
      figma: figma,
      left: 45,
      top: 373,
      width: 166,
      height: 95,
      color: tier.hamsterSeat,
    ),
    FigmaBox(
      figma: figma,
      left: 45,
      top: 373,
      width: 166,
      height: 52.994,
      child: CustomPaint(
        painter: _HamsterSeatCrescentPainter(color: tier.hamsterSeatTop),
        child: const SizedBox.expand(),
      ),
    ),

    // ── Group 367 / 271 햄스터 ──
    FigmaBox(
      figma: figma,
      left: 51,
      top: 319,
      width: 154.404,
      height: 150,
      child: FigmaSvg(tier.hamsterMap, fit: BoxFit.fill),
    ),

    // ── Group 548/549 돈주머니 SVG (opacity는 에셋 g에 포함) ──
    _homeEllipse(
      figma: figma,
      left: 65.07,
      top: 271,
      width: 50,
      height: 20.9,
      color: const Color(0xFFE8E8E8),
    ),
    FigmaBox(
      figma: figma,
      left: 59.48,
      top: 219.63,
      width: 65.101,
      height: 64.646,
      child: const FigmaSvg(FigmaAssets.homeBagLeft, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 255,
      top: 374,
      width: 120.989,
      height: 128.141,
      child: const FigmaSvg(FigmaAssets.homeBagRight, fit: BoxFit.fill),
    ),

    // ── Star 6/7/8 + Rectangle 687 + 왼쪽 스파클 ──
    _homeStar(
      figma: figma,
      left: 223.14,
      top: 339.14,
      boxSize: 54.136,
      starSize: 49,
      degrees: 6.37,
      color: tier.starOuter,
    ),
    _homeStar(
      figma: figma,
      left: 231,
      top: 348,
      boxSize: 35.166,
      starSize: 30.779,
      degrees: 8.89,
      color: tier.starMid,
    ),
    _homeStar(
      figma: figma,
      left: 209,
      top: 381,
      boxSize: 23.61,
      starSize: 18,
      degrees: 23.05,
      color: tier.starTiny,
    ),
    FigmaBox(
      figma: figma,
      left: 41,
      top: 384,
      width: 8.51,
      height: 8.51,
      child: Transform.rotate(
        angle: 8.01 * math.pi / 180,
        child: Center(
          child: Container(
            width: figma.s(7.534),
            height: figma.s(7.534),
            decoration: BoxDecoration(
              color: tier.sparkle,
              borderRadius: BorderRadius.circular(figma.s(3)),
            ),
          ),
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 19,
      top: 356.48,
      width: 28.06,
      height: 27.72,
      child: Transform.rotate(
        angle: -17.28 * math.pi / 180,
        child: FigmaSvg(
          FigmaAssets.homeSparkle,
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(tier.starTiny, BlendMode.srcIn),
        ),
      ),
    ),

    // ── Stage nodes: CSS rotate(100.57deg) + box-shadow 오각형 ──
    _HomeStagePentagon(
      figma: figma,
      left: 0.6718 * 393,
      top: 0.2054 * 852,
      width: (1 - 0.6718 - 0.237) * 393,
      height: (1 - 0.2054 - 0.7535) * 852,
      fill: tier.node1Fill,
      extrusion: tier.node1Shadow,
      extrusionOffset: const Offset(1.87584, 1.87584),
      isLarge: false,
      label: '$currentStep',
      fontSize: 15.1668,
      labelStroke: 1.01112,
      labelShadowOffset: const Offset(0.781601, 0.781601),
      labelShadowColor: const Color.fromRGBO(205, 85, 0, 0.25),
    ),
    if (showReviewStage)
      _HomeReviewHouse(figma: figma, tier: tier)
    else
      _HomeStagePentagon(
        figma: figma,
        left: 0.5522 * 393,
        top: 0.5751 * 852,
        width: (1 - 0.5522 - 0.2765) * 393,
        height: (1 - 0.5751 - 0.3477) * 852,
        fill: tier.node3Fill,
        extrusion: tier.node3Shadow,
        extrusionOffset: const Offset(-2.90579, 5.08513),
        isLarge: true,
        label: '${homeMapUpcomingStep(currentStep)}',
        fontSize: 28.4854,
        labelStroke: 1.89903,
        labelShadowOffset: const Offset(-1.45289, 1.46796),
        labelShadowColor: tier.node3LabelShadow,
      ),

    // ── 131:5325 뉴스 배너 ──
    FigmaPill(
      figma: figma,
      left: 32,
      top: 115,
      width: 327.536,
      height: 33.693,
      color: const Color(0xFFB4EBFF),
      radius: 14.255,
    ),
    FigmaBox(
      figma: figma,
      left: 45.607177734375,
      // 배너(top 115, height 33.693) 세로 중앙.
      top: 124.18,
      width: 16.0,
      height: 15.35,
      child: const FigmaSvg(
        FigmaAssets.homeBeginnerMegaphone,
        fit: BoxFit.fill,
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 71.525390625,
      // 글씨를 키운 만큼 세로 중앙을 다시 맞추고, 배너 오른쪽 끝까지 폭을 넓힌다.
      top: 122.85,
      width: 272,
      height: 18,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          // 전광판처럼 새 제목은 아래에서 올라오고, 이전 제목은 위로 밀려 나간다.
          // 나가는 쪽은 애니메이션이 거꾸로(1→0) 돌아서 0→(0,-1)로 움직인다.
          transitionBuilder: (child, animation) {
            final incoming = child.key == ValueKey(newsLine);
            final slide = Tween<Offset>(
              begin: incoming ? const Offset(0, 1) : const Offset(0, -1),
              end: Offset.zero,
            );
            return SlideTransition(
              position: animation.drive(slide),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previousChildren, ?currentChild],
          ),
          child: Align(
            key: ValueKey(newsLine),
            alignment: Alignment.centerLeft,
            child: Text(
              newsLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: FigmaHomeFonts.inter,
                // Figma 값은 8.747인데 393 프레임에서 그대로 쓰면 배너 안에서
                // 글씨만 혼자 3배 작다(바로 아래 '오늘의 학습'이 26).
                fontSize: s(13),
                fontWeight: FontWeight.w500,
                height: 1.1,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 338,
      top: 124,
      width: 16,
      height: 16,
      child: const FigmaSvg(
        FigmaAssets.homeBeginnerChevronNews,
        fit: BoxFit.fill,
      ),
    ),
    FigmaTapArea(
      figma: figma,
      left: 32,
      top: 115,
      width: 327.536,
      height: 33.693,
      onTap: onNews,
      child: const SizedBox.shrink(),
    ),

    // ── 131:5371 카테고리 메뉴 ──
    _BeginnerMenuButton(figma: figma, onTap: onMenu),

    // ── 131:5380~5395 상단 스탯 ──
    FigmaBox(
      figma: figma,
      left: 119.99951171875,
      top: 63.999755859375,
      width: 35.718,
      height: 24.949,
      child: const FigmaSvg(
        FigmaAssets.homeBeginnerStatEnergy,
        fit: BoxFit.contain,
      ),
    ),
    FigmaLabel(
      figma: figma,
      left: 163.91872787475586,
      top: 70.26683902740479,
      text: '$energy',
      fontSize: 12,
      color: const Color(0xFFFBB03B),
      fontWeight: FontWeight.w600,
      fontFamily: FigmaHomeFonts.inter,
    ),
    FigmaBox(
      figma: figma,
      left: 224,
      top: 62,
      width: 27.43,
      height: 26.57,
      child: const FigmaSvg(
        FigmaAssets.homeBeginnerStatCoin,
        fit: BoxFit.contain,
      ),
    ),
    FigmaLabel(
      figma: figma,
      left: 258.6328125,
      top: 70.087890625,
      text: '$coin',
      fontSize: 12,
      color: const Color(0xFFFFCA55),
      fontWeight: FontWeight.w600,
      fontFamily: FigmaHomeFonts.inter,
    ),
    FigmaTapArea(
      figma: figma,
      left: 210,
      top: 55,
      width: 90,
      height: 40,
      onTap: onShop,
      child: const SizedBox.expand(),
    ),
    FigmaBox(
      figma: figma,
      left: 316,
      top: 61,
      width: 22.111,
      height: 27.204,
      child: const FigmaSvg(
        FigmaAssets.homeBeginnerStatStreak,
        fit: BoxFit.contain,
      ),
    ),
    FigmaLabel(
      figma: figma,
      left: 345.92693519592285,
      top: 69.73677730560303,
      text: '$streak',
      fontSize: 12,
      color: const Color(0xFFFB8B3B),
      fontWeight: FontWeight.w600,
      fontFamily: FigmaHomeFonts.inter,
    ),
    FigmaTapArea(
      figma: figma,
      left: 300,
      top: 55,
      width: 80,
      height: 40,
      onTap: onStreakCalendar,
      child: const SizedBox.expand(),
    ),
  ];
}

Widget _homeEllipse({
  required FigmaScale figma,
  required double left,
  required double top,
  required double width,
  required double height,
  required Color color,
}) {
  return FigmaBox(
    figma: figma,
    left: left,
    top: top,
    width: width,
    height: height,
    child: ClipOval(child: ColoredBox(color: color)),
  );
}

/// Figma Subtract 166×53 — Ellipse 100 윗면을 잘라 만든 크레센트.
class _HamsterSeatCrescentPainter extends CustomPainter {
  const _HamsterSeatCrescentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromLTWH(0, 0, size.width, size.width * 95 / 166);
    final outer = Path()..addOval(oval);
    final inner = Path()..addOval(oval.shift(Offset(0, size.height * 0.22)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HamsterSeatCrescentPainter oldDelegate) =>
      oldDelegate.color != color;
}

Widget _homeStar({
  required FigmaScale figma,
  required double left,
  required double top,
  required double boxSize,
  required double starSize,
  required double degrees,
  required Color color,
}) {
  return FigmaBox(
    figma: figma,
    left: left,
    top: top,
    width: boxSize,
    height: boxSize,
    child: Transform.rotate(
      angle: degrees * math.pi / 180,
      child: Center(
        child: FigmaSvg(
          FigmaAssets.homeStar,
          width: figma.s(starSize),
          height: figma.s(starSize),
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    ),
  );
}

/// Figma `268:3644` / `268:3808` / `137:1610`의 복습 집 단계.
class _HomeReviewHouse extends StatelessWidget {
  const _HomeReviewHouse({required this.figma, required this.tier});

  final FigmaScale figma;
  final HomeTierTheme tier;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;

    return Stack(
      key: ValueKey('home-review-house-${tier.tier.name}'),
      clipBehavior: Clip.none,
      children: [
        FigmaBox(
          figma: figma,
          left: 195,
          top: 619,
          width: 101,
          height: 29,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: s(3.9), sigmaY: s(3.9)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tier.reviewHouseShadowColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        if (tier.hasCompositeReviewHouse)
          FigmaBox(
            figma: figma,
            left: 186.9993896484375,
            top: 488,
            width: 119.23079681396484,
            height: 145.61891174316406,
            child: FigmaSvg(tier.reviewHouseComposite, fit: BoxFit.fill),
          )
        else ...[
          FigmaBox(
            figma: figma,
            left: 186.9994354248047,
            top: 523.082275390625,
            width: 119.23079681396484,
            height: 110.53688049316406,
            child: FigmaSvg(tier.reviewHouseBody, fit: BoxFit.fill),
          ),
          FigmaBox(
            figma: figma,
            left: 221.00048828125,
            top: 590.1487426757812,
            width: 50.95686340332031,
            height: 36.018959045410156,
            child: FigmaSvg(tier.reviewHouseIcon, fit: BoxFit.fill),
          ),
          FigmaBox(
            figma: figma,
            left: 235,
            top: 488,
            width: 22.35577392578125,
            height: 22.35577392578125,
            child: FigmaSvg(tier.reviewHouseDot, fit: BoxFit.fill),
          ),
        ],
        FigmaBox(
          figma: figma,
          left: 178.5615,
          top: 513.1188,
          width: 135.877,
          height: 65.8812,
          child: FigmaSvg(tier.reviewHouseRoof, fit: BoxFit.fill),
        ),
      ],
    );
  }
}

/// Figma `131:5342` — 맵 스크롤과 무관하게 하단에 고정.
class _HomeLearningCta extends StatelessWidget {
  const _HomeLearningCta({
    required this.figma,
    required this.tier,
    required this.canStartLearning,
    required this.onTap,
  });

  final FigmaScale figma;
  final HomeTierTheme tier;
  final bool canStartLearning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final originX = tier.learningCtaLeft;
    const iconSize = 47.0;
    const chevronDesignSize = 46.055;
    const chevronSize = chevronDesignSize * 0.75;
    const textHeight = 33.8;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: canStartLearning
                  ? tier.learningCtaColor
                  : tier.learningCtaColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(s(13)),
              boxShadow: tier.hasLearningCtaShadow
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE5E5E5),
                        blurRadius: s(6.372),
                      ),
                    ]
                  : null,
            ),
            child: SizedBox(
              width: s(_homeLearningCtaWidth),
              height: s(_homeLearningCtaHeight),
            ),
          ),
          Positioned(
            left: s(49 - originX),
            top: s((_homeLearningCtaHeight - iconSize) / 2),
            width: s(iconSize),
            height: s(iconSize),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(s(7.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: Offset(s(3), s(3)),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: s(6),
                  top: s(9),
                  right: s(7),
                  bottom: s(10),
                ),
                child: FigmaSvg(tier.learningQ, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            left: s(135 - originX),
            top: s((_homeLearningCtaHeight - textHeight) / 2),
            child: Text(
              canStartLearning ? '오늘의 학습' : '에너지 부족',
              style: TextStyle(
                fontFamily: FigmaHomeFonts.pretendard,
                fontSize: s(26),
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
          Positioned(
            left: s(309 - originX + (chevronDesignSize - chevronSize) / 2),
            top: s((_homeLearningCtaHeight - chevronSize) / 2),
            width: s(chevronSize),
            height: s(chevronSize),
            child: FigmaSvg(tier.chevronLearning, fit: BoxFit.fill),
          ),
        ],
      ),
    );
  }
}

/// Figma 홈 오각형 — CSS `rotate(100.57deg)` + 단색 box-shadow 3D.
class _HomeStagePentagon extends StatelessWidget {
  const _HomeStagePentagon({
    required this.figma,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.fill,
    required this.extrusion,
    required this.extrusionOffset,
    required this.isLarge,
    required this.label,
    required this.fontSize,
    required this.labelStroke,
    required this.labelShadowOffset,
    required this.labelShadowColor,
  });

  static const _rotation = 100.57 * math.pi / 180;

  final FigmaScale figma;
  final double left;
  final double top;
  final double width;
  final double height;
  final Color fill;
  final Color extrusion;
  final Offset extrusionOffset;
  final bool isLarge;
  final String label;
  final double fontSize;
  final double labelStroke;
  final Offset labelShadowOffset;
  final Color labelShadowColor;

  double get _fittedFontSize {
    if (label.length >= 3) return fontSize * 0.62;
    if (label.length == 2) return fontSize * 0.78;
    return fontSize;
  }

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final style = TextStyle(
      fontFamily: FigmaHomeFonts.pretendard,
      fontSize: s(_fittedFontSize),
      fontWeight: FontWeight.w100,
      height: 1,
    );
    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.rotate(
            angle: _rotation,
            child: _StagePentagonShape(
              fill: fill,
              extrusion: extrusion,
              extrusionOffset: Offset(
                s(extrusionOffset.dx),
                s(extrusionOffset.dy),
              ),
              isLarge: isLarge,
            ),
          ),
          Text(
            label,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = s(labelStroke)
                ..color = Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(
                    s(labelShadowOffset.dx),
                    s(labelShadowOffset.dy),
                  ),
                  color: labelShadowColor,
                ),
              ],
            ),
          ),
          Text(label, style: style.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

/// 홈 단계 오각형. 원본 SVG를 그림자 색·채움 색으로 두 번 그린다.
///
/// flutter_svg는 SVG의 drop-shadow filter를 그리지 않아서, 그림자는 같은 모양을
/// [extrusionOffset]만큼 옮겨 아래에 깐다. 티어마다 모양이 같고 색만 달라 SVG는
/// 한 벌이고 색은 [HomeTierTheme]에서 받는다.
class _StagePentagonShape extends StatelessWidget {
  const _StagePentagonShape({
    required this.fill,
    required this.extrusion,
    required this.extrusionOffset,
    required this.isLarge,
  });

  final Color fill;
  final Color extrusion;
  final Offset extrusionOffset;
  final bool isLarge;

  // 박스는 경로가 차지하는 영역(Figma bounds)에 맞춘다. SVG viewBox는 그림자 필터
  // 여백까지 포함해 더 크므로, 경로 영역이 박스에 딱 맞도록 SVG를 옮겨 늘린다.
  static const _smallViewBox = Size(37.7288, 36.895);
  static const _smallShapeOrigin = Offset(-0.534659, -0.404554);
  static const _smallShapeSize = Size(36.3894, 35.423754);
  static const _largeViewBox = Size(70.2428, 70.8561);
  static const _largeShapeOrigin = Offset(1.90162, -0.75981);
  static const _largeShapeSize = Size(69.34858, 66.53081);

  @override
  Widget build(BuildContext context) {
    final asset = isLarge
        ? FigmaAssets.homeStagePentagonLarge
        : FigmaAssets.homeStagePentagonSmall;
    final viewBox = isLarge ? _largeViewBox : _smallViewBox;
    final shapeOrigin = isLarge ? _largeShapeOrigin : _smallShapeOrigin;
    final shapeSize = isLarge ? _largeShapeSize : _smallShapeSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sx = constraints.maxWidth / shapeSize.width;
        final sy = constraints.maxHeight / shapeSize.height;

        Widget layer(Color color, Offset shift) => Positioned(
          left: -shapeOrigin.dx * sx + shift.dx,
          top: -shapeOrigin.dy * sy + shift.dy,
          width: viewBox.width * sx,
          height: viewBox.height * sy,
          child: FigmaSvg(
            asset,
            fit: BoxFit.fill,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        );

        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              layer(extrusion, extrusionOffset),
              layer(fill, Offset.zero),
            ],
          ),
        );
      },
    );
  }
}

class _BeginnerMenuButton extends StatelessWidget {
  const _BeginnerMenuButton({required this.figma, required this.onTap});

  final FigmaScale figma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return FigmaTapArea(
      figma: figma,
      left: 33.999755859375,
      top: 61,
      width: 30.58,
      height: 29.91,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: s(16.78),
            child: _square(s, const Color(0xFFFFCA55)),
          ),
          Positioned(
            left: s(16.78),
            top: s(16.1),
            child: _square(s, const Color(0xFFFFCA55)),
          ),
          Positioned(top: s(16.1), child: _square(s, const Color(0xFFFFCA55))),
          Positioned(
            top: s(1.03),
            child: FigmaSvg(
              FigmaAssets.homeBeginnerMenuIcon,
              width: s(14.709),
              height: s(12.905),
            ),
          ),
        ],
      ),
    );
  }

  Widget _square(double Function(double) s, Color color) {
    return Container(
      width: s(13.803),
      height: s(13.803),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(s(2.924)),
      ),
    );
  }
}
