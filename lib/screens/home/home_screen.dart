import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../data/quiz_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../widgets/category_switcher_sheet.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_canvas.dart';
import '../../widgets/figma/figma_scale.dart';
import '../calendar/streak_calendar_screen.dart';
import '../quiz/quiz_screen.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
        setState(() => profile.interestCategories = updated);
      },
    );
  }

  void _openNews() {
    // 나중에 추가: HOT 뉴스/공지 화면
  }

  void _openDigging() {
    // 나중에 추가: 땅 파기(캐릭터 특기) 기능
  }

  void _openBookmark() {
    // 나중에 추가: 북마크/학습 저장 기능
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
        builder: (_) => StreakCalendarScreen(streak: profile.streak),
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
    final energyProgress = profile.energy / QuizData.maxEnergy;
    final progressFillWidth = 157.0 * energyProgress;
    final hamsterDisplayName =
        profile.nickname.isNotEmpty ? profile.nickname : '아깅햄핀';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: FigmaCanvas(
        designWidth: FigmaScale.homeDesignWidth,
        designHeight: FigmaScale.homeContentHeight,
        builder: (context, figma) => _buildFigmaHomeLayers(
          figma: figma,
          energy: profile.energy,
          coin: profile.seeds,
          streak: profile.streak,
          level: profile.level,
          hamsterName: hamsterDisplayName,
          questCompleted: profile.energy,
          questTotal: QuizData.maxEnergy,
          progressFillWidth: progressFillWidth,
          canStartLearning: canStart,
          onMenu: _openCategorySwitcher,
          onNews: _openNews,
          onDigging: _openDigging,
          onBookmark: _openBookmark,
          onShop: _openShop,
          onStreakCalendar: _openStreakCalendar,
          onStartLearning: _startQuiz,
        ),
      ),
    );
  }
}

