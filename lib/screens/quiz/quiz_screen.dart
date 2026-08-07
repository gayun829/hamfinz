import 'package:flutter/material.dart';

import '../../data/quiz_data.dart';
import '../../models/quiz_question.dart';
import '../../models/user_profile.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_quiz_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/quiz_widgets.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizQuestion> _questions;
  final List<QuizAnswer> _answers = [];
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _questions = QuizService.instance.getTodayQuestions();
  }

  QuizQuestion get _currentQuestion => _questions[_currentIndex];

  void _selectAnswer(int index) {
    if (_showResult) return;
    setState(() => _selectedIndex = index);
  }

  void _confirmAnswer() {
    if (_selectedIndex == null || _showResult) return;
    setState(() => _showResult = true);
  }

  void _showExplanationDialog(QuizQuestion question) {
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
    if (selected == null) return;

    _answers.add(
      QuizAnswer(
        questionId: _currentQuestion.id,
        selectedIndex: selected,
        isCorrect: _currentQuestion.isCorrect(selected),
      ),
    );

    if (_currentIndex >= _questions.length - 1) {
      final result = await QuizService.instance.completeSession(
        profile: widget.profile,
        answers: _answers,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(result: result, profile: widget.profile),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex += 1;
      _selectedIndex = null;
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;
    final isCorrect =
        _selectedIndex != null && question.isCorrect(_selectedIndex!);

    if (question.type == QuizType.multipleChoice) {
      return _buildMcQuizScreen(question, isCorrect);
    }

    return _buildOxQuizScreen(question, isCorrect);
  }

  Widget _buildQuizFooter({
    required FigmaScale figma,
    required QuizQuestion question,
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
                label: '정답 제출',
                enabled: _selectedIndex != null,
                onPressed: _confirmAnswer,
              ),
      ),
    );
  }

  Widget _buildMcQuizScreen(QuizQuestion question, bool isCorrect) {
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
                          isCorrectOption: question.correctIndex == index,
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

  Widget _buildOxQuizScreen(QuizQuestion question, bool isCorrect) {
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
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(horizontal: s(18)),
                            child: QuizOxHorizontalLayout(
                              question: question.question,
                              options: question.options,
                              selectedIndex: _selectedIndex,
                              correctIndex: question.correctIndex,
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
    required QuizQuestion question,
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
                      isCorrectOption: question.correctIndex == i,
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
