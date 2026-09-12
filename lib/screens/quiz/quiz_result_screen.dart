import 'package:flutter/material.dart';

import '../../data/learning_stages.dart';
import '../../models/quiz_question.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/streak_badge.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.result,
    required this.profile,
  });

  final QuizSessionResult result;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final correctCount = result.answers.where((a) => a.isCorrect).length;

    return Scaffold(
      appBar: AppBar(title: const Text('퀴즈 완료')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '🎉',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '학습 완료!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (result.advancedLearningStage != null) ...[
                        Card(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '🎓 ${learningStageLabel(result.advancedLearningStage!)}로 '
                              '넘어갔어요!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _ResultRow(
                                label: '정답',
                                value:
                                    '$correctCount / ${result.answers.length}',
                              ),
                              const SizedBox(height: 12),
                              _ResultRow(
                                label: '획득 씨앗',
                                value: '+${result.seedsEarned}',
                              ),
                              const SizedBox(height: 12),
                              _ResultRow(
                                label: '남은 에너지',
                                value: '${profile.energy}',
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: StreakBadge(streak: result.newStreak),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
