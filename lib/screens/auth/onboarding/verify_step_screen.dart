import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../theme/figma_onboarding_tokens.dart';
import '../../../widgets/figma/figma_scale.dart';
import '../../../widgets/figma_onboarding_widgets.dart';
import 'signup_draft.dart';
import 'terms_step_screen.dart';

/// 가입 4단계 — 이메일 인증 (Figma `439:644`).
///
/// 디자인은 6자리 인증번호 입력칸이지만, 백엔드는 Firebase 이메일 인증 **링크**를
/// 쓴다. 그래서 입력칸 자리에 받는 주소를 보여주고, "다음"이 서버에 인증 여부를
/// 다시 묻는다.
///
/// 디자인의 3:00 타이머는 뺐다. Firebase 인증 링크는 3분보다 훨씬 오래 유효해서
/// 시간이 지나도 "다음"이 그대로 통과한다 — 없는 마감을 보여주면 멀쩡한 링크를
/// 두고 재전송만 누르게 된다. 재전송 링크는 타이머 자리로 올렸다.
class VerifyStepScreen extends StatefulWidget {
  const VerifyStepScreen({super.key, required this.draft});

  final SignupDraft draft;

  @override
  State<VerifyStepScreen> createState() => _VerifyStepScreenState();
}

class _VerifyStepScreenState extends State<VerifyStepScreen> {
  String? _error;
  bool _loading = false;

  Future<void> _resend() async {
    final error = await AuthService.instance.resendVerificationEmail();
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _error = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('인증 메일을 다시 보냈어요.')));
  }

  Future<void> _next() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final bool verified;
    try {
      verified = await AuthService.instance.checkEmailVerified();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '인증 여부를 확인하지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
      return;
    }

    if (!mounted) return;
    if (!verified) {
      setState(() {
        _loading = false;
        _error = '아직 인증되지 않았어요. 메일함에서 링크를 눌러주세요.';
      });
      return;
    }

    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TermsStepScreen(draft: widget.draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return OnboardingStepScaffold(
      message: '메일함을 확인해조~',
      onBack: () => Navigator.of(context).pop(),
      ctaLabel: '다음',
      loading: _loading,
      onCta: _next,
      children: [
        OnboardingStaticField(
          label: '인증메일',
          value: widget.draft.email,
        ),
        OnboardingHelperLine(
          text: '인증 메일이 오지 않나요?',
          topGap: FigmaOnboardingTokens.underlineToResend,
          left: 31,
          color: FigmaOnboardingTokens.placeholder,
          underline: true,
          onTap: _resend,
        ),
        if (_error != null)
          OnboardingHelperLine(
            text: _error!,
            topGap: 16,
            left: 31,
            color: FigmaOnboardingTokens.timer,
          ),
        SizedBox(height: s(8)),
      ],
    );
  }
}
