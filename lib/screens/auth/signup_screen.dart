import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_auth_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/figma_auth_widgets.dart';
import 'category_select_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    this.onAuthenticated,
    this.onSwitchToLogin,
  });

  final VoidCallback? onAuthenticated;
  final VoidCallback? onSwitchToLogin;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.instance.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      nickname: _nicknameController.text,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CategorySelectScreen()),
    );

    if (!mounted) return;
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _checkNicknameDuplicate() {
    // 나중에 추가: 닉네임 중복 확인
  }

  void _signUpWithGoogle() {
    // 나중에 추가: 구글 계정 가입 연동
  }

  void _signUpWithApple() {
    // 나중에 추가: Apple 가입 연동
  }

  void _signUpWithKakao() {
    // 나중에 추가: 카카오 가입 연동
  }

  void _openLogin() {
    if (widget.onSwitchToLogin != null) {
      widget.onSwitchToLogin!();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaAuthTokens.designWidth,
    );
    final s = figma.s;
    final fieldPad = s(FigmaAuthTokens.signupFieldPaddingX);
    final nicknamePad = s(FigmaAuthTokens.signupNicknameFieldPaddingX);
    final buttonPad = s(FigmaAuthTokens.signupButtonPaddingX);

    return Scaffold(
      backgroundColor: FigmaAuthTokens.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FigmaHamsterHero(useSignupAsset: true),
              Padding(
                padding: EdgeInsets.only(left: nicknamePad, right: fieldPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: s(FigmaAuthTokens.signupHeroToForm)),
                    FigmaAuthField(
                      label: '닉네임',
                      controller: _nicknameController,
                      placeholder: '닉네임을 입력하세요',
                      borderColor: FigmaAuthTokens.inputBorder,
                      trailing: FigmaDuplicateCheckButton(
                        onPressed: _checkNicknameDuplicate,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: fieldPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: s(FigmaAuthTokens.signupFieldGap)),
                    FigmaAuthField(
                      label: '아이디(이메일)',
                      controller: _emailController,
                      placeholder: '아이디/ 이메일 주소를 입력하세요',
                      keyboardType: TextInputType.emailAddress,
                      borderColor: FigmaAuthTokens.inputBorderAlt,
                    ),
                    SizedBox(height: s(FigmaAuthTokens.signupFieldGap)),
                    FigmaAuthField(
                      label: '비밀번호',
                      controller: _passwordController,
                      placeholder: '비밀번호를 입력하세요',
                      obscureText: true,
                      borderColor: FigmaAuthTokens.inputBorderAlt,
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
              SizedBox(height: s(FigmaAuthTokens.signupButtonTopGap)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: buttonPad),
                child: FigmaAuthPrimaryButton(
                  label: '회원가입',
                  loading: _loading,
                  onPressed: _submit,
                ),
              ),
              SizedBox(height: s(FigmaAuthTokens.signupDividerTopGap)),
              const FigmaAuthDivider(useSignupLine: true),
              SizedBox(height: s(FigmaAuthTokens.signupSocialTopGap)),
              FigmaSocialLoginRow(
                useSignupAssets: true,
                onGoogle: _signUpWithGoogle,
                onApple: _signUpWithApple,
                onKakao: _signUpWithKakao,
              ),
              SizedBox(height: s(FigmaAuthTokens.signupFooterTopGap)),
              FigmaAuthFooterLink(
                prefix: '이미 계정을 가지고 있나요?',
                actionLabel: '로그인',
                onAction: _openLogin,
              ),
              SizedBox(height: s(32)),
            ],
          ),
        ),
      ),
    );
  }
}
