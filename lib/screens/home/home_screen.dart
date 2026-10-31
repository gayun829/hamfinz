import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/interest_categories.dart';
import '../../data/learning_steps.dart';
import '../../data/quiz_data.dart';
import '../../data/shop_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/friend_service.dart';
import '../../services/news_service.dart';
import '../../services/quiz_service.dart';
import '../../utils/incorrect_questions.dart';
import '../../theme/home_tier_theme.dart';
import '../../theme/figma_home_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_switcher_sheet.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_canvas.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/shop/shop_widgets.dart';
import '../calendar/streak_calendar_screen.dart';
import '../news/article_screen.dart';
import '../news/term_quiz_screen.dart';
import '../quiz/quiz_screen.dart';
import '../shop/shop_screen.dart';

/// Figma `131:5342` / `137:1375` / `137:1489` 오늘의 학습 CTA.
const _homeLearningCtaHeight = 84.247;
const _homeLearningCtaWidth = 328.0;

/// 홈 맵의 복습 단계 — Figma 복습창!(`526:3093` 등) / 복습창2(`526:2131` 등).
enum HomeReviewStage {
  none,

  /// 다음 칸이 복습 집이다.
  ahead,

  /// 복습을 끝내고 햄핀이가 복습 집에 도착했다.
  arrived,
}

