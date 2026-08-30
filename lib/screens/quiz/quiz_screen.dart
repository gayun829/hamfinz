import 'package:flutter/material.dart';

import '../../data/quiz_data.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_session.dart';
import '../../models/user_profile.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_quiz_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/quiz_widgets.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.profile, this.session});

  final UserProfile profile;
  final QuizSession? session;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizSession? _session;
  bool _loading = true;
  String? _loadError;
  final List<QuizAnswer> _answers = [];
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _showResult = false;
  SubmitAnswerResult? _submitResult;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _session = widget.session;
      _loading = false;
    } else {
      _loadSession();
    }
  }

  Future<void> _loadSession() async {
    try {
      final session =
          await QuizService.instance.startSession(profile: widget.profile);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
    } on QuizSessionException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = '문제를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
        _loading = false;
      });
    }
  }

  List<QuizQuestionLearning> get _questions => _session!.questions;

  QuizQuestionLearning get _currentQuestion => _questions[_currentIndex];

  void _selectAnswer(int index) {
    if (_showResult) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _confirmAnswer() async {
    if (_selectedIndex == null || _showResult || _submitting) return;

    setState(() => _submitting = true);
    try {
      final result = await QuizService.instance.submitAnswer(
        sessionId: _session!.sessionId,
        questionId: _currentQuestion.id,
        selectedIndex: _selectedIndex!,
        profile: widget.profile,
      );
      if (!mounted) return;
      setState(() {
        _submitResult = result;
        _showResult = true;
        _submitting = false;
      });
    } on QuizSessionException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답안 제출에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  void _showExplanationDialog(QuizQuestionLearning question) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '풀이',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          question.explanation,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _next() async {
    final selected = _selectedIndex;
    final submitResult = _submitResult;
    if (selected == null || submitResult == null) return;

    _answers.add(
      QuizAnswer(
        questionId: _currentQuestion.id,
        selectedIndex: selected,
        isCorrect: submitResult.isCorrect,
      ),
    );

    if (_currentIndex >= _questions.length - 1) {
      try {
        final result = await QuizService.instance.completeSession(
          profile: widget.profile,
          sessionId: _session!.sessionId,
        );
        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                QuizResultScreen(result: result, profile: widget.profile),
          ),
        );
      } on QuizSessionException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return;
    }

    setState(() {
      _currentIndex += 1;
      _selectedIndex = null;
      _showResult = false;
      _submitResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('학습')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('돌아가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _currentQuestion;
    final isCorrect = _submitResult?.isCorrect ?? false;
    final correctIndex = _showResult ? _submitResult?.correctIndex : null;

    if (question.type == QuizType.multipleChoice) {
      return _buildMcQuizScreen(question, isCorrect, correctIndex);
    }

    return _buildOxQuizScreen(question, isCorrect, correctIndex);
  }

  Widget _buildQuizFooter({
    required FigmaScale figma,
    required QuizQuestionLearning question,
    required bool isLast,
  }) {
    final s = figma.s;

    return ColoredBox(
      color: FigmaQuizTokens.footerMint.withValues(alpha: 0.73),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          s(FigmaQuizTokens.horizontalPadding),
          s(24),
          s(FigmaQuizTokens.horizontalPadding),
          s(32),
        ),
        child: _showResult
            ? Row(
                children: [
                  Expanded(
                    child: QuizFooterOutlinedButton(
                      label: '풀이확인',
                      onPressed: () => _showExplanationDialog(question),
                    ),
                  ),
                  SizedBox(width: s(FigmaQuizTokens.dualButtonGap)),
                  Expanded(
                    child: QuizFooterPrimaryButton(
                      label: isLast ? '결과 보기' : '다음문제',
                      onPressed: _next,
                    ),
                  ),
                ],
              )
            : QuizFooterPrimaryButton(
                label: _submitting ? '제출 중…' : '정답 제출',
                enabled: _selectedIndex != null && !_submitting,
                onPressed: _confirmAnswer,
              ),
      ),
    );
  }

  Widget _buildMcQuizScreen(
    QuizQuestionLearning question,
    bool isCorrect,
    int? correctIndex,
  ) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;
    final progress = (_currentIndex + 1) / _questions.length;
    final isLast = _currentIndex >= _questions.length - 1;

    return Scaffold(
      backgroundColor: FigmaQuizTokens.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: s(FigmaQuizTokens.horizontalPadding)),
                child: Column(
                  children: [
                    QuizProgressHeader(
                      progress: progress,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    const QuizMc1Hero(),
                    QuizCategoryBadge(label: question.category.label),
                    SizedBox(height: s(FigmaQuizTokens.questionTopGap)),
                    Text(
                      question.question,
                      textAlign: TextAlign.center,
                      style: FigmaQuizTokens.questionStyle(figma.scale),
                    ),
                    SizedBox(height: s(FigmaQuizTokens.questionTopGap)),
                    ...List.generate(question.options.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: s(FigmaQuizTokens.optionGap)),
                        child: QuizOptionButton(
                          label: question.options[index],
                          isSelected: _selectedIndex == index,
                          isCorrectOption: correctIndex == index,
                          showResult: _showResult,
                          onTap: _showResult ? null : () => _selectAnswer(index),
                        ),
                      );
                    }),
                    if (_showResult) ...[
                      SizedBox(height: s(FigmaQuizTokens.resultTopGap)),
                      QuizResultBanner(
                        isCorrect: isCorrect,
                        xpText: isCorrect
                            ? '정답! +${QuizData.correctXp} XP'
                            : '오답 +${QuizData.wrongXp} XP',
                      ),
                    ],
                    SizedBox(height: s(24)),
                  ],
                ),
              ),
            ),
            _buildQuizFooter(figma: figma, question: question, isLast: isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildOxQuizScreen(
    QuizQuestionLearning question,
    bool isCorrect,
    int? correctIndex,
  ) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaQuizTokens.designWidth,
    );
    final s = figma.s;
    final progress = (_currentIndex + 1) / _questions.length;
    final isLast = _currentIndex >= _questions.length - 1;
    final useVerticalOx = _currentIndex.isOdd;

    return Scaffold(
      backgroundColor: FigmaQuizTokens.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  QuizProgressHeader(
                    progress: progress,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: useVerticalOx
                        ? Padding(
                            padding: EdgeInsets.symmetric(horizontal: s(FigmaQuizTokens.horizontalPadding)),
                            child: _buildOxVerticalBody(
                              figma: figma,
                              question: question,
                              correctIndex: correctIndex ?? 0,
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(horizontal: s(18)),
                            child: QuizOxHorizontalLayout(
                              question: question.question,
                              options: question.options,
                              selectedIndex: _selectedIndex,
                              correctIndex: correctIndex ?? 0,
                              showResult: _showResult,
                              onSelect: _selectAnswer,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            _buildQuizFooter(figma: figma, question: question, isLast: isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildOxVerticalBody({
    required FigmaScale figma,
    required QuizQuestionLearning question,
    required int? correctIndex,
  }) {
    final s = figma.s;

    return Column(
      children: [
        const Flexible(flex: 3, child: QuizMc1Hero()),
        Flexible(
          flex: 2,
          child: Center(
            child: Text(
              question.question,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: FigmaQuizTokens.questionStyle(figma.scale).copyWith(
                fontSize: s(FigmaQuizTokens.questionFontSize * 0.9),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              for (var i = 0; i < question.options.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: s(FigmaQuizTokens.optionGap)),
                    child: QuizOxChoiceButton(
                      label: question.options[i],
                      isSelected: _selectedIndex == i,
                      isCorrectOption: correctIndex == i,
                      showResult: _showResult,
                      onTap: _showResult ? null : () => _selectAnswer(i),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
