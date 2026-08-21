import 'package:flutter/material.dart';

import '../../data/hamster_data.dart';
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
                      const Text('🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _ResultRow(label: '정답', value: '$correctCount / ${result.answers.length}'),
                              const SizedBox(height: 12),
                              _ResultRow(label: '획득 XP', value: '+${result.xpEarned}'),
                              const SizedBox(height: 12),
                              _ResultRow(
                                label: '남은 에너지',
                                value: '${profile.energy}',
                              ),
                              const SizedBox(height: 12),
                              _ResultRow(
                                label: '현재 레벨',
                                value: 'Lv.${result.newLevel} ${LevelUtils.titleForLevel(result.newLevel)}',
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: profile.levelProgress.clamp(0.0, 1.0),
                                  minHeight: 12,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(child: StreakBadge(streak: result.newStreak)),
                            ],
                          ),
                        ),
                      ),
                      if (result.leveledUp) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: const Color(0xFFEFF6FF),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  '레벨업!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lv.${result.previousLevel} → Lv.${result.newLevel}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (result.unlockedItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: const Color(0xFFFFF7ED),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '새 햄스터 획득!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.accentOrange,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...result.unlockedItems.map((id) {
                                  final item = HamsterData.findById(id);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '${item?.emoji ?? '🐹'} ${item?.name ?? id}',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
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
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
