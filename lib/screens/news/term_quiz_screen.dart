import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/figma_assets.dart';
import '../../data/finance_terms.dart';
import '../../services/news_quiz_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_quiz_fonts.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/home_bottom_nav.dart';

/// 기사에서 잡은 금융 용어 하나를 가르치고 3지선다 한 문제로 묻는다.
///
/// Figma `뉴스_퀴즈창 → 뉴스_정오답 → 뉴스_해설` 세 장면 **앞에 학습 단계**를 둔다.
/// 무슨 용어인지 모른 채 문제부터 받으면 찍고 넘기게 된다. 뜻을 먼저 보여 주고
/// 나서 물어야 해설이 남는다.
///
/// | 단계 | 보기 | 버튼 |
/// |---|---|---|
/// | 학습 | 용어 뜻 + 「나한테는?」 | 퀴즈 풀기 |
/// | 문제 | 고른 보기만 하늘색 테두리 | 정답 보기 |
/// | 정오답(`1006:2846`) | 정답은 하늘색, 내가 틀리게 고른 건 빨강 | 해설 보기 |
/// | 해설(`1006:2792`) | 정답 하나만 노랑으로 남기고 아래에 해설 상자 | 나가기 |
///
/// 정오답·해설은 시안 그대로다. 판정 문구나 ✓/✗ 없이 보기 색만으로 맞고 틀림을 보인다.
///
/// 홈 퀴즈([QuizScreen])와 **일부러 안 엮었다.** 그쪽은 에너지를 쓰고 채점을
/// 서버가 한다. 뉴스에서 들어오는 이 퀴즈는 기사를 읽다 곁다리로 보는
/// 거라 그 자리에서 채점하고, 맞히면 씨앗을 조금 준다([NewsQuizRepository]).
class TermQuizScreen extends StatefulWidget {
  const TermQuizScreen({super.key, required this.term, required this.headline});

  final FinanceTerm term;

  /// 어떤 기사에서 왔는지. 지금 화면에는 안 그리지만 다음 단계(기사 기반 문제)를
  /// 위해 받아 둔다.
  final String headline;

  /// 문제가 있는 용어일 때만 띄운다.
  static Future<void> open(
    BuildContext context,
    FinanceTerm term,
    String headline,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TermQuizScreen(term: term, headline: headline),
      ),
    );
  }

  @override
  State<TermQuizScreen> createState() => _TermQuizScreenState();
}

/// Figma `뉴스_퀴즈창`(`137:6383`) 바탕. 순백이 아니라 아주 옅은 회색이다.
const _quizBg = Color(0xFFFBFBFB);

/// 보기·상자·버튼 공통 모서리.
const _radius = 13.0;

/// 보기·상자 공통 테두리 두께.
const _borderWidth = 1.95;

/// `뉴스_해설`의 Q. 정답 보기 테두리보다 진한 노랑이다.
const _explainAccent = Color(0xFFFFCB5A);

enum _Stage { learn, question, graded, explain }

class _TermQuizScreenState extends State<TermQuizScreen> {
  _Stage _stage = _Stage.learn;

  /// 고른 보기. null이면 아직 안 골랐다.
  int? _picked;

  /// 이번에 실제로 받은 씨앗. 이미 받은 용어를 다시 풀면 0.
  int _earned = 0;

  TermQuiz get _quiz => widget.term.quiz!;

  /// 보기를 그리는 순서. 데이터의 정답 위치가 0·1번에 몰려 있어서 찍어도 맞힌다.
  late final List<int> _order = List.generate(_quiz.options.length, (i) => i)
    ..shuffle();
  bool get _isCorrect => _picked == _quiz.answer;

  /// 이미 씨앗을 받은 용어면 배지를 빼서 "또 주나?" 하는 오해를 막는다.
  bool get _showReward =>
      _earned > 0 || !NewsQuizRepository.instance.isRewarded(widget.term.term);

  void _startQuiz() => setState(() => _stage = _Stage.question);

  void _pick(int index) {
    if (_stage != _Stage.question) return;
    setState(() => _picked = index);
  }

