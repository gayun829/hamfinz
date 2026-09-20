import 'package:flutter/material.dart';

import '../../../constants/figma_assets.dart';
import '../../../services/auth_service.dart';
import '../../../theme/figma_onboarding_tokens.dart';
import '../../../widgets/figma/figma_asset_image.dart';
import '../../../widgets/figma/figma_scale.dart';
import '../social_profile_setup_screen.dart';
import 'nickname_step_screen.dart';
import 'signup_draft.dart';

/// 설치 후 처음 열었을 때 나오는 시작 화면 (Figma `102:12145`).
///
/// 원터치 가입이 기본이라 소셜 버튼 3개가 먼저 오고, 이메일로 가입하려는
/// 사람만 "다른 방법으로 계속하기"에서 한 화면씩 입력하는 흐름으로 간다.
class IntroScreen extends StatefulWidget {
  const IntroScreen({
    super.key,
    required this.onAuthenticated,
    required this.onLogin,
  });

  final VoidCallback onAuthenticated;

  /// 이미 가입한 계정으로 들어가기 — 기존 이메일 로그인 화면.
  final VoidCallback onLogin;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  String? _error;
  bool _loading = false;

  Future<void> _continueWithSocial(
    Future<SocialSignInResult> Function() signIn,
  ) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await signIn();

    if (!mounted) return;
    if (result.error != null) {
      setState(() {
        _loading = false;
        _error = result.error;
      });
      return;
    }

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

    widget.onAuthenticated();
  }

  void _continueWithApple() {
    // 나중에 추가: Apple 로그인 연동 (Apple Developer Program 계정 필요)
    setState(() => _error = 'Apple 로그인은 준비 중이에요.');
  }

  Future<void> _continueWithEmail() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NicknameStepScreen(draft: SignupDraft()),
      ),
    );
    if (!mounted) return;
    // 가입을 끝내면 프로필이 생긴다. 중간에 그만뒀으면 그대로 이 화면에 남는다.
    final user = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    if (user != null) widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return Scaffold(
      backgroundColor: FigmaOnboardingTokens.background,
      // 디자인 프레임(393×852)은 상태바를 포함한 좌표라 위쪽은 SafeArea를 끄고
      // y 값을 그대로 쓴다. 아래쪽만 홈 인디케이터를 피한다.
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: s(FigmaOnboardingTokens.introDotTop)),
            _IntroHamster(figma: figma),
            SizedBox(height: s(FigmaOnboardingTokens.introHamsterToButton)),
            _IntroButton(
              label: '카카오톡으로 계속하기',
              background: FigmaOnboardingTokens.kakaoFill,
              foreground: Colors.black,
              iconGap: 7,
              icon: FigmaPng(
                FigmaAssets.onboardingKakao,
                width: s(FigmaOnboardingTokens.introKakaoIconWidth),
                height: s(FigmaOnboardingTokens.introKakaoIconHeight),
              ),
              onPressed: _loading
                  ? null
                  : () => _continueWithSocial(
                      AuthService.instance.signInWithKakao,
                    ),
            ),
            SizedBox(height: s(FigmaOnboardingTokens.introButtonGap)),
            _IntroButton(
              label: 'Apple로 계속하기',
              background: Colors.black,
              foreground: Colors.white,
              // 검은 버튼 위라 흰색 애플 로고가 필요하다. Figma export는 배경이
              // 불투명해서 못 쓰고, 기존 로고(투명 배경)를 흰색으로 칠해 쓴다.
              icon: Image.asset(
                FigmaAssets.appleLogin,
                width: s(FigmaOnboardingTokens.introAppleIconWidth),
                height: s(FigmaOnboardingTokens.introAppleIconHeight),
                fit: BoxFit.contain,
                color: Colors.white,
              ),
              onPressed: _loading ? null : _continueWithApple,
            ),
            SizedBox(height: s(FigmaOnboardingTokens.introButtonGap)),
            _IntroButton(
              label: 'goolge로 계속하기',
              background: Colors.white,
              foreground: Colors.black,
              bordered: true,
              icon: FigmaPng(
                FigmaAssets.googleLogin,
                width: s(FigmaOnboardingTokens.introGoogleIconWidth),
                height: s(FigmaOnboardingTokens.introGoogleIconHeight),
              ),
              onPressed: _loading
                  ? null
                  : () => _continueWithSocial(
                      AuthService.instance.signInWithGoogle,
                    ),
            ),
            SizedBox(height: s(FigmaOnboardingTokens.introButtonGap)),
            _IntroButton(
              label: '다른 방법으로 계속하기',
              background: Colors.white,
              foreground: Colors.black,
              bordered: true,
              onPressed: _loading ? null : _continueWithEmail,
            ),
            SizedBox(height: s(FigmaOnboardingTokens.introButtonToLogin)),
            if (_error != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: s(FigmaOnboardingTokens.introButtonLeft),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: FigmaOnboardingTokens.helperStyle(
                    figma.scale,
                    color: FigmaOnboardingTokens.timer,
                  ),
                ),
              ),
              SizedBox(height: s(12)),
            ],
            // 디자인에는 없지만, 이메일로 가입한 기존 회원이 들어올 입구가 필요하다.
            GestureDetector(
              onTap: _loading ? null : widget.onLogin,
              behavior: HitTestBehavior.opaque,
              child: Text(
                '이미 계정이 있나요?  로그인',
                textAlign: TextAlign.center,
                style: FigmaOnboardingTokens.helperStyle(
                  figma.scale,
                  color: FigmaOnboardingTokens.accent,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _IntroHamster extends StatelessWidget {
  const _IntroHamster({required this.figma});

  final FigmaScale figma;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final dotToHamster =
        FigmaOnboardingTokens.introHamsterTop -
        FigmaOnboardingTokens.introDotTop;

    return SizedBox(
      height: s(dotToHamster + FigmaOnboardingTokens.introHamsterHeight),
      child: Stack(
        children: [
          Positioned(
            left: s(FigmaOnboardingTokens.introDotLeft),
            top: 0,
            child: FigmaSvg(
              FigmaAssets.onboardingIntroDot,
              width: s(FigmaOnboardingTokens.introDotWidth),
              height: s(FigmaOnboardingTokens.introDotHeight),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: s(dotToHamster),
            child: Center(
              child: FigmaSvg(
                FigmaAssets.onboardingHamsterIntro,
                width: s(FigmaOnboardingTokens.introHamsterWidth),
                height: s(FigmaOnboardingTokens.introHamsterHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroButton extends StatelessWidget {
  const _IntroButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.icon,
    this.bordered = false,
    this.iconGap = 4,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool bordered;
  final double iconGap;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: s(FigmaOnboardingTokens.introButtonLeft),
      ),
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1,
          child: Container(
            height: s(FigmaOnboardingTokens.introButtonHeight),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(
                s(FigmaOnboardingTokens.introButtonRadius),
              ),
              border: bordered ? Border.all(color: Colors.black) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, SizedBox(width: s(iconGap))],
                Text(
                  label,
                  style: FigmaOnboardingTokens.introButtonStyle(
                    figma.scale,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
