import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home_bottom_nav.dart';
import '../news/news_screen.dart';
import '../profile/profile_screen.dart';
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
    final profile = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loadingProfile = false;
    });
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
                const HomeScreen(),
                const _PlaceholderTab(title: '커뮤니티', message: '준비 중'),
                ProfileScreen(profile: profile, onLogout: widget.onLogout),
              ],
            ),
          ),
          HomeBottomNav(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
