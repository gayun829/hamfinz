import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../services/auth_service.dart';
import '../../theme/figma_onboarding_tokens.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/figma_onboarding_widgets.dart';
import 'find_password_screen.dart';
import 'onboarding/nickname_step_screen.dart';
import 'onboarding/signup_draft.dart';
import 'social_profile_setup_screen.dart';

typedef _T = FigmaOnboardingTokens;

/// 이메일 로그인 화면 (Figma `579:1606` 로그인 화면).
///
/// 디자인 프레임(393×852)은 상태바를 포함한 좌표라 위쪽 요소는 y 값을 그대로
/// 쓰고, 맨 아래 「회원가입하기」만 화면 아래 기준으로 둔다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onAuthenticated,
    this.onSwitchToSignup,
    this.onBack,
  });

  final VoidCallback? onAuthenticated;
  final VoidCallback? onSwitchToSignup;

  /// 시작 화면(`102:12145`)에서 들어온 경우 돌아갈 곳.
  final VoidCallback? onBack;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.instance.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    // 인증까지 마치고 약관 전에 그만둔 이메일 가입자는 프로필 없이 로그인된다.
    // 그대로 홈에 보내면 프로필을 못 찾아 멈추므로 닉네임·약관부터 받는다.
    final SocialSignInResult? pending;
    try {
      pending = await AuthService.instance.pendingProfileSetup();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '회원 정보를 확인하지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
      return;
    }
    if (!mounted) return;
    await _finishSignIn(pending ?? const SocialSignInResult.signedIn());
  }

  /// 로그인이 끝난 뒤. 프로필 문서가 없는 계정이면 닉네임·약관 → 카테고리를
  /// 먼저 거치고, 중간에 그만두면 이 화면에 남는다.
  Future<void> _finishSignIn(SocialSignInResult result) async {
    if (result.needsProfileSetup) {
      final completed = await SocialProfileSetupScreen.push(
        context,
        suggestedNickname: result.suggestedNickname,
      );
      if (!mounted) return;
      if (!completed) {
        setState(() => _loading = false);
        return;
      }
    }

    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _openFindId() {
    // 아이디는 가입한 이메일이라 따로 찾는 기능이 아직 없다.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('아이디 찾기는 준비 중이에요.')));
  }

  void _openForgotPassword() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FindPasswordScreen()));
  }

  void _openSignup() {
    if (widget.onSwitchToSignup != null) {
      widget.onSwitchToSignup!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NicknameStepScreen(draft: SignupDraft()),
      ),
    );
  }

  VoidCallback? get _onBack {
    if (widget.onBack != null) return widget.onBack;
    final navigator = Navigator.of(context);
    return navigator.canPop() ? () => navigator.maybePop() : null;
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(context, designWidth: _T.designWidth);
    final s = figma.s;
    final onBack = _onBack;

    /// 디자인 중심 y [centerY]에 한 줄 글자를 세로 가운데로 놓는 칸.
    Widget line({
      required double centerY,
      double? left,
      required Widget child,
    }) {
      const half = 16.0;
      return Positioned(
        left: left == null ? 0 : s(left),
        right: left == null ? 0 : null,
        top: s(centerY - half),
        height: s(half * 2),
        child: Align(
          alignment: left == null ? Alignment.center : Alignment.centerLeft,
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: _T.background,
      // 키보드가 올라와도 배치를 그대로 두고, 아래 회원가입 링크만 가려지게 한다.
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            if (onBack != null)
              Positioned(
                left: 0,
                top: s(_T.loginBackTop),
                child: OnboardingBackButton(onPressed: onBack),
              ),
            Positioned(
              left: s(_T.loginTitleLeft),
              top: s(_T.loginTitleTop),
              child: FigmaSvg(
                FigmaAssets.loginTitle,
                width: s(_T.loginTitleWidth),
                height: s(_T.loginTitleHeight),
              ),
            ),
            Positioned(
              left: s(_T.loginFieldLeft),
              top: s(_T.loginEmailTop),
              width: s(_T.loginFieldWidth),
              height: s(_T.loginFieldHeight),
              child: _LoginField(
                figma: figma,
                controller: _emailController,
                hint: '이메일을 입력해주세요',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
            ),
            Positioned(
              left: s(_T.loginFieldLeft),
              top: s(_T.loginPasswordTop),
              width: s(_T.loginFieldWidth),
              height: s(_T.loginFieldHeight),
              child: _LoginField(
                figma: figma,
                controller: _passwordController,
                focusNode: _passwordFocus,
                hint: '비밀번호를 입력해주세요',
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ),
            Positioned(
              left: s(_T.loginFieldLeft),
              top: s(_T.loginButtonTop),
              width: s(_T.loginFieldWidth),
              height: s(_T.loginButtonHeight),
              child: _LoginButton(
                figma: figma,
                loading: _loading,
                onPressed: _submit,
              ),
            ),
            line(
              centerY: _T.loginLinksCenterY,
              left: _T.loginFindIdLeft,
              child: _TextLink(
                label: '아이디 찾기',
                style: _T.loginLinkStyle(figma.scale),
                onTap: _openFindId,
              ),
            ),
            line(
              centerY: _T.loginLinksCenterY,
              left: _T.loginDividerLeft,
              child: Text(
                '|',
                style: _T.loginLinkStyle(figma.scale, weight: FontWeight.w400),
              ),
            ),
            line(
              centerY: _T.loginLinksCenterY,
              left: _T.loginFindPasswordLeft,
              child: _TextLink(
                label: '비밀번호 찾기',
                style: _T.loginLinkStyle(figma.scale),
                onTap: _openForgotPassword,
              ),
            ),
            // 디자인에는 없지만 로그인 실패 이유는 보여야 한다. 링크 바로 아래에 둔다.
            if (_error != null)
              Positioned(
                left: s(_T.loginFieldLeft),
                width: s(_T.loginFieldWidth),
                top: s(_T.loginLinksCenterY + 24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: _T.helperStyle(figma.scale, color: _T.timer),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: s(_T.loginSignupCenterFromBottom - 16),
              height: s(32),
              child: Center(
                child: _TextLink(
                  label: '계정이 없으신가요? 회원가입하기',
                  style: _T.loginSignupStyle(figma.scale),
                  onTap: _openSignup,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 흰 바탕 · 회색 테두리 입력 칸 (`579:1623` / `579:1624`).
class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.figma,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final FigmaScale figma;
  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(_T.loginFieldRadius)),
        border: Border.all(color: _T.loginFieldBorder),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: s(_T.loginFieldTextInset)),
        child: Center(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: obscureText,
            autocorrect: false,
            enableSuggestions: !obscureText,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            cursorColor: _T.accent,
            style: _T.loginFieldStyle(figma.scale, color: Colors.black),
            // 앱 테마의 입력칸 테두리·채우기를 끄고 바깥 상자만 보이게 한다.
            decoration: InputDecoration(
              isCollapsed: true,
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: hint,
              hintStyle: _T.loginFieldStyle(figma.scale, color: _T.placeholder),
            ),
          ),
        ),
      ),
    );
  }
}

/// 하늘색 「로그인」 버튼 (`579:1625`).
class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.figma,
    required this.loading,
    required this.onPressed,
  });

  final FigmaScale figma;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final radius = BorderRadius.circular(s(_T.loginFieldRadius));
    return Material(
      color: _T.accent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: loading ? null : onPressed,
        child: Center(
          child: loading
              ? SizedBox(
                  width: s(20),
                  height: s(20),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('로그인', style: _T.loginButtonStyle(figma.scale)),
        ),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(label, style: style),
    );
  }
}