  Future<void> _reveal() async {
    if (_picked == null) return;
    setState(() => _stage = _Stage.graded);
    if (!_isCorrect) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.lightImpact();
    final earned = await NewsQuizRepository.instance.rewardCorrect(
      widget.term.term,
    );
    if (!mounted) return;
    setState(() => _earned = earned);
  }

  void _explain() => setState(() => _stage = _Stage.explain);

  void _exit() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _quizBg,
      body: DefaultTextStyle.merge(
        style: const TextStyle(height: AppTheme.figmaAutoLineHeight),
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  // Figma: 보기·버튼은 x=41, 폭 310이라 오른쪽이 42 남는다.
                  // 위 8은 393×852 기기(상단 안전 영역 59)에서 `<`가 y=75에 오게 한다.
                  padding: const EdgeInsets.fromLTRB(41, 8, 42, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 뒤로 가기만 내용보다 바깥(화면 왼쪽 26)에 붙는다.
                      Transform.translate(
                        offset: const Offset(-23, 0),
                        child: _BackChevron(onTap: _exit),
                      ),
                      const SizedBox(height: 55),
                      _StageSwitcher(
                        child: _stage == _Stage.learn
                            ? _LearnHeader(
                                key: const ValueKey('learn'),
                                term: widget.term.term,
                                reward: NewsQuizRepository.seedsPerCorrect,
                                showReward: _showReward,
                              )
                            : Column(
                                key: const ValueKey('question'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _QuestionHeader(
                                    reward: NewsQuizRepository.seedsPerCorrect,
                                    showReward: _showReward,
                                    // 해설 장면에서는 Q도 정답 보기와 같은 노랑이 된다.
                                    color: _stage == _Stage.explain
                                        ? _explainAccent
                                        : _OptionStyle.accent,
                                  ),
                                  const SizedBox(height: 15),
                                  // 문제가 한 줄이어도 보기 시작 위치(323)는 그대로다.
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 107,
                                    ),
                                    child: Padding(
                                      // Figma 문제 글상자: x=56, 폭 268.
                                      padding: const EdgeInsets.only(
                                        left: 15,
                                        right: 27,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        _quiz.question,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      // 학습 단계는 시안에 없어서 문제 영역 높이가 없다.
                      SizedBox(height: _stage == _Stage.learn ? 56 : 0),
                      // Figma대로 버튼은 바닥에 붙이지 않고 보기 바로 아래에 둔다.
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StageSwitcher(
                                child: switch (_stage) {
                                  _Stage.learn => KeyedSubtree(
                                    key: const ValueKey('learn'),
                                    child: _buildLearn(),
                                  ),
                                  _Stage.explain => KeyedSubtree(
                                    key: const ValueKey('explain'),
                                    child: _buildExplain(),
                                  ),
                                  _ => KeyedSubtree(
                                    key: const ValueKey('options'),
                                    child: _buildOptions(),
                                  ),
                                },
                              ),
                              const SizedBox(height: 40),
                              _buildButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 퀴즈도 탭 안의 한 장면처럼 보이게 하단 탭을 그대로 둔다.
            // 누르면 뉴스 탭으로 돌아간다 — 탭 전환은 MainShell 몫이라 여기서 안 한다.
            HomeBottomNav(currentIndex: 0, onTap: (_) => _exit()),
          ],
        ),
      ),
    );
  }

  /// 학습 — 용어 뜻과 「나한테는?」. 문제는 아직 안 보여준다.
  Widget _buildLearn() {
    final term = widget.term;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LearnBox(
          label: '이런 뜻이에요',
          body: term.summary,
          accent: _OptionStyle.accent,
        ),
        if (term.forMe.isNotEmpty) ...[
          const SizedBox(height: 10),
          _LearnBox(label: '나한테는?', body: term.forMe, accent: _explainAccent),
        ],
      ],
    );
  }

  Widget _buildOptions() {
    final options = _quiz.options;
    return Column(
      children: [
        for (final i in _order) ...[
          if (i != _order.first) const SizedBox(height: 12),
          _OptionBox(
            label: options[i],
            style: _styleFor(i),
            onTap: _stage == _Stage.question ? () => _pick(i) : null,
          ),
        ],
      ],
    );
  }

  _OptionStyle _styleFor(int index) {
    final isAnswer = index == _quiz.answer;
    final isPicked = index == _picked;
    switch (_stage) {
      // 학습 단계에선 보기를 아예 안 그리지만 switch를 다 덮어 둔다.
      case _Stage.learn:
      case _Stage.question:
        return isPicked ? _OptionStyle.picked : _OptionStyle.idle;
      case _Stage.graded:
        if (isAnswer) return _OptionStyle.correct;
        if (isPicked) return _OptionStyle.wrong;
        return _OptionStyle.idle;
      case _Stage.explain:
        return _OptionStyle.answer;
    }
  }

  /// 해설 — 정답 보기 하나만 노랗게 남기고 그 아래에 해설 상자.
  Widget _buildExplain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OptionBox(
          label: _quiz.options[_quiz.answer],
          style: _OptionStyle.answer,
          onTap: null,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          // Figma 해설 상자는 내용이 짧아도 높이를 유지한다.
          constraints: const BoxConstraints(minHeight: 140),
          // Figma 해설 글상자: 상자에서 왼쪽 15, 위 16, 오른쪽 14 안쪽.
          // Container는 테두리 두께를 padding에 더하므로 그만큼 뺀다.
          padding: const EdgeInsets.fromLTRB(
            15 - _borderWidth,
            16 - _borderWidth,
            14 - _borderWidth,
            15 - _borderWidth,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: _OptionStyle.idle.border,
              width: _borderWidth,
            ),
          ),
          // Figma 해설 상자에는 해설 글(Regular 18)만 있다.
          child: Text(
            _quiz.why,
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    switch (_stage) {
      case _Stage.learn:
        return _PrimaryButton(label: '퀴즈 풀기', onPressed: _startQuiz);
      case _Stage.question:
        return _PrimaryButton(
          label: '정답 보기',
          onPressed: _picked == null ? null : _reveal,
        );
      case _Stage.graded:
        return _PrimaryButton(label: '해설 보기', onPressed: _explain);
      case _Stage.explain:
        return _PrimaryButton(label: '나가기', onPressed: _exit);
    }
  }
}

