import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'social_profile_setup_screen.dart';

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

  /// 소셜 로그인만 끝내고 닉네임 화면에서 앱을 껐던 계정. 여기부터 이어서 받는다.
  SocialSignInResult? _pendingSocialSignUp;

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

    // 프로필 문서가 없으면 가입이 안 끝난 계정이다. 소셜이면 닉네임부터 이어받고,
    // 이메일이면 회원가입 화면이 인증 단계를 다시 이어간다.
    final pending = await AuthService.instance.pendingSocialSignUp();
    if (!mounted) return;
    setState(() {
      _pendingSocialSignUp = pending;
      _checking = false;
    });
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

    final pending = _pendingSocialSignUp;
    if (pending != null) {
      return SocialProfileSetupScreen(
        suggestedNickname: pending.suggestedNickname,
        onCompleted: widget.onAuthenticated,
        onCancelled: () => setState(() => _pendingSocialSignUp = null),
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