List<Widget> _buildFigmaHomeLayers({
  required FigmaScale figma,
  required int energy,
  required int coin,
  required int streak,
  required int level,
  required String hamsterName,
  required int questCompleted,
  required int questTotal,
  required double progressFillWidth,
  required bool canStartLearning,
  required VoidCallback onMenu,
  required VoidCallback onNews,
  required VoidCallback onDigging,
  required VoidCallback onBookmark,
  required VoidCallback onShop,
  required VoidCallback onStreakCalendar,
  required VoidCallback onStartLearning,
}) {
  final s = figma.s;

  return [
      // 83:4, 83:5 배경 원
      FigmaBox(
        figma: figma,
        left: -477,
        top: 1510,
        width: 924,
        height: 924,
        child: const FigmaSvg(FigmaAssets.bgBottom, fit: BoxFit.fill),
      ),
      FigmaBox(
        figma: figma,
        left: 300,
        top: -1255,
        width: 2976,
        height: 2976,
        child: const FigmaSvg(FigmaAssets.bgTop, fit: BoxFit.fill),
      ),

      // 83:7, 83:13 뉴스 배너
      FigmaPill(
        figma: figma,
        left: 108,
        top: 280,
        width: 1011,
        height: 104,
        color: const Color(0xFF99C9CA),
        radius: 44,
      ),
      FigmaPill(
        figma: figma,
        left: 102,
        top: 268,
        width: 1011,
        height: 104,
        color: const Color(0xFFB7F1F3),
        radius: 44,
      ),

      // 83:8~9, 83:14 레벨 pill
      FigmaPill(
        figma: figma,
        left: 299.06,
        top: 1469.54,
        width: 588.962,
        height: 125.311,
        color: const Color(0xFFACC5CF),
        radius: 75.187,
      ),
      FigmaPill(
        figma: figma,
        left: 288,
        top: 1443,
        width: 588.962,
        height: 125.311,
        color: const Color(0xFFCFDFE5),
        radius: 75.187,
      ),
      FigmaPill(
        figma: figma,
        left: 295,
        top: 1456,
        width: 588.962,
        height: 125.311,
        color: const Color(0xFFEEF9FD),
        radius: 75.187,
      ),

      // 83:11, 83:12 학습 카드
      FigmaPill(
        figma: figma,
        left: 105,
        top: 1745,
        width: 1029,
        height: 633,
        color: const Color(0xFFABC8D3),
        radius: 95,
      ),
      FigmaPill(
        figma: figma,
        left: 82,
        top: 1721,
        width: 1029,
        height: 633,
        color: const Color(0xFFDDF6FF),
        radius: 95,
      ),

      // 83:91 학습 버튼 배경
      FigmaPill(
        figma: figma,
        left: 158.9,
        top: 2114,
        width: 876,
        height: 141,
        color: const Color(0xFF9CE5FF),
        radius: 46.285,
      ),

      // 83:80 메뉴 버튼
      _FigmaMenuButton(figma: figma, onTap: onMenu),

      // 83:197, 83:181, 83:185, 83:196 스탯
      FigmaBox(
        figma: figma,
        left: 343,
        top: 111,
        width: 135,
        height: 83,
        child: const FigmaSvg(FigmaAssets.statEnergy, fit: BoxFit.contain),
      ),
      FigmaLabel(
        figma: figma,
        left: 478.62,
        top: 130.37,
        text: '$energy',
        fontSize: 37,
        color: const Color(0xFFFBB03B),
        fontWeight: FontWeight.w600,
      ),
      FigmaBox(
        figma: figma,
        left: 667,
        top: 110,
        width: 107,
        height: 83,
        child: const FigmaSvg(FigmaAssets.statCoin, fit: BoxFit.contain),
      ),
      FigmaLabel(
        figma: figma,
        left: 774,
        top: 135,
        text: '$coin',
        fontSize: 37,
        color: const Color(0xFFFFCA55),
        fontWeight: FontWeight.w600,
      ),
      FigmaTapArea(
        figma: figma,
        left: 650,
        top: 100,
        width: 220,
        height: 110,
        onTap: onShop,
        child: const SizedBox.expand(),
      ),
      FigmaBox(
        figma: figma,
        left: 980,
        top: 108,
        width: 68.249,
        height: 83.999,
        child: const FigmaSvg(FigmaAssets.statStreak, fit: BoxFit.contain),
      ),
      FigmaLabel(
        figma: figma,
        left: 1072.37,
        top: 135,
        text: '$streak',
        fontSize: 37,
        color: const Color(0xFFFB8B3B),
        fontWeight: FontWeight.w600,
      ),
      FigmaTapArea(
        figma: figma,
        left: 960,
        top: 100,
        width: 220,
        height: 110,
        onTap: onStreakCalendar,
        child: const SizedBox.expand(),
      ),

      // 83:19, 83:17, 83:67 뉴스
      FigmaBox(
        figma: figma,
        left: 144,
        top: 299,
        width: 44,
        height: 42.222,
        child: const FigmaSvg(FigmaAssets.megaphone, fit: BoxFit.fill),
      ),
      FigmaLabel(
        figma: figma,
        left: 224,
        top: 300,
        text: 'HOT 뉴스 / 기사 제목 ~',
        fontSize: 34,
        width: 867,
      ),
      FigmaBox(
        figma: figma,
        left: 1060,
        top: 303,
        width: 20,
        height: 34.754,
        child: const FigmaSvg(FigmaAssets.chevronRight, fit: BoxFit.fill),
      ),
      FigmaTapArea(
        figma: figma,
        left: 102,
        top: 268,
        width: 1011,
        height: 104,
        onTap: onNews,
        child: const SizedBox.shrink(),
      ),

      // 83:31~43 말풍선
      ..._speechBubbleLayers(figma),

      // 87:3 메인 햄스터 — 단일 PNG (스프라이트 크롭 금지)
      FigmaCenterBox(
        figma: figma,
        designWidth: FigmaScale.homeDesignWidth,
        top: 817,
        width: 502,
        height: 600,
        centerOffsetX: -0.34,
        child: const FigmaPng(
          FigmaAssets.hamsterAuth,
          fit: BoxFit.contain,
          clip: true,
        ),
      ),

      // 83:15~18, 83:16 레벨 pill 텍스트
      FigmaLabel(
        figma: figma,
        left: 344,
        top: 1496,
        text: 'Lv.$level $hamsterName',
        fontSize: 37,
      ),
      FigmaBox(
        figma: figma,
        left: 641.42,
        top: 1490.98,
        width: 4.177,
        height: 54.301,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFB0C5CD),
            borderRadius: BorderRadius.circular(s(2.089)),
          ),
        ),
      ),
      FigmaTapArea(
        figma: figma,
        left: 713,
        top: 1496,
        width: 121,
        height: 46,
        onTap: onDigging,
        child: Text(
          '땅 파기',
          style: TextStyle(
            fontSize: s(37),
            color: Colors.black,
            height: 1.1,
          ),
        ),
      ),

      // 83:93 프레임 + 87:5 카드 썸네일 (Figma: left calc(50%-334.84px) → frame 기준 x=53.16)
      FigmaBox(
        figma: figma,
        left: 158,
        top: 1809,
        width: 235.677,
        height: 254.867,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: figma.s(53.16),
              top: figma.s(45),
              width: figma.s(145),
              height: figma.s(173),
              child: const FigmaPng(
                FigmaAssets.hamsterAuth,
                fit: BoxFit.contain,
                clip: true,
              ),
            ),
            const FigmaSvg(FigmaAssets.cardHamsterFrame, fit: BoxFit.fill),
          ],
        ),
      ),

      // 83:96~102 퀘스트
      FigmaPill(
        figma: figma,
        left: 447.9,
        top: 1920,
        width: 346,
        height: 62,
        color: Colors.white,
        radius: 17,
      ),
      FigmaLabel(
        figma: figma,
        left: 521.9,
        top: 1935,
        text: '에너지    $questCompleted / $questTotal',
        fontSize: 28,
      ),
      FigmaBox(
        figma: figma,
        left: 465.9,
        top: 1931,
        width: 40.114,
        height: 40.114,
        child: const FigmaSvg(FigmaAssets.questIconCircle, fit: BoxFit.fill),
      ),
      FigmaBox(
        figma: figma,
        left: 482.79,
        top: 1957.51,
        width: 6.054,
        height: 6.054,
        child: const FigmaSvg(FigmaAssets.questIconDot, fit: BoxFit.fill),
      ),
      FigmaBox(
        figma: figma,
        left: 482.79,
        top: 1937.51,
        width: 6.054,
        height: 18.162,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(s(3.027)),
          ),
        ),
      ),
      FigmaPill(
        figma: figma,
        left: 447.9,
        top: 2016.33,
        width: 587,
        height: 47.339,
        color: Colors.white,
        radius: 32.136,
      ),
      FigmaPill(
        figma: figma,
        left: 456.9,
        top: 2024.25,
        width: progressFillWidth.clamp(31, 587),
        height: 31,
        color: const Color(0xFF46CABF),
        radius: 33.942,
      ),

      // 83:103~111 Q 아이콘 + 텍스트
      ..._quizIconLayers(figma),
      FigmaLabel(
        figma: figma,
        left: 305.9,
        top: 2166,
        text: canStartLearning ? '학습 시작' : '에너지 부족',
        fontSize: 34,
      ),
      FigmaBox(
        figma: figma,
        left: 973.9,
        top: 2165,
        width: 24.046,
        height: 39.297,
        child: const FigmaSvg(FigmaAssets.chevronLearning, fit: BoxFit.fill),
      ),
      FigmaTapArea(
        figma: figma,
        left: 158.9,
        top: 2114,
        width: 876,
        height: 141,
        onTap: onStartLearning,
        child: const SizedBox.shrink(),
      ),

      // 83:133 북마크
      FigmaTapArea(
        figma: figma,
        left: 993.19,
        top: 1888.25,
        width: 42,
        height: 51.241,
        onTap: onBookmark,
        child: const FigmaSvg(FigmaAssets.bookmark, fit: BoxFit.fill),
      ),
  ];
}

