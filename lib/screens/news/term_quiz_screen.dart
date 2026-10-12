import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/figma_assets.dart';
import '../../data/finance_terms.dart';
import '../../services/news_quiz_repository.dart';
import '../../theme/app_theme.dart';
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
/// | 정오답 | 정답은 하늘색, 내가 틀리게 고른 건 빨강 | 해설 보기 |
/// | 해설 | 정답 하나만 노랑으로 남기고 아래에 해설 상자 | 나가기 |
///
/// 홈 퀴즈([QuizScreen])와 **일부러 안 엮었다.** 그쪽은 에너지를 쓰고 채점을
/// 서버가 한다. 뉴스에서 들어오는 이 퀴즈는 기사를 읽다 곁다리로 보는
/// 거라 그 자리에서 채점하고, 맞히면 에너지를 조금 준다([NewsQuizRepository]).
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

/// Figma `뉴스_퀴즈창` 바탕. 순백이 아니라 아주 옅은 회색이다.
const _quizBg = Color(0xFFFAFAFA);

/// 보기·상자 공통 모서리.
const _radius = 12.0;

enum _Stage { learn, question, graded, explain }

class _TermQuizScreenState extends State<TermQuizScreen> {
  _Stage _stage = _Stage.learn;

  /// 고른 보기. null이면 아직 안 골랐다.
  int? _picked;

  /// 이번에 실제로 받은 에너지. 이미 받은 용어를 다시 풀면 0.
  int _earned = 0;

  TermQuiz get _quiz => widget.term.quiz!;

  /// 보기를 그리는 순서. 데이터의 정답 위치가 0·1번에 몰려 있어서 찍어도 맞힌다.
  late final List<int> _order = List.generate(_quiz.options.length, (i) => i)
    ..shuffle();
  bool get _isCorrect => _picked == _quiz.answer;

  /// 이미 에너지를 받은 용어면 배지를 빼서 "또 주나?" 하는 오해를 막는다.
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
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                // Figma 뉴스_정오답: 내용 덩어리는 좌우 41씩 들여서 가운데에 둔다.
                padding: const EdgeInsets.fromLTRB(41, 8, 41, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 뒤로 가기만 내용보다 바깥(화면 왼쪽 24)에 붙는다.
                    Transform.translate(
                      offset: const Offset(-17, 0),
                      child: _BackChevron(onTap: _exit),
                    ),
                    const SizedBox(height: 70),
                    _StageSwitcher(
                      child: _stage == _Stage.learn
                          ? _LearnHeader(
                              key: const ValueKey('learn'),
                              term: widget.term.term,
                              reward: NewsQuizRepository.energyPerCorrect,
                              showReward: _showReward,
                            )
                          : Column(
                              key: const ValueKey('question'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _QuestionHeader(
                                  reward: NewsQuizRepository.energyPerCorrect,
                                  showReward: _showReward,
                                  // 해설 장면에서는 Q도 정답 보기와 같은 노랑이 된다.
                                  color: _stage == _Stage.explain
                                      ? _OptionStyle.answer.border
                                      : _OptionStyle.accent,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _quiz.question,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    height: 1.45,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 56),
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
                                _ => Column(
                                  key: const ValueKey('options'),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // 배너가 끼어들 때 보기가 툭 밀리지 않고 미끄러지게.
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOut,
                                      child: _stage == _Stage.graded
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: _Verdict(
                                                correct: _isCorrect,
                                                earned: _earned,
                                              ),
                                            )
                                          : const SizedBox(
                                              width: double.infinity,
                                            ),
                                    ),
                                    _buildOptions(),
                                  ],
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
          _LearnBox(
            label: '나한테는?',
            body: term.forMe,
            accent: _OptionStyle.answer.border,
          ),
        ],
      ],
    );
  }

  Widget _buildOptions() {
    final options = _quiz.options;
    return Column(
      children: [
        for (final i in _order) ...[
          if (i != _order.first) const SizedBox(height: 14),
          _OptionBox(
            label: options[i],
            style: _styleFor(i),
            mark: _markFor(i),
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

  /// 정오답 장면에서 보기 오른쪽에 붙는 ✓/✗. 색만으로는 고른 보기와 정답이 헷갈린다.
  IconData? _markFor(int index) {
    if (_stage != _Stage.graded) return null;
    if (index == _quiz.answer) return Icons.check_circle;
    if (index == _picked) return Icons.cancel;
    return null;
  }

  /// 해설 — 정답 보기 하나만 노랗게 남기고 그 아래에 해설 상자.
  Widget _buildExplain() {
    final term = widget.term;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OptionBox(
          label: _quiz.options[_quiz.answer],
          style: _OptionStyle.answer,
          onTap: null,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          // Figma 해설 상자는 내용이 짧아도 높이를 유지한다.
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _OptionStyle.idle.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isCorrect ? '정답이에요!' : '아쉬워요, 정답은 위와 같아요.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _isCorrect
                      ? AppTheme.figmaTeal
                      : _OptionStyle.wrong.border,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _quiz.why,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: Colors.black,
                ),
              ),
              if (term.summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '「${term.term}」 ${term.summary}',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (_earned > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '⚡ 에너지 +$_earned',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.figmaTeal,
                  ),
                ),
              ],
            ],
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

/// Figma 좌상단 `<`. 얇고 연한 회색이라 기본 AppBar 화살표 대신 직접 그린다.
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
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFFB0B0B0),
          ),
        ),
      ),
    );
  }
}

