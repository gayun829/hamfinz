import 'package:flutter/material.dart';

import '../../data/learning_stages.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_session.dart';
import '../../models/user_profile.dart';
import '../../services/quiz_service.dart';
import '../../theme/figma_quiz_question_tokens.dart';
import '../../utils/quiz_text_helper.dart';
import '../../widgets/figma/figma_quiz_ox_view.dart';
import '../../widgets/figma/figma_quiz_question_view.dart';
import 'quiz_complete_screen.dart';
import 'quiz_reward_screen.dart';
import 'quiz_streak_screen.dart';

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
  bool _showExplanation = false;
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
                  builder: (context) => QuizStreakScreen(
                    streak: result.newStreak,
                    onContinue: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => QuizRewardScreen(
                          correctCount: result.answers
                              .where((a) => a.isCorrect)
                              .length,
                          totalCount: result.answers.length,
                          seedsEarned: result.seedsEarned,
                          energyEarned: result.energyEarned,
                          onClaim: () {
                            // 결과창을 걷어냈으니 학습과정 진급 안내는
                            // 홈으로 돌아가면서 스낵바로 남긴다.
                            _notifyStageAdvance(
                              context,
                              result.advancedLearningStage,
                            );
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ),
                    ),
                  ),
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
      _showExplanation = false;
      _submitResult = null;
    });
  }

  void _notifyStageAdvance(BuildContext context, int? advancedStage) {
    if (advancedStage == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎓 ${learningStageLabel(advancedStage)}로 넘어갔어요!'),
      ),
    );
  }

  /// 4지선다 Figma 화면은 버튼 하나로 제출 → 다음 문제를 처리한다.
  Future<void> _onNextPressed() async {
    if (_selectedIndex == null || _submitting) return;
    if (!_showResult) {
      await _confirmAnswer();
      return;
    }
    await _next();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: FigmaQuizQuestionTokens.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: FigmaQuizQuestionTokens.background,
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
    final correctIndex = _showResult ? _submitResult?.correctIndex : null;

    if (question.type == QuizType.multipleChoice) {
      return _buildMcQuizScreen(question, correctIndex);
    }

    return _buildOxQuizScreen(question, correctIndex);
  }

  /// Figma `137:5521` 문제 / `137:5589` 정답 / `291:931` 해설 — 4지선다 전용.
  Widget _buildMcQuizScreen(QuizQuestionLearning question, int? correctIndex) {
    return FigmaQuizQuestionView(
      questionNumber: _currentIndex + 1,
      totalQuestions: _questions.length,
      question: question.question,
      options: question.options,
      selectedIndex: _selectedIndex,
      submitting: _submitting,
      locked: _showResult,
      showAnswer: _showResult,
      showExplanation: _showExplanation,
      correctIndex: correctIndex,
      explanation: question.explanation,
      onBack: () => Navigator.of(context).pop(),
      onSelect: _selectAnswer,
      onNext: _onNextPressed,
      onQuestionTap: _showResult
          ? () => setState(() => _showExplanation = false)
          : null,
      onExplanationTap: _showResult
          ? () => setState(() => _showExplanation = true)
          : null,
    );
  }

  /// Figma `137:5890` 문제 / `137:5957` 정답 / `291:971` 해설 — OX 전용.
  Widget _buildOxQuizScreen(QuizQuestionLearning question, int? correctIndex) {
    return FigmaQuizOxView(
      questionNumber: _currentIndex + 1,
      totalQuestions: _questions.length,
      question: question.question,
      options: question.options,
      selectedIndex: _selectedIndex,
      submitting: _submitting,
      locked: _showResult,
      showAnswer: _showResult,
      showExplanation: _showExplanation,
      correctIndex: correctIndex,
      explanation: question.explanation,
      onBack: () => Navigator.of(context).pop(),
      onSelect: _selectAnswer,
      onNext: _onNextPressed,
      onQuestionTap: _showResult
          ? () => setState(() => _showExplanation = false)
          : null,
      onExplanationTap: _showResult
          ? () => setState(() => _showExplanation = true)
          : null,
    );
  }
}
