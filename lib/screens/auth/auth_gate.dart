import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// 세션 확인 후 Figma 로그인 화면(`1:152`)을 시작 화면으로 표시한다.
///
/// 로그인 ↔ 회원가입 전환은 Navigator 없이 [AuthGate] 상태로 처리해
/// `onAuthenticated` 콜백이 항상 유지되도록 한다.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _showSignup = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      widget.onAuthenticated();
      return;
    }
    setState(() => _checking = false);
  }

  void _showLoginScreen() => setState(() => _showSignup = false);

  void _showSignupScreen() => setState(() => _showSignup = true);

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppTheme.figmaAuthBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showSignup) {
      return SignupScreen(
        onAuthenticated: widget.onAuthenticated,
        onSwitchToLogin: _showLoginScreen,
      );
    }

    return LoginScreen(
      onAuthenticated: widget.onAuthenticated,
      onSwitchToSignup: _showSignupScreen,
    );
  }
}