HomeReviewStage homeReviewStageOf(UserProfile profile) {
  if (activeCategoryNeedsReview(profile)) return HomeReviewStage.ahead;
  if (activeCategoryReviewArrived(profile)) return HomeReviewStage.arrived;
  return HomeReviewStage.none;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.profile,
    this.reviewStageOverride,
    this.tierOverride,
    this.onNavTap,
  });

  /// [MainShell]에서 내려주면 학습과정 변경 시 홈 티어가 즉시 반영된다.
  final UserProfile? profile;
  final ValueChanged<int>? onNavTap;

  /// 복습 홈을 학습 기록과 무관하게 미리 보여주기 위한 단계 지정.
  final HomeReviewStage? reviewStageOverride;

  /// 복습 홈 3종을 학습 진도와 독립적으로 미리 보여주기 위한 티어 지정.
  final HomeTierTheme? tierOverride;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// 햄핀이가 땅속에 들어간 정도. 0이면 제자리, 1이면 완전히 땅속이다.
  late final AnimationController _dig = AnimationController(vsync: this);
  bool _quizFlowActive = false;

  UserProfile? _profile;
  bool _loading = true;

  /// 착용 아이템을 그릴 카탈로그. 이미 불러온 카탈로그가 있으면 그것으로,
  /// 없으면 로컬 카탈로그로 먼저 그리고 불러온 뒤 반영한다.
  final List<ShopItem> _catalogItems = ShopData.items;

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

  /// 뉴스바 제목만 바꿔 그린다. 7초마다 홈 전체를 다시 빌드하지 않게 한다.
  final _newsTitle = ValueNotifier(_emptyNewsTitle);

  /// 못 불러왔을 때도 배너가 비어 보이지 않게 한다.
  static const _emptyNewsTitle = '오늘의 금융 뉴스 보러가기';

  /// 뉴스바가 한 건을 보여주는 시간.
  static const _newsSlideInterval = Duration(seconds: 7);

  @override
  void dispose() {
    _dig.dispose();
    _newsTimer?.cancel();
    _newsTitle.dispose();
    super.dispose();
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
    if (_quizFlowActive) return;
    _quizFlowActive = true;
    try {
      await _runQuizFlow();
    } finally {
      _quizFlowActive = false;
    }
  }

  Future<void> _runQuizFlow() async {
    await _loadProfile();
    if (!mounted) return;

    final profile = _profile;
    if (profile == null) return;

    // 앱이 종료돼 닫지 못한 세션이 있으면 닫고 에너지를 돌려받는다.
    // 에너지 확인 전에 해야 돌려받은 에너지로 바로 시작할 수 있다.
    await QuizService.instance.abandonOpenSessions(profile: profile);
    if (!mounted) return;

    final isReview = activeCategoryNeedsReview(profile);

    if (profile.energy < QuizData.sessionEnergyCost) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('에너지가 부족해요'),
          content: Text(
            '학습 1회(${QuizData.dailyQuestionCount}문제)에 '
            '${QuizData.sessionEnergyCost} 에너지가 필요해요.\n'
            '(지금 에너지: ${profile.energy})',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
          ],
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

    // 햄핀이가 땅을 파고 들어간 뒤 학습을 시작하고, 돌아오면 바뀐 칸 번호를
    // 먼저 불러온 다음 땅을 파고 올라온다.
    await _dig.animateTo(
      1,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInCubic,
    );
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(profile: profile, isReview: isReview),
      ),
    );

    if (!mounted) return;
    await _loadProfile();
    if (!mounted) return;
    await _dig.animateTo(
      0,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
    );
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

  Future<void> _loadNews() async {
    try {
      final items = await NewsService.topFinance();
      if (!mounted) return;
      _news = items;
      _newsIndex = 0;
      _newsTitle.value = items.isEmpty ? _emptyNewsTitle : items.first.title;
      // 목록이 들어온 시점부터 다시 세서 첫 기사도 다른 기사만큼 보이게 한다.
      _newsTimer?.cancel();
      _newsTimer = Timer.periodic(_newsSlideInterval, (_) => _rotateNews());
    } catch (_) {
      // 뉴스는 홈의 곁다리라, 실패해도 홈 전체를 오류로 만들지 않는다.
    }
  }

  void _rotateNews() {
    if (!mounted || _news.length < 2) return;
    _newsIndex = (_newsIndex + 1) % _news.length;
    _newsTitle.value = _news[_newsIndex].title;
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
          loadFriendsRanking: FriendService.instance.getFriendsRanking,
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

    final homeTier =
        widget.tierOverride ?? HomeTierTheme.forStage(profile.learningStage);
    final reviewStage =
        widget.reviewStageOverride ?? homeReviewStageOf(profile);

    return LayoutBuilder(
      builder: (context, constraints) {
        final figma = FigmaScale.ofWidth(
          constraints.maxWidth,
          designWidth: FigmaScale.homeDesignWidth,
        );

        // 스크롤하지 않는다. 화면이 디자인보다 낮으면 위쪽부터 보이고
        // 아래쪽이 그대로 잘린다. CTA만 화면 바닥에 붙어 있어 항상 보인다.
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _homeBackgroundGradient(homeTier),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRect(
                child: FigmaCanvas(
                  designWidth: FigmaScale.homeDesignWidth,
                  designHeight: FigmaScale.homeContentHeight,
                  backgroundColor: Colors.transparent,
                  fit: FigmaCanvasFit.widthScroll,
                  scrollable: false,
                  clipContent: false,
                  extraBottomPaddingDesign:
                      FigmaScale.homeContentHeight - homeTier.learningCtaTop,
                  builder: (context, figma) => _buildFigmaHomeLayers(
                    figma: figma,
                    tier: homeTier,
                    energy: profile.energy,
                    coin: profile.seeds,
                    streak: profile.streak,
                    currentStep: homeMapCurrentStep(profile),
                    newsTitle: _newsTitle,
                    reviewStage: reviewStage,
                    look: EquippedLook.of(profile, _catalogItems),
                    dig: _dig,
                    onMenu: _openCategorySwitcher,
                    onNews: _openNews,
                    onShop: _openShop,
                    onStreakCalendar: _openStreakCalendar,
                  ),
                ),
              ),
            ),
            Positioned(
              left: figma.s(homeTier.learningCtaLeft),
              bottom: figma.s(
                FigmaScale.homeContentHeight -
                    homeTier.learningCtaTop -
                    _homeLearningCtaHeight,
              ),
              width: figma.s(_homeLearningCtaWidth),
              height: figma.s(_homeLearningCtaHeight),
              child: _HomeLearningCta(
                figma: figma,
                tier: homeTier,
                onTap: _startQuiz,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Figma 프레임(852) 기준 그라데이션을 하단 탭(68)을 뺀 홈 영역(784)에 맞춘다.
/// 끝 stop(115.61%)은 프레임 밖이라, 홈 영역 바닥의 보간색으로 끝낸다.
LinearGradient _homeBackgroundGradient(HomeTierTheme tier) {
  const frameHeight = 852.0;
  const homeHeight = 784.0;
  const startStop = 0.27758;
  const endStop = 1.1561;
  const homeBottom = homeHeight / frameHeight;
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppTheme.figmaHomeBackground,
      Color.lerp(
        AppTheme.figmaHomeBackground,
        tier.backgroundBottom,
        (homeBottom - startStop) / (endStop - startStop),
      )!,
    ],
    stops: const [startStop / homeBottom, 1],
  );
}

List<Widget> _buildFigmaHomeLayers({
  required FigmaScale figma,
  required HomeTierTheme tier,
  required int energy,
  required int coin,
  required int streak,
  required int currentStep,
  required ValueListenable<String> newsTitle,
  required HomeReviewStage reviewStage,
  required EquippedLook look,
  required Animation<double> dig,
  required VoidCallback onMenu,
  required VoidCallback onNews,
  required VoidCallback onShop,
  required VoidCallback onStreakCalendar,
}) {
  final s = figma.s;
  final ahead = reviewStage == HomeReviewStage.ahead;
  final arrived = reviewStage == HomeReviewStage.arrived;

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
    if (ahead)
      // Ellipse 218/219 — 복습 집 그림자. 집 몸통이 어두워지지 않게 먼저 깐다.
      _blurredEllipse(
        figma: figma,
        left: 180.19287109375,
        top: 619.18359375,
        width: 116.05223083496094,
        height: 33.321929931640625,
        color: tier.reviewAheadShadowColor,
        blurSigma: 4.48123,
      )
    else
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
    if (arrived)
      // Ellipse 217 — 복습 집에 앉은 햄핀이 그림자.
      _blurredEllipse(
        figma: figma,
        left: 104,
        top: 469,
        width: 101,
        height: 29,
        color: tier.reviewArrivalShadowColor,
        blurSigma: 3.9,
      ),
    FigmaBox(
      figma: figma,
      left: 219,
      top: 186,
      width: 131,
      height: 66,
      child: FigmaSvg(tier.ellipse154, fit: BoxFit.fill),
    ),
    if (!ahead)
      FigmaBox(
        figma: figma,
        left: 145,
        top: 514,
        width: 210,
        height: 119,
        child: FigmaSvg(tier.ellipse155, fit: BoxFit.fill),
      ),
    if (!arrived) ...[
      // Ellipse 100 + Subtract 크레센트 — 햄스터 자리 3D (CSS 45,373 / 166×95·53).
      _homeEllipse(
        figma: figma,
        left: _hamsterHole.left,
        top: _hamsterHole.top,
        width: _hamsterHole.width,
        height: _hamsterHole.height,
        color: tier.hamsterSeat,
      ),
      FigmaBox(
        figma: figma,
        left: _hamsterHole.left,
        top: _hamsterHole.top,
        width: _hamsterHole.width,
        height: 52.994,
        child: CustomPaint(
          painter: _HamsterSeatCrescentPainter(color: tier.hamsterSeatTop),
          child: const SizedBox.expand(),
        ),
      ),
    ],
    _DiggingHamster(
      figma: figma,
      dig: dig,
      ground: arrived ? _DigGround.house : _DigGround.hole,
      dirtColor: tier.hamsterSeat,
      layers: look.isCustom
          ? arrived
                ? _customArrivalLayers(figma, tier, look)
                : [_customHamster(figma, look)]
          : arrived
          ? _reviewArrivalHamsterLayers(figma, tier)
          : tier.usesPeekHamster
          ? _peekHamsterLayers(figma)
          : [
              // ── Group 367 햄스터 ──
              FigmaBox(
                figma: figma,
                left: 51,
                top: 319,
                width: 154.404,
                height: 150,
                child: FigmaSvg(tier.hamsterMap, fit: BoxFit.fill),
              ),
            ],
    ),

    // ── Group 548/549 돈주머니 ──
    // 왼쪽 그림자(Subtract)는 타원에서 주머니 자리를 뺀 모양이라 반투명한
    // 주머니 뒤로 비치지 않는다.
    FigmaBox(
      figma: figma,
      left: 65.07528686523438,
      top: 271.0029296875,
      width: 49.99713134765625,
      height: 20.898149490356445,
      child: const FigmaSvg(FigmaAssets.homeBagLeftShadow, fit: BoxFit.fill),
    ),
    _homeBag(figma, _leftBag),
    _homeBag(figma, _rightBag),

    // ── Star 6/7/8 + Rectangle 687 + 왼쪽 스파클 ──
    // 복습 집 도착 화면은 햄핀이가 커진 만큼 장식이 바깥으로 물러난다.
    if (arrived) ...[
      _homeStar(
        figma: figma,
        left: 255.2553,
        top: 328,
        boxSize: 50.216,
        starSize: 49,
        degrees: 1.44,
        color: tier.starOuter,
      ),
      _homeStar(
        figma: figma,
        left: 262.2703,
        top: 336.209,
        boxSize: 32.83,
        starSize: 30.779,
        degrees: 3.96,
        color: tier.starMid,
      ),
      _homeStar(
        figma: figma,
        left: 241.999,
        top: 370.78,
        boxSize: 22.705,
        starSize: 18,
        degrees: 18.12,
        color: tier.starTiny,
      ),
      _homeSparkleSquare(
        figma: figma,
        left: 65.8828,
        top: 387.63,
        boxSize: 8.0007,
        degrees: -3.67,
        color: tier.sparkle,
      ),
      _homeSparkle(
        figma: figma,
        left: 39,
        top: 361.0008,
        width: 30.3782,
        height: 30.1733,
        degrees: -28.95,
        color: tier.starTiny,
      ),
    ] else ...[
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
      _homeSparkleSquare(
        figma: figma,
        left: 41,
        top: 384,
        boxSize: 8.51,
        degrees: 8.01,
        color: tier.sparkle,
      ),
      _homeSparkle(
        figma: figma,
        left: 19,
        top: 356.0004,
        width: 28.0602,
        height: 27.7154,
        degrees: -17.28,
        color: tier.starTiny,
      ),
    ],

    // ── Stage nodes: CSS rotate(100.57deg) + box-shadow 오각형 ──
    // 복습 집이 기다리는 화면(`526:3093` 등)은 1단계 오각형이 한 단계 작다.
    if (ahead) ...[
      _stageShadow(
        figma: figma,
        left: 272.7525,
        top: 210.0151,
        width: 29.6559,
        height: 12.335,
        degrees: 87.94,
        blurSigma: 1.84902,
        flipX: false,
        path: _stageShadowAheadPath,
        viewBox: const Size(18.6856, 36.6648),
      ),
      _HomeStagePentagon(
        figma: figma,
        left: 264.0,
        top: 175.0,
        width: 40.9996,
        height: 41.6664,
        shapeSize: const Size(35.851, 35.017),
        fill: tier.node1Fill,
        extrusion: tier.node1Shadow,
        extrusionOffset: const Offset(1.87584, 1.87584),
        isLarge: false,
        label: '$currentStep',
        fontSize: 15.167,
        labelStroke: 1.01112,
        labelShadowOffset: const Offset(0.782, 0.782),
        labelShadowColor: const Color.fromRGBO(205, 85, 0, 0.25),
      ),
      ..._reviewHouseLayers(figma, tier),
    ] else ...[
      // ── 오각형 아래 발판에 드리운 그림자 (Figma `526:2706` / `526:2848`) ──
      _stageShadow(
        figma: figma,
        left: 0.6842 * 393,
        top: 0.2448 * 852,
        width: (1 - 0.6842 - 0.2219) * 393,
        height: (1 - 0.2448 - 0.7372) * 852,
        degrees: 87.94,
        blurSigma: 2.30002,
        flipX: false,
        path: _stageShadowSmallPath,
        viewBox: const Size(23.2433, 45.6079),
      ),
      _stageShadow(
        figma: figma,
        left: 0.5496 * 393,
        top: 0.6578 * 852,
        width: (1 - 0.5496 - 0.2882) * 393,
        height: (1 - 0.6578 - 0.311) * 852,
        degrees: -87.94,
        blurSigma: 2.6322,
        flipX: true,
        path: _stageShadowLargePath,
        viewBox: const Size(34.7947, 73.4394),
      ),
      _HomeStagePentagon(
        figma: figma,
        left: 0.6565 * 393,
        top: 0.1937 * 852,
        width: (1 - 0.6565 - 0.2137) * 393,
        height: (1 - 0.1937 - 0.7455) * 852,
        shapeSize: _HomeStagePentagon._smallShapeSize,
        fill: tier.node1Fill,
        extrusion: tier.node1Shadow,
        extrusionOffset: const Offset(2.33339, 2.33339),
        isLarge: false,
        label: '$currentStep',
        fontSize: 18.866,
        labelStroke: 1.2578,
        labelShadowOffset: const Offset(0.972, 0.972),
        labelShadowColor: tier.node1LabelShadow,
      ),
      _HomeStagePentagon(
        figma: figma,
        left: 0.5369 * 393,
        top: 0.5681 * 852,
        width: (1 - 0.5369 - 0.2389) * 393,
        height: (1 - 0.5681 - 0.3268) * 852,
        shapeSize: _HomeStagePentagon._largeShapeSize,
        fill: tier.node3Fill,
        extrusion: tier.node3Shadow,
        extrusionOffset: const Offset(-3.32549, 5.8196),
        isLarge: true,
        label: '${homeMapUpcomingStep(currentStep)}',
        fontSize: 32.6,
        labelStroke: 2.1734,
        labelShadowOffset: const Offset(-1.663, 1.68),
        labelShadowColor: tier.node3LabelShadow,
      ),
    ],

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
      child: ValueListenableBuilder<String>(
        valueListenable: newsTitle,
        builder: (context, title, _) {
          final newsLine = title.startsWith('HOT 뉴스')
              ? title
              : 'HOT 뉴스 / $title';
          return ClipRect(
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
          );
        },
      ),
    ),
    // fi-rr-angle-small-right 16×16 아이콘에서 화살표 경로가 차지하는 영역만.
    FigmaBox(
      figma: figma,
      left: 338 + 6.0694,
      top: 124 + 3.3328,
      width: 4.7821,
      height: 9.3342,
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

/// 돈주머니 한 개(Figma Group 548/549). 에셋은 Figma SVG를 그대로 세 층으로
/// 나눴다: 몸통(오른쪽은 바닥 그림자 포함) → 어둠 → 매듭·구슬·물방울.
///
/// Figma의 몸통 아래 어둠은 `feGaussianBlur`(4.15)로 흐린 뒤 몸통 모양 마스크로
/// 가린 것이다. flutter_svg는 filter를 그리지 않아 어둠이 선명한 초승달로
/// 나오므로, 어둠 층만 Flutter로 흐리고 [_BagBodyClipper]로 자른다.
class _HomeBag {
  const _HomeBag({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.base,
    required this.shade,
    required this.front,
    required this.body,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  /// 그룹 투명도. 세 층을 합친 뒤 한 번만 입혀야 층끼리 비치지 않는다.
  final double opacity;
  final String base;
  final String shade;
  final String front;

  /// 마스크(몸통) 경로. SVG viewBox 좌표의 시작점 하나와 cubic 네 개다.
  final List<double> body;
}

const _leftBag = _HomeBag(
  left: 59.4769172668457,
  top: 219.634765625,
  width: 65.1013,
  height: 64.6455,
  opacity: 0.58,
  base: FigmaAssets.homeBagLeftBase,
  shade: FigmaAssets.homeBagLeftShade,
  front: FigmaAssets.homeBagLeftFront,
  body: [
    38.1552, 57.92, //
    23.2733, 61.634, 8.69996, 54.5907, 5.6048, 42.1884,
    2.50964, 29.786, 12.0647, 16.7212, 26.9466, 13.0072,
    41.8285, 9.29324, 56.4019, 16.3365, 59.497, 28.7389,
    62.5922, 41.1412, 53.0371, 54.206, 38.1552, 57.92,
  ],
);

const _rightBag = _HomeBag(
  left: 255.00025939941406,
  top: 375,
  width: 120.99,
  height: 128.141,
  opacity: 0.8,
  base: FigmaAssets.homeBagRightBase,
  shade: FigmaAssets.homeBagRightShade,
  front: FigmaAssets.homeBagRightFront,
  body: [
    41.4989, 103.11, //
    64.4183, 113.422, 89.9647, 106.297, 98.5585, 87.1964,
    107.152, 68.0958, 95.5391, 44.2523, 72.6198, 33.9404,
    49.7005, 23.6284, 24.1541, 30.753, 15.5603, 49.8535,
    6.96648, 68.9541, 18.5796, 92.7976, 41.4989, 103.11,
  ],
);

Widget _homeBag(FigmaScale figma, _HomeBag bag) {
  final blur = figma.s(4.15);
  return FigmaBox(
    figma: figma,
    left: bag.left,
    top: bag.top,
    width: bag.width,
    height: bag.height,
    child: Opacity(
      opacity: bag.opacity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FigmaSvg(bag.base, fit: BoxFit.fill),
          ClipPath(
            clipper: _BagBodyClipper(bag),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blur,
                sigmaY: blur,
                tileMode: TileMode.decal,
              ),
              child: FigmaSvg(bag.shade, fit: BoxFit.fill),
            ),
          ),
          FigmaSvg(bag.front, fit: BoxFit.fill),
        ],
      ),
    ),
  );
}

/// [_HomeBag.body]를 박스 크기에 맞춰 늘린 몸통 모양.
class _BagBodyClipper extends CustomClipper<Path> {
  const _BagBodyClipper(this.bag);

  final _HomeBag bag;

  @override
  Path getClip(Size size) {
    final sx = size.width / bag.width;
    final sy = size.height / bag.height;
    final p = bag.body;
    final path = Path()..moveTo(p[0] * sx, p[1] * sy);
    for (var i = 2; i + 5 < p.length; i += 6) {
      path.cubicTo(
        p[i] * sx,
        p[i + 1] * sy,
        p[i + 2] * sx,
        p[i + 3] * sy,
        p[i + 4] * sx,
        p[i + 5] * sy,
      );
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant _BagBodyClipper oldClipper) =>
      oldClipper.bag != bag;
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

/// 옷을 입은 햄핀이. 땅 위로 올라온 부분만 보이도록 아래를 자른다.
///
/// [ShopAvatar]는 서 있는 전신이라 Figma 홈의 엎드린 포즈와 모양이 다르다.
/// 구멍(복습 집)에 몸이 반쯤 묻힌 모습으로 맞춘다. 배경은 홈 티어 배경이
/// 따로 있어 적용하지 않는다.
Widget _customHamster(FigmaScale figma, EquippedLook look) {
  // 디자인 px. 햄핀이 칸의 한가운데(x)다.
  const size = 240.0;
  const left = 128.0 - size / 2;
  const top = 275.0;
  return FigmaBox(
    figma: figma,
    left: left,
    top: top,
    width: size,
    height: size,
    child: ClipPath(
      // 구멍은 둥글어서 일자로 자르면 어색하다. 햄핀이도 구멍 테두리를 따라 자른다.
      clipper: _HoleClipper(
        origin: const Offset(left, top),
        scale: figma.scale,
      ),
      child: look.avatar(),
    ),
  );
}

/// 복습 집에 도착한 홈. 집·곰 로고는 기존 디자인 그대로 두고 햄핀이만
/// 옷 입은 모습으로 바꾼다. 복습 모자는 기본 햄핀이에게만 씌우므로 여기서는
/// 그리지 않는다. 레이어 순서는 [_reviewArrivalHamsterLayers]와 같다:
/// 햄핀이 → 집 앞면 → 곰 로고. 햄핀이 몸 아랫부분은 집 앞면이 가린다.
List<Widget> _customArrivalLayers(
  FigmaScale figma,
  HomeTierTheme tier,
  EquippedLook look,
) {
  // 디자인 px. 기본 햄핀이 머리(89~222, 313~419)와 크기·중심을 맞춘다.
  const size = 185.0;
  const left = 155.0 - size / 2;
  // 기본 햄핀이보다 14px 올려 팔이 집 윗선 위에 걸치게 한다.
  const top = 287.0;
  // 집 앞면 윗선(425) 조금 아래에서 자른다. 집이 그 아래를 덮는다.
  const cutY = 440.0;
  return [
    FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: size,
      height: size,
      child: ClipPath(
        clipper: _CutBelowClipper(figma.s(cutY - top)),
        child: look.avatar(),
      ),
    ),
    FigmaBox(
      key: ValueKey('home-review-arrival-${tier.tier.name}'),
      figma: figma,
      left: 94.2090072631836,
      top: 425.18121337890625,
      width: 122.49980926513672,
      height: 52.8189582824707,
      child: FigmaSvg(tier.reviewArrivalHouse, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 132.93344116210938,
      top: 441.14312744140625,
      width: 44.86116409301758,
      height: 27.560375213623047,
      child: FigmaSvg(FigmaAssets.homeReviewArrivalLayer(28), fit: BoxFit.fill),
    ),
  ];
}

/// [bottom] 아래만 자른다. 위·좌우는 모자 같은 장식이 삐져나와도 둔다.
class _CutBelowClipper extends CustomClipper<Path> {
  const _CutBelowClipper(this.bottom);

  final double bottom;

  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTRB(-size.width, -size.height, size.width * 2, bottom));

  @override
  bool shouldReclip(covariant _CutBelowClipper oldClipper) =>
      oldClipper.bottom != bottom;
}

/// 햄핀이가 들어가는 구멍(Ellipse 100) — 디자인 px. 발판 그림과 두 클리퍼가
/// 같은 값을 써야 테두리가 어긋나지 않는다.
const _hamsterHole = Rect.fromLTWH(45, 373, 166, 95);

/// 구멍 안쪽과 구멍 가운데선 위만 남기는 경로. [origin]은 클리퍼가 붙은 박스의
/// 디자인 좌표다.
Path _holeClipPath(Size size, {required Offset origin, required double scale}) {
  final far = size.longestSide * 2;
  final hole = _hamsterHole.shift(-origin);
  final scaled = Rect.fromLTRB(
    hole.left * scale,
    hole.top * scale,
    hole.right * scale,
    hole.bottom * scale,
  );
  return Path()
    ..addRect(Rect.fromLTRB(-far, -far, far, scaled.center.dy))
    ..addOval(scaled);
}

/// 구멍 안쪽과 그 위만 남긴다. [_DigGroundClipper]의 구멍과 같은 모양이다.
class _HoleClipper extends CustomClipper<Path> {
  const _HoleClipper({required this.origin, required this.scale});

  final Offset origin;
  final double scale;

  @override
  Path getClip(Size size) => _holeClipPath(size, origin: origin, scale: scale);

  @override
  bool shouldReclip(covariant _HoleClipper oldClipper) =>
      oldClipper.origin != origin || oldClipper.scale != scale;
}

/// Figma `541:2666` — 초급·중급 햄스터. 레이어 순서는 Figma와 같다.
List<Widget> _peekHamsterLayers(FigmaScale figma) {
  return [
    FigmaBox(
      figma: figma,
      left: 80.79,
      top: 446.28,
      width: 92.832,
      height: 21.7188,
      child: const FigmaSvg(
        FigmaAssets.homeHamsterPeekBottom,
        fit: BoxFit.fill,
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 157.2,
      top: 436.224,
      width: 26.2414,
      height: 29.7403,
      child: const FigmaSvg(
        FigmaAssets.homeHamsterPeekPawRight,
        fit: BoxFit.fill,
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 72.6264,
      top: 435.7128,
      width: 25.7022,
      height: 30.7572,
      child: Transform.rotate(
        angle: 2.4 * math.pi / 180,
        child: Center(
          child: FigmaSvg(
            FigmaAssets.homeHamsterPeekPawLeft,
            width: figma.s(24.492),
            height: figma.s(29.7403),
            fit: BoxFit.fill,
          ),
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 90.94,
      top: 403.02,
      width: 74.0488,
      height: 64.8257,
      child: const FigmaSvg(FigmaAssets.homeHamsterPeekBelly, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 54,
      top: 330,
      width: 148.427,
      height: 137.373,
      child: const FigmaSvg(FigmaAssets.homeHamsterPeekBody, fit: BoxFit.fill),
    ),
  ];
}

/// Figma `526:2236`~`526:2269` — 복습 집에 도착한 햄핀이. 레이어 순서는 Figma와
/// 같고, 모자와 집 몸통만 티어별 에셋이다.
List<Widget> _reviewArrivalHamsterLayers(FigmaScale figma, HomeTierTheme tier) {
  Widget layer(
    String asset,
    double left,
    double top,
    double width,
    double height,
  ) => FigmaBox(
    figma: figma,
    left: left,
    top: top,
    width: width,
    height: height,
    child: FigmaSvg(asset, fit: BoxFit.fill),
  );
  String shared(int index) => FigmaAssets.homeReviewArrivalLayer(index);

  return [
    layer(
      shared(1),
      105.34921264648438,
      419.0991516113281,
      100.1357192993164,
      30.567745208740234,
    ),
    layer(
      shared(2),
      106.81764221191406,
      355.1837158203125,
      26.944232940673828,
      26.945390701293945,
    ),
    layer(
      shared(3),
      111.66287231445312,
      358.5234069824219,
      16.242603302001953,
      11.878024101257324,
    ),
    layer(
      shared(4),
      114.94287109375,
      371.7411193847656,
      12.433037757873535,
      8.062350273132324,
    ),
    layer(
      shared(5),
      89.36540222167969,
      312.92462158203125,
      133.5634307861328,
      106.18213653564453,
    ),
    layer(
      shared(6),
      69.98957824707031,
      304.780029296875,
      50.748374938964844,
      54.003543853759766,
    ),
    layer(
      shared(7),
      84.10536193847656,
      313.4191589355469,
      68.65987396240234,
      73.0945816040039,
    ),
    layer(
      shared(8),
      166.05194091796875,
      313.4191589355469,
      53.00868606567383,
      50.40515899658203,
    ),
    layer(
      shared(9),
      78.13255310058594,
      384.26055908203125,
      23.141155242919922,
      5.141439437866211,
    ),
    layer(
      shared(10),
      80.59030151367188,
      395.47796630859375,
      18.292335510253906,
      6.879568576812744,
    ),
    layer(
      shared(11),
      210.4187469482422,
      366.4725646972656,
      22.17752456665039,
      9.262642860412598,
    ),
    layer(
      shared(12),
      214.89385986328125,
      380.09033203125,
      18.825349807739258,
      3.9938857555389404,
    ),
    layer(
      shared(13),
      106.81764221191406,
      355.1219482421875,
      26.944232940673828,
      26.945390701293945,
    ),
    layer(
      shared(3),
      111.66287231445312,
      358.5234069824219,
      16.242603302001953,
      11.878024101257324,
    ),
    layer(
      shared(15),
      114.9324951171875,
      371.6885681152344,
      12.433037757873535,
      8.062350273132324,
    ),
    layer(
      shared(16),
      122.30644989013672,
      383.973876953125,
      68.91276550292969,
      14.180625915527344,
    ),
    layer(
      shared(17),
      173.908935546875,
      347.02667236328125,
      26.945072174072266,
      26.944395065307617,
    ),
    layer(
      shared(18),
      178.75369262695312,
      350.3756103515625,
      16.242605209350586,
      11.878024101257324,
    ),
    layer(
      shared(19),
      182.03414916992188,
      363.5822448730469,
      12.433435440063477,
      8.062342643737793,
    ),
    layer(
      shared(20),
      69.97828674316406,
      317.41656494140625,
      29.17258644104004,
      41.315120697021484,
    ),
    layer(
      shared(21),
      175.6124267578125,
      292.3785705566406,
      53.7455940246582,
      52.051185607910156,
    ),
    layer(
      shared(22),
      198.90750122070312,
      301.7413330078125,
      30.419235229492188,
      42.62520217895508,
    ),
    layer(
      tier.reviewArrivalHat,
      101.76271057128906,
      276,
      80.72356414794922,
      59.397308349609375,
    ),
    layer(
      shared(24),
      182.5379180908203,
      390.57305908203125,
      47.97502136230469,
      27.76566505432129,
    ),
    layer(
      shared(25),
      114.6983642578125,
      411.44683837890625,
      81.2469482421875,
      30.251523971557617,
    ),
    layer(
      shared(26),
      123.93205261230469,
      411.5731201171875,
      64.20281219482422,
      21.556182861328125,
    ),
    FigmaBox(
      key: ValueKey('home-review-arrival-${tier.tier.name}'),
      figma: figma,
      left: 94.2090072631836,
      top: 425.18121337890625,
      width: 122.49980926513672,
      height: 52.8189582824707,
      child: FigmaSvg(tier.reviewArrivalHouse, fit: BoxFit.fill),
    ),
    layer(
      shared(28),
      132.93344116210938,
      441.14312744140625,
      44.86116409301758,
      27.560375213623047,
    ),
    // 526:2269 — rotate(-6.31deg). 박스는 회전 후 바운딩 박스다.
    FigmaBox(
      figma: figma,
      left: 99.8663330078125,
      top: 405.5886,
      width: 28.6896,
      height: 25.4841,
      child: Center(
        child: Transform.rotate(
          angle: -6.31 * math.pi / 180,
          child: FigmaSvg(
            shared(29),
            width: figma.s(26.3515),
            height: figma.s(22.7255),
            fit: BoxFit.fill,
          ),
        ),
      ),
    ),
  ];
}

/// 햄핀이가 파고드는 땅. 구멍은 Ellipse 100 앞쪽 테두리, 복습 집은 집 바닥선이다.
enum _DigGround {
  hole(sinkDistance: 150, dirtCenter: Offset(128, 415), dirtHalfWidth: 76),
  house(sinkDistance: 205, dirtCenter: Offset(155, 476), dirtHalfWidth: 58);

  const _DigGround({
    required this.sinkDistance,
    required this.dirtCenter,
    required this.dirtHalfWidth,
  });

  /// 완전히 땅속에 들어갈 때까지 내려가는 거리(디자인 px).
  final double sinkDistance;

  /// 흙이 튀는 자리(디자인 px). 햄핀이를 가리지 않게 양옆 가장자리에서 튄다.
  final Offset dirtCenter;
  final double dirtHalfWidth;
}

/// 학습을 시작할 때 땅을 파고 들어가고, 끝나면 파고 올라오는 햄핀이.
class _DiggingHamster extends StatelessWidget {
  const _DiggingHamster({
    required this.figma,
    required this.dig,
    required this.ground,
    required this.dirtColor,
    required this.layers,
  });

  final FigmaScale figma;
  final Animation<double> dig;
  final _DigGround ground;
  final Color dirtColor;
  final List<Widget> layers;

  static const _dirtCount = 6;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: dig,
        child: Stack(clipBehavior: Clip.none, children: layers),
        builder: (context, hamster) {
          final t = dig.value;
          // 파는 동안 좌우로 버둥거린다. 양 끝(0·1)에서는 흔들림이 0이다.
          final wiggle = math.sin(t * math.pi * 6) * 3;
          final moved = Transform.translate(
            offset: Offset(figma.s(wiggle), figma.s(ground.sinkDistance * t)),
            child: hamster,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 제자리에서는 발이 구멍 테두리에 걸쳐 있어 자르지 않는다.
              // 자르기만 끄고 위젯은 그대로 둬야 0을 오갈 때 햄스터 레이어를
              // 통째로 다시 만들지 않는다.
              ClipPath(
                clipper: _DigGroundClipper(ground: ground, scale: figma.scale),
                clipBehavior: t == 0 ? Clip.none : Clip.antiAlias,
                child: moved,
              ),
              if (t > 0 && t < 1) ..._dirt(t),
            ],
          );
        },
      ),
    );
  }

  /// 구멍 양옆 가장자리에서 바깥으로 튀는 흙 알갱이. 움직임 한가운데서 가장 높이 튄다.
  List<Widget> _dirt(double t) {
    final lift = math.sin(t * math.pi);
    return [
      for (var i = 0; i < _dirtCount; i++)
        () {
          final side = i.isEven ? -1.0 : 1.0;
          final k = i ~/ 2;
          final x =
              ground.dirtCenter.dx +
              side * (ground.dirtHalfWidth - k * 9 + (8 + k * 7) * lift);
          final y = ground.dirtCenter.dy - k * 8 - (12 + k * 9) * lift;
          final size = 4.5 + (k % 2) * 2.5;
          return Positioned(
            left: figma.s(x - size / 2),
            top: figma.s(y - size / 2),
            width: figma.s(size),
            height: figma.s(size),
            child: Opacity(
              opacity: lift.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dirtColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }(),
    ];
  }
}

/// 땅 위(구멍 안쪽 포함)만 남긴다. 햄핀이가 내려가면 앞쪽 테두리 아래가 가려진다.
class _DigGroundClipper extends CustomClipper<Path> {
  const _DigGroundClipper({required this.ground, required this.scale});

  final _DigGround ground;
  final double scale;

  @override
  Path getClip(Size size) {
    final far = size.longestSide * 2;
    switch (ground) {
      case _DigGround.hole:
        return _holeClipPath(size, origin: Offset.zero, scale: scale);
      case _DigGround.house:
        return Path()..addRect(Rect.fromLTRB(-far, -far, far, 478 * scale));
    }
  }

  @override
  bool shouldReclip(covariant _DigGroundClipper oldClipper) =>
      oldClipper.ground != ground || oldClipper.scale != scale;
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

Widget _homeSparkleSquare({
  required FigmaScale figma,
  required double left,
  required double top,
  required double boxSize,
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
        child: Container(
          width: figma.s(7.534),
          height: figma.s(7.534),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(figma.s(3)),
          ),
        ),
      ),
    ),
  );
}

/// 왼쪽 스파클 Vector — 회전한 바운딩 박스 가운데에 원래 크기로 돌려 그린다.
Widget _homeSparkle({
  required FigmaScale figma,
  required double left,
  required double top,
  required double width,
  required double height,
  required double degrees,
  required Color color,
}) {
  return FigmaBox(
    figma: figma,
    left: left,
    top: top,
    width: width,
    height: height,
    child: Center(
      child: Transform.rotate(
        angle: degrees * math.pi / 180,
        child: FigmaSvg(
          FigmaAssets.homeSparkle,
          width: figma.s(22.5381),
          height: figma.s(22.0139),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    ),
  );
}

/// 흐린 타원 그림자. Figma의 multiply·plus-darker 블렌드와 blur를 flutter_svg가
/// 그리지 않아 직접 칠한다. plus-darker는 Flutter에 없어서, 밝은 배경에서
/// 결과가 거의 같은 multiply로 대신한다.
Widget _blurredEllipse({
  required FigmaScale figma,
  required double left,
  required double top,
  required double width,
  required double height,
  required Color color,
  required double blurSigma,
}) {
  return FigmaBox(
    figma: figma,
    left: left,
    top: top,
    width: width,
    height: height,
    child: CustomPaint(
      painter: _BlurredEllipsePainter(
        color: color,
        blurSigma: figma.s(blurSigma),
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _BlurredEllipsePainter extends CustomPainter {
  const _BlurredEllipsePainter({required this.color, required this.blurSigma});

  final Color color;
  final double blurSigma;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Offset.zero & size,
      Paint()
        ..color = color
        ..blendMode = BlendMode.multiply
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
    );
  }

  @override
  bool shouldRepaint(covariant _BlurredEllipsePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.blurSigma != blurSigma;
}

/// 오각형이 발판에 드리운 그림자. SVG의 blur·overlay 블렌드는 flutter_svg가
/// 그리지 않아서, 같은 경로를 직접 칠한다.
Widget _stageShadow({
  required FigmaScale figma,
  required double left,
  required double top,
  required double width,
  required double height,
  required double degrees,
  required bool flipX,
  required double blurSigma,
  required Path path,
  required Size viewBox,
}) {
  return FigmaBox(
    figma: figma,
    left: left,
    top: top,
    width: width,
    height: height,
    child: OverflowBox(
      minWidth: 0,
      minHeight: 0,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.rotate(
        angle: degrees * math.pi / 180,
        child: Transform.flip(
          flipX: flipX,
          child: CustomPaint(
            size: Size(figma.s(viewBox.width), figma.s(viewBox.height)),
            painter: _StageShadowPainter(
              path: path,
              scale: figma.s(1),
              blurSigma: blurSigma,
            ),
          ),
        ),
      ),
    ),
  );
}

class _StageShadowPainter extends CustomPainter {
  const _StageShadowPainter({
    required this.path,
    required this.scale,
    required this.blurSigma,
  });

  final Path path;
  final double scale;
  final double blurSigma;

  @override
  void paint(Canvas canvas, Size size) {
    // Impeller(iOS·Android)는 MaskFilter.blur와 BlendMode.overlay를 한 Paint에
    // 함께 쓰면 그림자를 아예 그리지 않는다. 모양은 레이어에 그리고 블러와
    // overlay는 레이어를 합칠 때 적용한다.
    final sigma = blurSigma * scale;
    canvas.saveLayer(
      null,
      Paint()
        ..blendMode = BlendMode.overlay
        ..imageFilter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
    canvas.drawPath(
      path.transform(Matrix4.diagonal3Values(scale, scale, 1).storage),
      Paint()..color = const Color(0xFF2A1D00),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StageShadowPainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.scale != scale ||
      oldDelegate.blurSigma != blurSigma;
}

final _stageShadowSmallPath = Path()
  ..moveTo(10.1714, 5.86183)
  ..cubicTo(11.0359, 4.17944, 12.208, 4.17944, 13.0726, 5.86183)
  ..lineTo(17.6258, 14.7194)
  ..cubicTo(18.4904, 16.4018, 18.8534, 19.3855, 18.5217, 22.1077)
  ..lineTo(16.7829, 36.4419)
  ..cubicTo(16.4525, 39.164, 15.5048, 41.0079, 14.4352, 41.0079)
  ..lineTo(8.80757, 41.0079)
  ..cubicTo(7.738, 41.0079, 6.79022, 39.164, 6.45982, 36.4419)
  ..lineTo(4.72101, 22.1077)
  ..cubicTo(4.39062, 19.3855, 4.75236, 16.4018, 5.61815, 14.7194)
  ..close();

final _stageShadowLargePath = Path()
  ..moveTo(14.8913, 7.4447)
  ..cubicTo(16.3853, 4.53764, 18.4105, 4.53764, 19.9045, 7.4447)
  ..lineTo(27.7722, 22.75)
  ..cubicTo(29.2661, 25.6571, 29.8933, 30.8128, 29.3203, 35.5166)
  ..lineTo(26.3157, 60.2852)
  ..cubicTo(25.7448, 64.989, 24.1071, 68.175, 22.259, 68.175)
  ..lineTo(12.5348, 68.175)
  ..cubicTo(10.6866, 68.175, 9.04891, 64.989, 8.478, 60.2852)
  ..lineTo(5.47344, 35.5166)
  ..cubicTo(4.90254, 30.8128, 5.52762, 25.6571, 7.02365, 22.75)
  ..close();

final _stageShadowAheadPath = Path()
  ..moveTo(8.17691, 4.7124)
  ..cubicTo(8.87195, 3.35991, 9.8142, 3.35991, 10.5092, 4.7124)
  ..lineTo(14.1696, 11.8331)
  ..cubicTo(14.8647, 13.1856, 15.1565, 15.5843, 14.8899, 17.7727)
  ..lineTo(13.492, 29.2961)
  ..cubicTo(13.2264, 31.4845, 12.4645, 32.9668, 11.6046, 32.9668)
  ..lineTo(7.08053, 32.9668)
  ..cubicTo(6.22069, 32.9668, 5.45875, 31.4845, 5.19314, 29.2961)
  ..lineTo(3.79529, 17.7727)
  ..cubicTo(3.52968, 15.5843, 3.82049, 13.1856, 4.51651, 11.8331)
  ..close();

/// Figma `526:3264`~`526:3270` — 다음 칸에서 기다리는 복습 집.
List<Widget> _reviewHouseLayers(FigmaScale figma, HomeTierTheme tier) {
  return [
    FigmaBox(
      key: ValueKey('home-review-house-${tier.tier.name}'),
      figma: figma,
      left: 171,
      top: 508.970703125,
      width: 137,
      height: 127.01041412353516,
      child: FigmaSvg(tier.reviewHouseBody, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 210.068359375,
      top: 586.03125,
      width: 58.55109405517578,
      height: 41.38420867919922,
      child: const FigmaSvg(FigmaAssets.homeReviewHouseIcon, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 226.6591796875,
      top: 479,
      width: 25.687498092651367,
      height: 25.687498092651367,
      child: FigmaSvg(tier.reviewHouseDot, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 171,
      top: 508.9684143066406,
      width: 137.00022888183594,
      height: 63.101898193359375,
      child: FigmaSvg(tier.reviewHouseRoof, fit: BoxFit.fill),
    ),
  ];
}

/// Figma `131:5342` — 맵 스크롤과 무관하게 하단에 고정.
class _HomeLearningCta extends StatelessWidget {
  const _HomeLearningCta({
    required this.figma,
    required this.tier,
    required this.onTap,
  });

  final FigmaScale figma;
  final HomeTierTheme tier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final originX = tier.learningCtaLeft;
    const iconSize = 47.0;
    const chevronSize = 46.055;
    const textHeight = 33.8;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tier.learningCtaColor,
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
              '오늘의 학습',
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
            left: s(309 - originX),
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
    required this.shapeSize,
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

  // 회전 전 오각형 박스. Figma 컨테이너(회전 후 바운딩 박스)에서 역산한 값이다.
  static const _smallShapeSize = Size(44.575, 43.570);
  static const _largeShapeSize = Size(77.050, 75.258);

  final FigmaScale figma;
  final double left;
  final double top;
  final double width;
  final double height;

  /// 회전 전 오각형 박스(디자인 px).
  final Size shapeSize;
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
    // Figma 외곽선은 글자 바깥쪽에만 붙는다. Flutter 외곽선은 선 중심 기준이라
    // 두 배로 그리고 안쪽 절반은 채움 글자가 덮는다.
    TextStyle outlined(Color color) => style.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s(labelStroke * 2)
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    Widget shape(Color color) => Transform.rotate(
      angle: _rotation,
      child: _StagePentagonShape(
        size: Size(s(shapeSize.width), s(shapeSize.height)),
        color: color,
        isLarge: isLarge,
      ),
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
          // Figma 그림자 효과는 레이어 회전과 무관하게 화면 기준으로 떨어진다.
          Transform.translate(
            offset: Offset(s(extrusionOffset.dx), s(extrusionOffset.dy)),
            child: shape(extrusion),
          ),
          shape(fill),
          // 글자 그림자는 외곽선까지 포함한 모양으로 떨어진다. Text.shadows는
          // 얇은 Thin 글자 모양으로만 그려져 흰 외곽선에 가려서 따로 깐다.
          Transform.translate(
            offset: Offset(s(labelShadowOffset.dx), s(labelShadowOffset.dy)),
            child: Text(label, style: outlined(labelShadowColor)),
          ),
          Text(label, style: outlined(Colors.white)),
          Text(label, style: style.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

/// 홈 단계 오각형 한 겹. 원본 SVG를 [color] 한 색으로 칠한다.
///
/// flutter_svg는 SVG의 drop-shadow filter를 그리지 않아서, [_HomeStagePentagon]이
/// 같은 모양을 그림자 색으로 한 번 더 옮겨 깐다. 티어마다 모양이 같고 색만 달라
/// SVG는 한 벌이고 색은 [HomeTierTheme]에서 받는다.
class _StagePentagonShape extends StatelessWidget {
  const _StagePentagonShape({
    required this.size,
    required this.color,
    required this.isLarge,
  });

  final Size size;
  final Color color;
  final bool isLarge;

  // 박스는 경로가 차지하는 영역(Figma bounds)에 맞춘다. SVG viewBox는 그림자 필터
  // 여백까지 포함해 더 크므로, 경로 영역이 박스에 딱 맞도록 SVG를 옮겨 늘린다.
  static const _smallViewBox = Size(46.9314, 45.8943);
  static const _smallShapeOrigin = Offset.zero;
  static const _largeViewBox = Size(80.3883, 81.0902);
  static const _largeShapeOrigin = Offset(3.32549, 0);

  @override
  Widget build(BuildContext context) {
    final asset = isLarge
        ? FigmaAssets.homeStagePentagonLarge
        : FigmaAssets.homeStagePentagonSmall;
    final viewBox = isLarge ? _largeViewBox : _smallViewBox;
    final shapeOrigin = isLarge ? _largeShapeOrigin : _smallShapeOrigin;
    final shapeSize = isLarge
        ? _HomeStagePentagon._largeShapeSize
        : _HomeStagePentagon._smallShapeSize;
    final sx = size.width / shapeSize.width;
    final sy = size.height / shapeSize.height;

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -shapeOrigin.dx * sx,
            top: -shapeOrigin.dy * sy,
            width: viewBox.width * sx,
            height: viewBox.height * sy,
            child: FigmaSvg(
              asset,
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ],
      ),
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
