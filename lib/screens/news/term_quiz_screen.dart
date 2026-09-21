import 'package:flutter/material.dart';

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
/// 거라 그 자리에서 채점하고, 맞히면 씨앗 +3만 준다([NewsQuizRepository]).
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

enum _Stage { learn, question, graded, explain }

class _TermQuizScreenState extends State<TermQuizScreen> {
  _Stage _stage = _Stage.learn;

  /// 고른 보기. null이면 아직 안 골랐다.
  int? _picked;

  /// 이번에 실제로 받은 씨앗. 이미 받은 용어를 다시 풀면 0.
  int _earned = 0;

  TermQuiz get _quiz => widget.term.quiz!;
  bool get _isCorrect => _picked == _quiz.answer;

  /// 이미 씨앗을 받은 용어면 배지를 빼서 "또 주나?" 하는 오해를 막는다.
  bool get _showReward =>
      _earned > 0 ||
      !NewsQuizRepository.instance.isRewarded(widget.term.term);

  void _startQuiz() => setState(() => _stage = _Stage.question);

  void _pick(int index) {
    if (_stage != _Stage.question) return;
    setState(() => _picked = index);
  }

  Future<void> _reveal() async {
    if (_picked == null) return;
    setState(() => _stage = _Stage.graded);
    if (!_isCorrect) return;
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BackChevron(onTap: _exit),
                    const SizedBox(height: 28),
                    if (_stage == _Stage.learn)
                      _LearnHeader(
                        term: widget.term.term,
                        reward: NewsQuizRepository.seedsPerCorrect,
                        showReward: _showReward,
                      )
                    else ...[
                      _QuestionHeader(
                        reward: NewsQuizRepository.seedsPerCorrect,
                        showReward: _showReward,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _quiz.question,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    // Figma대로 버튼은 바닥에 붙이지 않고 보기 바로 아래에 둔다.
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_stage == _Stage.learn)
                              _buildLearn()
                            else if (_stage == _Stage.explain)
                              _buildExplain()
                            else
                              _buildOptions(),
                            const SizedBox(height: 28),
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
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
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
                  color: _isCorrect ? AppTheme.figmaTeal : _OptionStyle.wrong.border,
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
                  '🌱 씨앗 +$_earned',
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
          child: Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFFB0B0B0)),
        ),
      ),
    );
  }
}

/// 학습 단계 머리 — 용어 이름과 씨앗 배지. `Q` 자리에 용어가 온다.
class _LearnHeader extends StatelessWidget {
  const _LearnHeader({
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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

/// `Q` 마크 + 씨앗 `+3` 배지.
class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.reward, required this.showReward});

  final int reward;
  final bool showReward;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Q',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _OptionStyle.accent,
            height: 1,
          ),
        ),
        if (showReward) ...[
          const SizedBox(width: 8),
          _SeedBadge(reward: reward),
        ],
      ],
    );
  }
}

class _SeedBadge extends StatelessWidget {
  const _SeedBadge({required this.reward});

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
            child: FigmaSvg(FigmaAssets.shopSeedPouch),
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
  });

  final String label;
  final _OptionStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: style.border,
            width: style == _OptionStyle.idle ? 1 : 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
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
      height: 46,
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
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
