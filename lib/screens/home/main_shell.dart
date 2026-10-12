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
            child: _FadeIndexedStack(
              index: _currentIndex,
              children: [
                const NewsScreen(),
                HomeScreen(
                  key: ValueKey(profile.learningStage),
                  profile: profile,
                  onNavTap: _onNavTap,
                ),
                SettingsScreen(
                  profile: profile,
                  onLogout: widget.onLogout,
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

/// [IndexedStack]처럼 탭 상태는 살려 두되, 탭이 바뀔 때 툭 끊지 않고 겹쳐 넘긴다.
class _FadeIndexedStack extends StatelessWidget {
  const _FadeIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          // 숨은 탭은 터치·애니메이션·스크린리더에서 빠진다.
          IgnorePointer(
            ignoring: i != index,
            child: ExcludeSemantics(
              excluding: i != index,
              child: TickerMode(
                enabled: i == index,
                child: AnimatedOpacity(
                  opacity: i == index ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: children[i],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
