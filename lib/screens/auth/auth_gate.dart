import 'package:flutter/material.dart';

import '../../data/interest_categories.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import 'category_select_screen.dart';
import 'login_screen.dart';
import 'onboarding/intro_screen.dart';
import 'onboarding/nickname_step_screen.dart';
import 'onboarding/signup_draft.dart';
import 'onboarding/splash_screen.dart';
import 'social_profile_setup_screen.dart';

/// 스플래시(`478:1213`)를 먼저 띄우고 세션을 확인한 뒤 시작 화면을 고른다.
///
/// 세션이 있으면 바로 홈, 없으면 설치 직후 화면(`102:12145`)이다.
/// 초기 화면 ↔ 로그인 전환은 Navigator 없이 [AuthGate] 상태로 처리해
/// `onAuthenticated` 콜백이 항상 유지되도록 한다.
///
/// 어느 경로로 들어오든 홈으로 넘기기 직전에 [_enterApp]을 거친다 — 가입의
/// 마지막 단계(관심 카테고리)를 건너뛴 계정을 여기서 한 번 더 붙잡는다.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// 로고 화면을 최소한 이만큼은 보여준다 — 세션 확인이 빨라도 깜빡이지 않게.
  static const _splashMinimum = Duration(milliseconds: 1600);

  bool _checking = true;
  bool _splashDone = false;
  bool _showLogin = false;

  /// 소셜 로그인만 끝내고 닉네임 화면에서 앱을 껐던 계정. 여기부터 이어서 받는다.
  SocialSignInResult? _pendingSocialSignUp;

  @override
  void initState() {
    super.initState();
    _checkSession();
    Future.delayed(_splashMinimum, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  Future<void> _checkSession() async {
    final user = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      await _enterApp(profile: user);
      return;
    }

    // 프로필 문서가 없으면 가입이 안 끝난 계정이다. 소셜이면 닉네임 화면부터
    // 이어받고, 이메일이면 이어갈 수 없으니 로그아웃시켜 처음부터 받는다.
    final pending = await AuthService.instance.pendingSocialSignUp();
    if (pending == null) {
      await AuthService.instance.discardIncompleteEmailSignUp();
    }
    if (!mounted) return;
    setState(() {
      _pendingSocialSignUp = pending;
      _checking = false;
    });
  }

  /// 홈으로 넘기기 전 마지막 관문.
  ///
  /// 프로필 문서는 약관 화면에서 만들어지고 카테고리는 그다음 화면에서 고르므로,
  /// 그 사이에 앱이 꺼지면 "가입은 됐는데 카테고리가 빈" 계정이 남는다. 프로필만
  /// 보고 홈으로 보내면 온보딩을 건너뛴 채 들어가게 되니, 여기서 카테고리 화면을
  /// 다시 띄운다. 가입 흐름에서 이미 골랐다면 그대로 통과한다.
  Future<void> _enterApp({UserProfile? profile}) async {
    final current = profile ?? await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    if (current != null &&
        needsInterestCategorySelection(current.interestCategories)) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CategorySelectScreen()),
      );
      if (!mounted) return;
    }
    widget.onAuthenticated();
  }

  void _showLoginScreen() => setState(() => _showLogin = true);

  void _showIntroScreen() => setState(() => _showLogin = false);

  /// 로그인 화면의 "회원가입" 링크 — 새 단계형 가입 흐름으로 보낸다.
  Future<void> _startSignupFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NicknameStepScreen(draft: SignupDraft()),
      ),
    );
    if (!mounted) return;
    final user = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    if (user != null) await _enterApp(profile: user);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_splashDone) {
      return const SplashScreen();
    }

    final pending = _pendingSocialSignUp;
    if (pending != null) {
      return SocialProfileSetupScreen(
        suggestedNickname: pending.suggestedNickname,
        onCompleted: _enterApp,
        onCancelled: () => setState(() => _pendingSocialSignUp = null),
      );
    }

    if (_showLogin) {
      return LoginScreen(
        onAuthenticated: _enterApp,
        onSwitchToSignup: _startSignupFlow,
        onBack: _showIntroScreen,
      );
    }

    return IntroScreen(
      onAuthenticated: _enterApp,
      onLogin: _showLoginScreen,
    );
  }
}
