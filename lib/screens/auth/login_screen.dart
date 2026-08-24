import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_auth_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/figma_auth_widgets.dart';
import 'find_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onAuthenticated,
    this.onSwitchToSignup,
  });

  final VoidCallback? onAuthenticated;
  final VoidCallback? onSwitchToSignup;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.instance.signInWithGoogle();

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _loginWithApple() {
    // 나중에 추가: Apple 로그인 연동
  }

  Future<void> _loginWithKakao() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.instance.signInWithKakao();

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FindPasswordScreen()),
    );
  }

  void _openSignup() {
    if (widget.onSwitchToSignup != null) {
      widget.onSwitchToSignup!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;
    final fieldPad = s(FigmaAuthTokens.loginFieldPaddingX);
    final buttonPad = s(FigmaAuthTokens.loginButtonPaddingX);

    return Scaffold(
      backgroundColor: FigmaAuthTokens.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FigmaHamsterHero(useSignupAsset: false),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: fieldPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: s(FigmaAuthTokens.loginHeroToForm)),
                    FigmaAuthField(
                      label: '아이디(이메일)',
                      controller: _emailController,
                      placeholder: '아이디/ 이메일 주소를 입력하세요',
                      keyboardType: TextInputType.emailAddress,
                      borderColor: FigmaAuthTokens.inputBorder,
                    ),
                    SizedBox(height: s(FigmaAuthTokens.loginFieldGap)),
                    FigmaAuthField(
                      label: '비밀번호',
                      controller: _passwordController,
                      placeholder: '비밀번호를 입력하세요',
                      obscureText: true,
                      borderColor: FigmaAuthTokens.inputBorderAlt,
                    ),
                    SizedBox(height: s(FigmaAuthTokens.loginForgotTopGap)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _openForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: FigmaAuthTokens.placeholder,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '비밀번호를 잊으셨나요?',
                          style: FigmaAuthTokens.bodyStyle(figma.scale),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: s(16)),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: s(28),
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: s(FigmaAuthTokens.loginButtonTopGap)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: buttonPad),
                child: FigmaAuthPrimaryButton(
                  label: '로그인',
                  loading: _loading,
                  onPressed: _submit,
                ),
              ),
              SizedBox(height: s(FigmaAuthTokens.loginDividerTopGap)),
              const FigmaAuthDivider(),
              SizedBox(height: s(FigmaAuthTokens.loginSocialTopGap)),
              FigmaSocialLoginRow(
                onGoogle: _loginWithGoogle,
                onApple: _loginWithApple,
                onKakao: _loginWithKakao,
              ),
              SizedBox(height: s(FigmaAuthTokens.loginFooterTopGap)),
              FigmaAuthFooterLink(
                prefix: '기존 계정을 찾을 수 없나요?',
                actionLabel: '회원가입',
                onAction: _openSignup,
              ),
              SizedBox(height: s(32)),
            ],
          ),
        ),
      ),
    );
  }
}
