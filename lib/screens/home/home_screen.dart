import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hamster_avatar.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/xp_progress_bar.dart';
import '../profile/profile_screen.dart';
import '../quiz/quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _startQuiz() async {
    final profile = _profile;
    if (profile == null) return;

    if (profile.todayQuizCompleted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘의 퀴즈를 이미 완료했어요! 내일 다시 도전해보세요.')),
      );
      return;
    }

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(profile: profile),
      ),
    );

    if (completed == true) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('사용자 정보를 불러올 수 없습니다.')));
    }

    final questionCount = QuizService.instance.getTodayQuestions().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('핀퀴즈'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    profile: profile,
                    onLogout: widget.onLogout,
                  ),
                ),
              );
              await _loadProfile();
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    HamsterAvatar(hamsterId: profile.selectedHamsterId),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile.nickname}님, 안녕하세요!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.todayQuizCompleted
                                ? '오늘 학습 완료! 🎉'
                                : '오늘의 금융 퀴즈를 시작해보세요',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XpProgressBar(
                      level: profile.level,
                      levelTitle: profile.levelTitle,
                      progress: profile.levelProgress,
                      xpInLevel: profile.xpInCurrentLevel,
                      xpForNext: profile.xpForNextLevel,
                    ),
                    const SizedBox(height: 20),
                    StreakBadge(streak: profile.streak),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: profile.todayQuizCompleted
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            profile.todayQuizCompleted ? '완료' : '미완료',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: profile.todayQuizCompleted
                                  ? AppTheme.success
                                  : AppTheme.accentOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 퀴즈 · $questionCount문항',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'OX · 4지선다 · 용돈/저축/주식/보험/세금/신용',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: profile.todayQuizCompleted ? null : _startQuiz,
                      child: Text(
                        profile.todayQuizCompleted ? '오늘 퀴즈 완료' : '오늘의 퀴즈 시작',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
