import 'package:flutter/material.dart';

import '../../data/finance_terms.dart';
import '../../data/interest_categories.dart';
import '../../theme/app_theme.dart';

/// 기사에서 잡은 금융 용어 하나를 가르치고 바로 묻는다.
///
/// 홈 퀴즈([QuizScreen])와 **일부러 안 엮었다.** 그쪽은 에너지를 쓰고 XP를 주고
/// 채점을 서버가 한다(`QuizSession`에 정답이 안 실려 온다). 뉴스에서 들어오는
/// 이 학습은 기사를 읽다 곁다리로 보는 거라, 에너지도 기록도 없이 그 자리에서
/// 채점하고 끝낸다. 진도로 세고 싶어지면 그때 `QuizService`에 붙이면 된다.
class TermQuizScreen extends StatefulWidget {
  const TermQuizScreen({super.key, required this.term, required this.headline});

  final FinanceTerm term;

  /// 어떤 기사에서 왔는지. 카드 맨 위에 한 줄로 붙는다.
  final String headline;

  /// 학습 내용이 있는 용어일 때만 띄운다.
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

class _TermQuizScreenState extends State<TermQuizScreen> {
  /// 0 = 용어 카드, 1..n = 문제, n+1 = 결과.
  int _step = 0;

  /// 지금 문제에 고른 답. null이면 아직 안 골랐다.
  bool? _picked;
  final List<bool> _correct = [];

  List<TermOx> get _quiz => widget.term.quiz;
  bool get _isResult => _step > _quiz.length;

  void _pick(bool answer) {
    if (_picked != null) return;
    setState(() {
      _picked = answer;
      _correct.add(answer == _quiz[_step - 1].answer);
    });
  }

  void _next() {
    setState(() {
      _step += 1;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.figmaHomeBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text(
          '용어 학습',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _step / (_quiz.length + 1),
            minHeight: 3,
            backgroundColor: AppTheme.figmaMintLight,
            color: AppTheme.figmaTeal,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: _isResult
              ? _buildResult()
              : _step == 0
              ? _buildCard()
              : _buildQuestion(),
        ),
      ),
    );
  }

  /// 용어 카드 — 용어 / 한 줄 정의 / 나한테는?
  Widget _buildCard() {
    final term = widget.term;
    final emoji = findInterestCategory(term.categoryId)?.emoji ?? '📰';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.figmaMintLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$emoji ${term.term}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    term.summary,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '나한테는?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.figmaTeal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    term.forMe,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(label: '문제 풀기 (${_quiz.length}문제)', onPressed: _next),
      ],
    );
  }

  Widget _buildQuestion() {
    final index = _step - 1;
    final question = _quiz[index];
    final picked = _picked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${index + 1} / ${_quiz.length}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.figmaTeal,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          question.statement,
          style: const TextStyle(
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _OxButton(
                label: 'O',
                value: true,
                picked: picked,
                answer: question.answer,
                onTap: () => _pick(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OxButton(
                label: 'X',
                value: false,
                picked: picked,
                answer: question.answer,
                onTap: () => _pick(false),
              ),
            ),
          ],
        ),
        if (picked != null) ...[
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.figmaMintCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      picked == question.answer ? '맞았어요' : '아쉬워요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: picked == question.answer
                            ? AppTheme.figmaTeal
                            : AppTheme.figmaOrange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question.why,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: index + 1 == _quiz.length ? '결과 보기' : '다음 문제',
            onPressed: _next,
          ),
        ] else
          const Spacer(),
      ],
    );
  }

  Widget _buildResult() {
    final score = _correct.where((ok) => ok).length;
    final perfect = score == _quiz.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          perfect ? '🎉' : '💪',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 56),
        ),
        const SizedBox(height: 12),
        Text(
          '${_quiz.length}문제 중 $score개',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          perfect ? '「${widget.term.term}」 확실히 알고 있네요.' : '해설을 한 번 더 읽어 보면 남아요.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const Spacer(),
        _PrimaryButton(
          label: '다시 풀기',
          onPressed: () => setState(() {
            _step = 1;
            _picked = null;
            _correct.clear();
          }),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _OxButton extends StatelessWidget {
  const _OxButton({
    required this.label,
    required this.value,
    required this.picked,
    required this.answer,
    required this.onTap,
  });

  final String label;
  final bool value;
  final bool? picked;
  final bool answer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 답을 고른 뒤에는 정답 쪽을 민트로, 잘못 고른 쪽을 주황으로 칠한다.
    final decided = picked != null;
    final isAnswer = value == answer;
    final isPicked = value == picked;

    Color background = AppTheme.card;
    Color border = AppTheme.figmaMintLight;
    Color text = AppTheme.textPrimary;
    if (decided && isAnswer) {
      background = AppTheme.figmaMintDeep;
      border = AppTheme.figmaMintDeep;
      text = Colors.white;
    } else if (decided && isPicked) {
      background = AppTheme.figmaOrange;
      border = AppTheme.figmaOrange;
      text = Colors.white;
    }

    return GestureDetector(
      onTap: decided ? null : onTap,
      child: Container(
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: text,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.figmaTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