/// 학습 단계 머리 — 용어 이름과 에너지 배지. `Q` 자리에 용어가 온다.
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
              _EnergyBadge(reward: reward),
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
        border: Border.all(color: _OptionStyle.idle.border),
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

/// `Q` 마크 + 에너지 배지.
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
    return Row(
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
          child: const Text('Q'),
        ),
        if (showReward) ...[
          const SizedBox(width: 8),
          _EnergyBadge(reward: reward),
        ],
      ],
    );
  }
}

class _EnergyBadge extends StatelessWidget {
  const _EnergyBadge({required this.reward});

  final int reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(
        color: AppTheme.figmaMintCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: FigmaSvg(FigmaAssets.statEnergy),
          ),
          const SizedBox(width: 3),
          Text(
            '+$reward',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 정오답 판정 배너. 채점 직후 튀어나와서 맞았는지 틀렸는지 바로 보이게 한다.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.correct, required this.earned});

  final bool correct;

  /// 받은 에너지. 서버 응답 전이거나 이미 받은 용어면 0.
  final int earned;

  @override
  Widget build(BuildContext context) {
    final style = correct ? _OptionStyle.correct : _OptionStyle.wrong;
    final color = correct ? AppTheme.figmaTeal : _OptionStyle.wrong.border;
    return TweenAnimationBuilder<double>(
      // 정답만 통통 튄다. 오답까지 튀면 축하하는 것처럼 보인다.
      tween: Tween(begin: correct ? 0.6 : 0.95, end: 1),
      duration: Duration(milliseconds: correct ? 380 : 200),
      curve: correct ? Curves.elasticOut : Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: style.border, width: 1.6),
        ),
        child: Row(
          children: [
            Icon(
              correct ? Icons.check_circle : Icons.cancel,
              color: color,
              size: correct ? 30 : 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                correct ? '정답이에요!' : '아쉬워요, 틀렸어요',
                // 정답은 크게 축하하고, 오답은 작고 담담하게 — 크게 띄우면 혼나는 느낌이 든다.
                style: TextStyle(
                  fontSize: correct ? 18 : 15,
                  fontWeight: correct ? FontWeight.w800 : FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            if (earned > 0)
              Text(
                '⚡ +$earned',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.figmaTeal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 보기 상자의 색 조합. Figma 네 장면에서 쓰인 다섯 가지.
enum _OptionStyle {
  idle(Colors.white, Color(0xFFDADADA)),
  picked(Colors.white, accent),
  correct(Color(0xFFD6F4FF), Color(0xFF7DD3F7)),
  wrong(Color(0xFFF8C9C9), Color(0xFFE5484D)),
  answer(Color(0xFFFFF5C2), Color(0xFFF3D66B));

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
    this.mark,
  });

  final String label;
  final _OptionStyle style;
  final VoidCallback? onTap;

  /// 오른쪽 끝 ✓/✗ 아이콘. 색은 [style] 테두리를 따른다.
  final IconData? mark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: style.border,
            width: style == _OptionStyle.idle ? 1 : 1.6,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              // 아이콘과 글자가 겹치지 않게 양쪽을 같이 비워 가운데 정렬을 지킨다.
              padding: EdgeInsets.symmetric(horizontal: mark == null ? 0 : 26),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            if (mark != null)
              Positioned(
                right: 0,
                child: Icon(mark, size: 22, color: style.border),
              ),
          ],
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
      height: 49,
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
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(label),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
