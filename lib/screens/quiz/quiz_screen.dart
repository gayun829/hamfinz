import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/quiz_data.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_session.dart';
import '../../models/user_profile.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_quiz_tokens.dart';
import '../../utils/quiz_text_helper.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/quiz_widgets.dart';
import 'quiz_complete_screen.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.profile,
    this.session,
    this.isReview = false,
  });

  final UserProfile profile;
  final QuizSession? session;
  final bool isReview;

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
      final session = widget.isReview
          ? await QuizService.instance.startReviewSession(
              profile: widget.profile,
            )
          : await QuizService.instance.startSession(profile: widget.profile);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final mapped = e is QuizSessionException ? e : mapQuizSubmitError(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    }
  }

  void _showExplanationDialog(QuizQuestionLearning question) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('풀이', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          question.explanation,
          style: const TextStyle(color: AppTheme.textPrimary, height: 1.5),
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
            builder: (context) => QuizCompleteScreen(
              onContinue: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      QuizResultScreen(result: result, profile: widget.profile),
                ),
              ),
            ),
          ),
        );
      } on QuizSessionException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

  Widget _buildQuizFooterContent({
    required FigmaScale figma,
    required QuizQuestionLearning question,
    required bool isLast,
    bool compact = false,
  }) {
    final s = figma.s;
    final hPad = s(FigmaQuizTokens.horizontalPadding).clamp(16.0, 28.0);
    final topPad = compact ? 8.0 : 12.0;
    final bottomPad = compact ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
      child: _showResult
          ? Row(
              children: [
                Expanded(
                  child: QuizFooterOutlinedButton(
                    label: '풀이확인',
                    onPressed: () => _showExplanationDialog(question),
                  ),
                ),
                SizedBox(
                  width: s(FigmaQuizTokens.dualButtonGap).clamp(8.0, 16.0),
                ),
                Expanded(
                  child: QuizFooterPrimaryButton(
                    label: isLast ? '결과 보기' : '다음문제',
                    onPressed: _next,
                  ),
                ),
              ],
            )
          : _buildSubmitButton(compact: compact),
    );
  }

  Widget _buildSubmitButton({required bool compact}) {
    final canSubmit = _selectedIndex != null && !_submitting && !_showResult;

    return SizedBox(
      width: double.infinity,
      height: compact ? 48 : 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: FigmaQuizTokens.footerButtonTop,
          foregroundColor: Colors.white,
          disabledBackgroundColor: FigmaQuizTokens.footerButtonTop.withValues(
            alpha: 0.45,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: canSubmit ? _confirmAnswer : null,
        child: Text(
          _submitting ? '제출 중…' : '정답 제출',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }

  double _quizFooterReserveHeight({required bool compact}) => compact ? 72 : 80;

  Widget _buildQuizShell({
    required Widget content,
    required FigmaScale figma,
    required QuizQuestionLearning question,
    required bool isLast,
    required bool compact,
  }) {
    final footerReserve = _quizFooterReserveHeight(compact: compact);

    return Scaffold(
      backgroundColor: FigmaQuizTokens.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: footerReserve),
              child: content,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildQuizFooterBar(
                figma: figma,
                question: question,
                isLast: isLast,
                compact: compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizFooterBar({
    required FigmaScale figma,
    required QuizQuestionLearning question,
    required bool isLast,
    bool compact = false,
  }) {
    return Material(
      color: FigmaQuizTokens.footerMint.withValues(alpha: 0.73),
      child: SafeArea(
        top: false,
        child: _buildQuizFooterContent(
          figma: figma,
          question: question,
          isLast: isLast,
          compact: compact,
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
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final compact = viewportHeight < 720;

    return _buildQuizShell(
      figma: figma,
      question: question,
      isLast: isLast,
      compact: compact,
      content: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: s(FigmaQuizTokens.horizontalPadding),
        ),
        child: Column(
          children: [
            QuizProgressHeader(
              progress: progress,
              onBack: () => Navigator.of(context).pop(),
            ),
            if (compact)
              SizedBox(
                height: 96,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  child: const QuizMc1Hero(),
                ),
              )
            else
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
            const SizedBox(height: 16),
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
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final compact = viewportHeight < 720;

    return _buildQuizShell(
      figma: figma,
      question: question,
      isLast: isLast,
      compact: compact,
      content: Column(
        children: [
          QuizProgressHeader(
            progress: progress,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: s(
                  useVerticalOx ? FigmaQuizTokens.horizontalPadding : 18,
                ),
              ),
              child: useVerticalOx
                  ? _buildOxVerticalBody(
                      figma: figma,
                      question: question,
                      correctIndex: correctIndex ?? 0,
                    )
                  : QuizOxHorizontalLayout(
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
    );
  }

  Widget _buildOxVerticalBody({
    required FigmaScale figma,
    required QuizQuestionLearning question,
    required int? correctIndex,
  }) {
    final s = figma.s;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final heroH = _orderedClamp(maxH * 0.34, 96.0, s(260.0));
        final questionH = _orderedClamp(maxH * 0.18, 72.0, s(180.0));
        final optionsH = _orderedClamp(maxH - heroH - questionH, 120.0, maxH);

        return Column(
          children: [
            SizedBox(
              height: heroH,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: const QuizMc1Hero(),
                ),
              ),
            ),
            SizedBox(
              height: questionH,
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
            SizedBox(
              height: optionsH,
              child: Column(
                children: [
                  for (var i = 0; i < question.options.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: i < question.options.length - 1
                              ? s(FigmaQuizTokens.optionGap)
                              : 0,
                        ),
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
      },
    );
  }

  static double _orderedClamp(double value, double a, double b) {
    final lo = math.min(a, b);
    final hi = math.max(a, b);
    return value.clamp(lo, hi);
  }
}
