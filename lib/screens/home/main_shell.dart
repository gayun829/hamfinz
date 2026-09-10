import 'package:flutter/material.dart';

import '../../data/learning_stages.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home_bottom_nav.dart';
import '../news/news_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1;
  UserProfile? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.instance.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  void _onLearningStageChanged(int stage) {
    setState(() {
      _profile?.learningStage = normalizeLearningStage(stage);
    });
    _loadProfile();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return Scaffold(
        backgroundColor: AppTheme.figmaHomeBackground,
        body: Column(
          children: [
            const Expanded(child: Center(child: CircularProgressIndicator())),
            HomeBottomNav(currentIndex: _currentIndex, onTap: _onNavTap),
          ],
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.figmaHomeBackground,
        body: Column(
          children: [
            const Expanded(child: Center(child: Text('사용자 정보를 불러올 수 없습니다.'))),
            HomeBottomNav(currentIndex: _currentIndex, onTap: _onNavTap),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.figmaHomeBackground,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const NewsScreen(),
                HomeScreen(
                  key: ValueKey(profile.learningStage),
                  profile: profile,
                ),
                SettingsScreen(
                  profile: profile,
                  onLogout: widget.onLogout,
                  onComplete: () => setState(() => _currentIndex = 1),
                  onProfileChanged: _onLearningStageChanged,
                ),
              ],
            ),
          ),
          HomeBottomNav(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
    );
  }
}
