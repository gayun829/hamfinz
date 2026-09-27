import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../theme/figma_onboarding_tokens.dart';
import '../../../widgets/figma_onboarding_widgets.dart';
import 'password_step_screen.dart';
import 'signup_draft.dart';

/// 가입 2단계 — 이메일 (Figma `439:463`).
///
/// 형식을 본 뒤 서버에 이미 가입된 메일인지 묻는다. 확인에 실패하면 넘어가고,
/// 계정을 만드는 비밀번호 화면에서 Firebase가 `email-already-in-use`로 한 번 더 거른다.
class EmailStepScreen extends StatefulWidget {
  const EmailStepScreen({super.key, required this.draft});

  final SignupDraft draft;

  @override
  State<EmailStepScreen> createState() => _EmailStepScreenState();
}

class _EmailStepScreenState extends State<EmailStepScreen> {
  late final _controller = TextEditingController(text: widget.draft.email);
  String? _error;
  bool _loading = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_loading) return;
    final email = _controller.text.trim().toLowerCase();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = '올바른 이메일 형식이 아니에요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await AuthService.instance.checkEmailAvailable(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
    if (error != null) return;

    widget.draft.email = email;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PasswordStepScreen(draft: widget.draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      message: '이메일을 입력해조~',
      onBack: () => Navigator.of(context).pop(),
      ctaLabel: '다음',
      loading: _loading,
      onCta: _next,
      children: [
        OnboardingField(
          label: '이메일',
          controller: _controller,
          placeholder: '이메일을 입력해 주세요',
          keyboardType: TextInputType.emailAddress,
          onClear: () => setState(() {
            _controller.clear();
            _error = null;
          }),
          onSubmitted: (_) => _next(),
        ),
        if (_error != null)
          OnboardingHelperLine(
            text: _error!,
            topGap: FigmaOnboardingTokens.underlineToHelper,
            color: FigmaOnboardingTokens.timer,
          ),
      ],
    );
  }
}
