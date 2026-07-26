import 'package:flutter/material.dart';

import '../../models/quiz_question.dart';
import '../../models/user_profile.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/figma/figma_canvas.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/figma/quiz_figma_layout.dart';
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

  void _onPrimaryAction() {
    _confirmAnswer();
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;
    final isCorrect =
        _selectedIndex != null && question.isCorrect(_selectedIndex!);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: FigmaCanvas(
            designWidth: FigmaScale.quizDesignWidth,
            designHeight: FigmaScale.quizContentHeight,
            scrollable: false,
            fitToViewport: true,
            builder: (context, figma) => buildQuizFigmaLayers(
              figma: figma,
              question: question,
              currentIndex: _currentIndex,
              totalQuestions: _questions.length,
              selectedIndex: _selectedIndex,
              showResult: _showResult,
              isCorrect: isCorrect,
              onBack: () => Navigator.of(context).pop(),
              onSelectOption: _selectAnswer,
              onPrimaryAction: _onPrimaryAction,
              onNextQuestion: _next,
              onShowExplanation: () => _showExplanationDialog(question),
            ),
          ),
        ),
      ),
    );
  }
}
