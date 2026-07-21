import 'package:flutter/material.dart';

import '../../data/quiz_data.dart';
import '../../models/quiz_question.dart';
import '../../models/user_profile.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
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
    setState(() {
      _selectedIndex = index;
      _showResult = true;
    });
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
    final isCorrect = _selectedIndex != null && question.isCorrect(_selectedIndex!);

    return Scaffold(
      appBar: AppBar(
        title: Text('퀴즈 ${_currentIndex + 1}/${_questions.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  question.category.label,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                question.type == QuizType.ox ? 'OX 퀴즈' : '4지선다',
                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = question.options[index];
                    Color? background;
                    Color borderColor = const Color(0xFFE5E7EB);

                    if (_showResult && _selectedIndex == index) {
                      background = isCorrect
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2);
                      borderColor = isCorrect ? AppTheme.success : AppTheme.error;
                    } else if (_showResult && index == question.correctIndex) {
                      background = const Color(0xFFDCFCE7);
                      borderColor = AppTheme.success;
                    }

                    return Material(
                      color: background ?? Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _showResult ? null : () => _selectAnswer(index),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_showResult) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect ? '정답! +${QuizData.correctXp} XP' : '오답 +${QuizData.wrongXp} XP',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isCorrect ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.explanation,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _currentIndex >= _questions.length - 1 ? '결과 보기' : '다음 문제',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
