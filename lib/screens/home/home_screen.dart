import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/interest_categories.dart';
import '../../data/quiz_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/news_service.dart';
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

/// Figma `131:5342` 오늘의 학습 CTA — 하단 고정 오버레이용.
const _homeLearningCtaLeft = 34.0;
const _homeLearningCtaDesignHeight = 84.247;
const _homeLearningCtaHeightScale = 0.75;
const _homeLearningCtaHeight =
    _homeLearningCtaDesignHeight * _homeLearningCtaHeightScale;
const _homeLearningCtaTop = 666.0;
const _homeLearningCtaWidth = 328.0;
const _homeLearningCtaBottomDesign =
    _homeLearningCtaTop + _homeLearningCtaDesignHeight;
const _homeLearningCtaBottomGap =
    FigmaScale.homeContentHeight - _homeLearningCtaBottomDesign;
const _homeLearningCtaScrollPadding = FigmaScale.homeContentHeight -
    (_homeLearningCtaBottomDesign - _homeLearningCtaHeight);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  bool _loading = true;

  /// 뉴스바에 돌릴 TOP 10. 뉴스 탭과 같은 캐시를 쓴다(1시간 TTL).
  List<NewsItem> _news = const [];
  int _newsIndex = 0;
  Timer? _newsTimer;

  /// 뉴스바가 한 건을 보여주는 시간.
  static const _newsSlideInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNews();
    _newsTimer = Timer.periodic(_newsSlideInterval, (_) => _rotateNews());
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshHome() async {
    await Future.wait([_loadProfile(), _loadNews()]);
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _startQuiz() async {
    final profile = _profile;
    if (profile == null) return;

    if (profile.energy < QuizData.sessionEnergyCost) {
      if (!mounted) return;
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

    if (resolveActiveInterestCategoryId(profile.interestCategories) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학습 카테고리를 먼저 선택해 주세요.')),
      );
      await _openCategorySwitcher();
      return;
    }

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(profile: profile)),
    );

    if (completed == true || mounted) {
      await _loadProfile();
    }
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
  /// 아직 못 불러왔으면 구글뉴스 비즈니스 섹션으로 보낸다(빈 탭 방지).
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShopScreen(profile: profile)),
    );
    await _loadProfile();
  }

  void _openStreakCalendar() {
    final profile = _profile;
    if (profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StreakCalendarScreen(
          streak: profile.streak,
          studyGuardCount: profile.studyGuardCount,
          completedDates: profile.learningHistory
              .map((record) => record.date)
              .toSet(),
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
      return const Scaffold(
        body: Center(child: Text('사용자 정보를 불러올 수 없습니다.')),
      );
    }

    final canStart = profile.energy >= QuizData.sessionEnergyCost;

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
                extraBottomPaddingDesign: _homeLearningCtaScrollPadding,
                builder: (context, figma) => _buildFigmaHomeLayers(
                  figma: figma,
                  energy: profile.energy,
                  coin: profile.seeds,
                  streak: profile.streak,
                  newsTitle: _newsBarTitle,
                  onMenu: _openCategorySwitcher,
                  onNews: _openNews,
                  onShop: _openShop,
                  onStreakCalendar: _openStreakCalendar,
                ),
              ),
              Positioned(
                left: figma.s(_homeLearningCtaLeft),
                bottom: figma.s(_homeLearningCtaBottomGap),
                width: figma.s(_homeLearningCtaWidth),
                height: figma.s(_homeLearningCtaHeight),
                child: _HomeLearningCta(
                  figma: figma,
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
  required int energy,
  required int coin,
  required int streak,
  required String newsTitle,
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
    // ── 131:5279~5324 학습 경로 (관람차 원 + 섹터) ──
    FigmaBox(
      figma: figma,
      left: 139.59765625,
      top: 143,
      width: 485.3046875,
      height: 541.802734375,
      child: const FigmaSvg(FigmaAssets.homePathMap, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 219,
      top: 186,
      width: 131,
      height: 66,
      child: const FigmaSvg(FigmaAssets.homeEllipse154, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 302.0035400390625,
      top: 210.01507568359375,
      width: 29.65591569747437,
      height: 12.33499826037405,
      child: const FigmaSvg(FigmaAssets.homeNode1Overlay, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 145,
      top: 514,
      width: 210,
      height: 119,
      child: const FigmaSvg(FigmaAssets.homeEllipse155, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 45,
      top: 373,
      width: 166,
      height: 95,
      child: const FigmaSvg(FigmaAssets.homeEllipse100, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 258.90625,
      top: 359.197265625,
      width: 46.0875624669402,
      height: 46.427402590952624,
      child: const FigmaSvg(FigmaAssets.homeDecoVector1, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 221.388671875,
      top: 399.357421875,
      width: 18.94550179868429,
      height: 18.72608362290339,
      child: const FigmaSvg(FigmaAssets.homeDecoVector3, fit: BoxFit.fill),
    ),
    FigmaBox(
      figma: figma,
      left: 22,
      top: 356.4765625,
      width: 24.489221139918072,
      height: 23.995337006143018,
      child: const FigmaSvg(FigmaAssets.homeDecoVector4, fit: BoxFit.fill),
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
      top: 125.04296875,
      width: 14.255,
      height: 13.679,
      child: const FigmaSvg(
        FigmaAssets.homeBeginnerMegaphone,
        fit: BoxFit.fill,
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 71.525390625,
      top: 126.6640625,
      width: 258,
      height: 16,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Align(
            key: ValueKey(newsLine),
            alignment: Alignment.centerLeft,
            child: Text(
              newsLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: s(8.747),
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

    // ── 131:5322/5421, 131:5423/5424 스테이지 오각형 + 번호 ──
    _HomeStagePentagon(
      figma: figma,
      left: 304.9996337890625,
      top: 181.42132568359375,
      width: 40.99964304702837,
      height: 41.66641630988579,
      asset: FigmaAssets.homeDecoVector2,
      label: '1',
      fontSize: 15.167,
      shadowOffset: Offset(0.782, 0.782),
      svgBleed: const EdgeInsets.only(right: 0.0523, bottom: 0.0536),
    ),
    FigmaBox(
      figma: figma,
      left: 222.1222686767578,
      top: 556.8336181640625,
      width: 55.69799777731794,
      height: 23.166871005831126,
      child: const FigmaSvg(FigmaAssets.homeNode3Overlay, fit: BoxFit.fill),
    ),
    _HomeStagePentagon(
      figma: figma,
      left: 294.0031433105469,
      top: 502.0601501464844,
      width: 77.00312867523678,
      height: 78.25542120861064,
      asset: FigmaAssets.homeNode3Flag,
      label: '3',
      fontSize: 28.485,
      shadowOffset: Offset(-1.453, 1.468),
      svgBleed: const EdgeInsets.only(left: 0.0432, bottom: 0.0773),
    ),

    // ── 162:421 햄스터 (최상단) ──
    FigmaBox(
      figma: figma,
      left: 52,
      top: 324,
      width: 152,
      height: 144,
      child: const FigmaSvg(FigmaAssets.homeHamsterMap, fit: BoxFit.contain),
    ),
  ];
}

/// Figma `131:5342` — 맵 스크롤과 무관하게 하단에 고정.
class _HomeLearningCta extends StatelessWidget {
  const _HomeLearningCta({
    required this.figma,
    required this.canStartLearning,
    required this.onTap,
  });

  final FigmaScale figma;
  final bool canStartLearning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final v = _homeLearningCtaHeightScale;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: canStartLearning
                  ? const Color(0xFF3CC6FF)
                  : const Color(0xFF3CC6FF).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(s(13 * v)),
            ),
            child: SizedBox(
              width: s(_homeLearningCtaWidth),
              height: s(_homeLearningCtaHeight),
            ),
          ),
          Positioned(
            left: s(15),
            top: s(18 * v),
            width: s(47 * v),
            height: s(47 * v),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(s(7.5 * v)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: Offset(s(3 * v), s(3 * v)),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: s(6 * v),
                  top: s(9 * v),
                  right: s(7 * v),
                  bottom: s(10 * v),
                ),
                child: const FigmaSvg(
                  FigmaAssets.homeBeginnerLearningQ,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: s(101),
            top: s(24 * v),
            child: Text(
              canStartLearning ? '오늘의 학습' : '에너지 부족',
              style: TextStyle(
                fontSize: s(26 * v),
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
          Positioned(
            left: s(275),
            top: s(18 * v),
            width: s(46.055 * v),
            height: s(46.055 * v),
            child: const FigmaSvg(
              FigmaAssets.homeBeginnerChevronLearning,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma 131:5322 / 131:5423 오각형 + 131:5421 / 131:5424 번호.
///
/// Figma MCP 기준 번호는 오각형 bounds 안에서 center 정렬된다.
/// SVG는 inset bleed(그림자)만큼 box 밖으로 확장한다.
class _HomeStagePentagon extends StatelessWidget {
  const _HomeStagePentagon({
    required this.figma,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.asset,
    required this.label,
    required this.fontSize,
    required this.shadowOffset,
    required this.svgBleed,
  });

  final FigmaScale figma;
  final double left;
  final double top;
  final double width;
  final double height;
  final String asset;
  final String label;
  final double fontSize;
  final Offset shadowOffset;

  /// Figma export `inset-[...]` — 비율(0~1)로 box 대비 bleed.
  final EdgeInsets svgBleed;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -width * svgBleed.left,
            top: -height * svgBleed.top,
            right: -width * svgBleed.right,
            bottom: -height * svgBleed.bottom,
            child: FigmaSvg(asset, fit: BoxFit.fill),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: s(fontSize),
              fontWeight: FontWeight.w200,
              color: Colors.white,
              height: 1,
              shadows: [
                Shadow(
                  offset: Offset(s(shadowOffset.dx), s(shadowOffset.dy)),
                  color: const Color(0xFFCD5500).withValues(alpha: 0.25),
                ),
              ],
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
          Positioned(
            top: s(16.1),
            child: _square(s, const Color(0xFFFFCA55)),
          ),
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