List<Widget> _speechBubbleLayers(FigmaScale figma) {
  return [
    _bubbleLayer(figma, 564, 596, 835.8, 677.31, 821, 739, const Color(0xFF9EB6CE)),
    _bubbleLayer(figma, 548, 580, 819.8, 661.31, 805, 723, const Color(0xFFC3D5E8)),
    _bubbleLayer(
      figma,
      559,
      590,
      830.8,
      671.31,
      816,
      733,
      const Color(0xFFF5FAFF),
      text: '작은 습관이 큰 자산이 돼요 !',
    ),
  ];
}

Widget _bubbleLayer(
  FigmaScale figma,
  double left,
  double top,
  double tailLeft,
  double tailTop,
  double dotLeft,
  double dotTop,
  Color color, {
  String? text,
}) {
  final s = figma.s;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      FigmaBox(
        figma: figma,
        left: left,
        top: top,
        width: 435.081,
        height: 111.085,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(s(55.542)),
          ),
          child: text == null
              ? null
              : Padding(
                  padding: EdgeInsets.fromLTRB(s(49), s(39), s(16), 0),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: s(27),
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                ),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: tailLeft,
        top: tailTop,
        width: 58.628,
        height: 58.628,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(s(55.542)),
          ),
        ),
      ),
      FigmaBox(
        figma: figma,
        left: dotLeft,
        top: dotTop,
        width: 30.857,
        height: 30.857,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(s(55.542)),
          ),
        ),
      ),
    ],
  );
}

List<Widget> _quizIconLayers(FigmaScale figma) {
  final s = figma.s;
  return [
    FigmaBox(
      figma: figma,
      left: 184.9,
      top: 2138,
      width: 93.411,
      height: 93.411,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1B9CA1),
          borderRadius: BorderRadius.circular(s(25.848)),
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 198.44,
      top: 2158.31,
      width: 35.198,
      height: 52.797,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(s(25.848)),
        ),
      ),
    ),
    FigmaBox(
      figma: figma,
      left: 205.21,
      top: 2167.78,
      width: 21.66,
      height: 35.198,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1B9CA1),
          borderRadius: BorderRadius.circular(s(16.569)),
        ),
      ),
    ),
  ];
}

class _FigmaMenuButton extends StatelessWidget {
  const _FigmaMenuButton({required this.figma, required this.onTap});

  final FigmaScale figma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return FigmaTapArea(
      figma: figma,
      left: 110.8,
      top: 100,
      width: 94,
      height: 92,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: s(51.8),
            child: _square(s, const Color(0xFFFFCA55)),
          ),
          Positioned(
            left: s(51.8),
            top: s(49.71),
            child: _square(s, const Color(0xFFFFCA55)),
          ),
          Positioned(
            left: s(2.09),
            top: s(49.71),
            child: _square(s, const Color(0xFFFFCA55)),
          ),
          Positioned(
            top: s(3.15),
            child: FigmaSvg(
              FigmaAssets.menuIcon,
              width: s(45.397),
              height: s(39.861),
            ),
          ),
        ],
      ),
    );
  }

  Widget _square(double Function(double) s, Color color) {
    return Container(
      width: s(42.604),
      height: s(42.604),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(s(9.026)),
      ),
    );
  }
}