/// Figma 좌상단 `<`(10.6×21.1, `#D9D9D9` 획 3). 기본 AppBar 화살표 대신 직접 그린다.
class _BackChevron extends StatelessWidget {
  const _BackChevron({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CustomPaint(
            size: const Size(10.644, 21.069),
            painter: _BackChevronPainter(),
          ),
        ),
      ),
    );
  }
}

class _BackChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFD9D9D9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 학습 단계 머리 — 용어 이름과 씨앗 배지. `Q` 자리에 용어가 온다.
class _LearnHeader extends StatelessWidget {
  const _LearnHeader({
    super.key,
    required this.term,
    required this.reward,
    required this.showReward,
  });

  final String term;
  final int reward;
  final bool showReward;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '오늘의 용어',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _OptionStyle.accent,
              ),
            ),
            if (showReward) ...[
              const SizedBox(width: 8),
              _SeedBadge(reward: reward),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          term,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// 학습 단계의 설명 상자. 해설 상자와 같은 흰 상자에 색 라벨만 얹는다.
class _LearnBox extends StatelessWidget {
  const _LearnBox({
    required this.label,
    required this.body,
    required this.accent,
  });

  final String label;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: _OptionStyle.idle.border,
          width: _borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// `Q` 마크 + 씨앗 배지.
class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
    required this.reward,
    required this.showReward,
    this.color = _OptionStyle.accent,
  });

  final int reward;
  final bool showReward;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Figma: Q는 보기보다 13 안쪽(x=54), 배지는 Q 글상자(폭 37) 1 옆(x=92)에 붙는다.
      padding: const EdgeInsets.only(left: 13),
      child: Row(
        children: [
          // Figma Q는 SUIT Thin 글자에 바깥 외곽선 1.3(round join)을 두른 것이다.
          // 글자에 stroke를 덧그리면 렌더러마다 획 모양이 달라져서, Figma가 내보낸
          // 글자 윤곽에 같은 획을 입힌 벡터(`quiz_q.svg`)를 쓰고 색만 바꾼다.
          Semantics(
            label: 'Q',
            child: SizedBox(
              width: 37,
              height: 42,
              child: Stack(
                children: [
                  // 글상자(54, 159) 안에서 벡터가 놓이는 자리(55.33, 166.31).
                  Positioned(
                    left: 1.331,
                    top: 7.308,
                    width: 26,
                    height: 27,
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: color),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, value, _) => FigmaSvg(
                        FigmaAssets.newsQuizQ,
                        fit: BoxFit.fill,
                        colorFilter: ColorFilter.mode(
                          value ?? color,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showReward) ...[
            const SizedBox(width: 1),
            _SeedBadge(reward: reward),
          ],
        ],
      ),
    );
  }
}

/// Figma `Group 384`: 53×26.1 알약에 씨앗 아이콘과 `+N`. 안쪽도 시안 좌표 그대로 놓는다.
class _SeedBadge extends StatelessWidget {
  const _SeedBadge({required this.reward});

  final int reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 53.002,
      height: 26.117,
      decoration: BoxDecoration(
        color: const Color(0xFFD9FAFF),
        borderRadius: BorderRadius.circular(16.826),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // `Group 359`는 홈 씨앗 아이콘과 같은 벡터다(16.5×15.98).
          const Positioned(
            left: 8.6,
            top: 4.64,
            width: 16.5,
            height: 15.984,
            child: FigmaSvg(FigmaAssets.homeBeginnerStatCoin, fit: BoxFit.fill),
          ),
          Positioned(
            left: 27.78,
            top: 5.65,
            child: Text(
              '+$reward',
              style: const TextStyle(
                fontFamily: FigmaQuizFonts.inter,
                fontSize: 11.988,
                fontWeight: FontWeight.w600,
                // Inter 기본 줄 높이 (1984 + 494) / 2048.
                height: 1.21,
                color: Color(0xFF616161),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 보기 상자의 색 조합. Figma 네 장면에서 쓰인 다섯 가지.
enum _OptionStyle {
  idle(Colors.white, Color(0xFFD9D9D9)),
  picked(Colors.white, accent),
  correct(Color(0xFFD4F4FF), Color(0xFF70D9FF)),
  wrong(Color(0xFFFFC4C4), Color(0xFFFF3C3C)),
  answer(Color(0xFFFFF8D3), Color(0xFFF9E08D));

  const _OptionStyle(this.background, this.border);

  final Color background;
  final Color border;

  /// 홈 '오늘의 학습' CTA와 같은 하늘색. `Q` 마크·버튼·고른 보기 테두리에 쓴다.
  static const accent = Color(0xFF3CC6FF);
}

class _OptionBox extends StatelessWidget {
  const _OptionBox({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final _OptionStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 64),
        // Figma 보기 글상자: 상자 위에서 20 아래, 폭 291(양옆 9.5). 한 줄이면
        // 가운데보다 1px쯤 위에 놓이는 것도 시안 그대로다.
        // Container는 테두리 두께를 padding에 더하므로 그만큼 뺀다.
        padding: const EdgeInsets.fromLTRB(
          9.5 - _borderWidth,
          20 - _borderWidth,
          9.5 - _borderWidth,
          20 - _borderWidth,
        ),
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: style.border, width: _borderWidth),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _OptionStyle.accent,
          disabledBackgroundColor: _OptionStyle.accent.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(label),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// 단계가 바뀔 때 이전 장면은 사라지고 새 장면은 살짝 올라오며 나타난다.
/// 자식 key가 바뀔 때만 움직이므로, 같은 key 안의 변화(보기 색)는 그대로 둔다.
class _StageSwitcher extends StatelessWidget {
  const _StageSwitcher({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      // 기본은 가운데 정렬이라 왼쪽 정렬 장면이 흔들린다.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}
