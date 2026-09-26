import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../theme/figma_onboarding_tokens.dart';
import '../../../widgets/figma_onboarding_widgets.dart';
import 'email_step_screen.dart';
import 'signup_draft.dart';

/// 가입 1단계 — 닉네임 (Figma `439:419`).
///
/// "다음"을 누를 때 길이를 보고, 통과하면 `nicknames/` 인덱스로 중복을 확인한다.
/// 이미 있으면 다음 화면으로 넘기지 않고 "이미 사용중인 아이디입니다."를 띄운다.
class NicknameStepScreen extends StatefulWidget {
  const NicknameStepScreen({super.key, required this.draft});

  final SignupDraft draft;

  static const maxLength = AuthService.nicknameMaxLength;
  static const hint = AuthService.nicknameLengthHint;

  @override
  State<NicknameStepScreen> createState() => _NicknameStepScreenState();
}

class _NicknameStepScreenState extends State<NicknameStepScreen> {
  late final _controller = TextEditingController(text: widget.draft.nickname);
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final nickname = _controller.text.trim();
    // 소셜 가입과 같은 규칙 — 길이와 문서 id로 못 쓰는 문자(`/` 등).
    final invalid = AuthService.nicknameError(nickname);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final bool taken;
    try {
      taken = await AuthService.instance.isNicknameTaken(nickname);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '중복 확인에 실패했어요. 잠시 후 다시 시도해 주세요.';
      });
      return;
    }

    if (!mounted) return;
    if (taken) {
      setState(() {
        _loading = false;
        _error = '이미 사용중인 아이디입니다.';
      });
      return;
    }

    widget.draft.nickname = nickname;
    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmailStepScreen(draft: widget.draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      message: '닉네임을 입력해조~',
      onBack: () => Navigator.of(context).pop(),
      ctaLabel: '다음',
      loading: _loading,
      onCta: _next,
      children: [
        OnboardingField(
          label: '닉네임',
          controller: _controller,
          placeholder: '닉네임을 입력해 주세요',
          onClear: () => setState(() {
            _controller.clear();
            _error = null;
          }),
          onSubmitted: (_) => _next(),
        ),
        OnboardingHelperLine(
          text: _error ?? NicknameStepScreen.hint,
          topGap: FigmaOnboardingTokens.underlineToHelper,
          color: _error == null
              ? FigmaOnboardingTokens.accent
              : FigmaOnboardingTokens.timer,
        ),
      ],
    );
  }
}
