import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
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

  Widget _buildBody() {
    if (_loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = _profile;
    if (profile == null) {
      return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
    }

    switch (_currentIndex) {
      case 0:
        return const _PlaceholderTab(
          title: '메뉴',
          message: '학습 메뉴 화면이 준비 중이에요.',
        );
      case 2:
        return const _PlaceholderTab(
          title: '커뮤니티',
          message: '친구/커뮤니티 기능이 준비 중이에요.',
        );
      case 3:
        return ProfileScreen(
          profile: profile,
          onLogout: widget.onLogout,
        );
      case 1:
      default:
        return HomeScreen(
          onLogout: widget.onLogout,
          currentNavIndex: _currentIndex,
          onNavTap: _onNavTap,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.figmaHomeBackground,
      body: _buildBody(),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.message,
  });

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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
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
