import 'package:flutter/material.dart';

import '../../../constants/figma_assets.dart';
import '../../../services/auth_service.dart';
import '../../../theme/figma_onboarding_tokens.dart';
import '../../../widgets/figma/figma_asset_image.dart';
import '../../../widgets/figma/figma_scale.dart';
import '../../../widgets/figma_onboarding_widgets.dart';
import 'signup_draft.dart';
import 'verify_step_screen.dart';

/// 가입 3단계 — 비밀번호 (Figma `439:700`).
///
/// 규칙 4개를 실시간으로 채우고, "인증번호 전송"에서 계정을 만든 뒤 인증 메일을
/// 보낸다. Firebase는 계정을 만들 때 비밀번호가 있어야 해서, 디자인의 인증 화면은
/// 이 단계 다음에 온다.
class PasswordStepScreen extends StatefulWidget {
  const PasswordStepScreen({super.key, required this.draft});

  final SignupDraft draft;

  @override
  State<PasswordStepScreen> createState() => _PasswordStepScreenState();
}

class _PasswordStepScreenState extends State<PasswordStepScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String get _password => _controller.text;

  bool get _hasLength => _password.length >= 8;
  bool get _hasDigit => RegExp(r'\d').hasMatch(_password);
  bool get _hasLetter => RegExp(r'[A-Za-z]').hasMatch(_password);
  bool get _hasSymbol => RegExp(r'[^A-Za-z0-9]').hasMatch(_password);
  bool get _allSatisfied => _hasLength && _hasDigit && _hasLetter && _hasSymbol;

  Future<void> _next() async {
    if (!_allSatisfied) {
      setState(() => _error = '비밀번호 조건을 모두 채워 주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.instance.beginSignUp(
      email: widget.draft.email,
      password: _password,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyStepScreen(draft: widget.draft),
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
      message: '비밀번호를 입력해조~',
      onBack: () => Navigator.of(context).pop(),
      ctaLabel: '인증번호 전송',
      loading: _loading,
      onCta: _next,
      children: [
        OnboardingField(
          label: '비밀번호',
          controller: _controller,
          placeholder: '비밀번호를 입력해 주세요',
          obscureText: _obscure,
          onSubmitted: (_) => _next(),
          trailing: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            behavior: HitTestBehavior.opaque,
            child: FigmaSvg(
              _obscure
                  ? FigmaAssets.onboardingEyeOff
                  : FigmaAssets.onboardingEye,
              width: s(FigmaOnboardingTokens.eyeWidth),
              height: s(FigmaOnboardingTokens.eyeHeight),
            ),
          ),
        ),
        SizedBox(height: s(FigmaOnboardingTokens.underlineToRules)),
        _RuleRow(
          left: ('8자리 이상', _hasLength),
          right: ('숫자 포함', _hasDigit),
        ),
        SizedBox(height: s(FigmaOnboardingTokens.ruleRowGap)),
        _RuleRow(
          left: ('영문 포함', _hasLetter),
          right: ('특수문자 포함', _hasSymbol),
        ),
        if (_error != null)
          OnboardingHelperLine(
            text: _error!,
            topGap: 16,
            color: FigmaOnboardingTokens.timer,
          ),
      ],
    );
  }
}

/// 비밀번호 규칙 한 줄 — 왼쪽 칸 x=36, 오른쪽 칸 x=135 (`439:2756` 외).
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.left, required this.right});

  final (String, bool) left;
  final (String, bool) right;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return Padding(
      padding: EdgeInsets.only(left: s(FigmaOnboardingTokens.ruleColumnLeft)),
      child: Row(
        children: [
          SizedBox(
            width: s(
              FigmaOnboardingTokens.ruleColumnRight -
                  FigmaOnboardingTokens.ruleColumnLeft,
            ),
            child: _Rule(label: left.$1, satisfied: left.$2),
          ),
          _Rule(label: right.$1, satisfied: right.$2),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;
    final color = satisfied
        ? FigmaOnboardingTokens.accent
        : FigmaOnboardingTokens.placeholder;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FigmaSvg(
          FigmaAssets.onboardingCheckSmall,
          width: s(FigmaOnboardingTokens.ruleCheckWidth),
          height: s(FigmaOnboardingTokens.ruleCheckHeight),
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        SizedBox(
          width: s(
            FigmaOnboardingTokens.ruleTextGap -
                FigmaOnboardingTokens.ruleCheckWidth,
          ),
        ),
        Text(
          label,
          style: FigmaOnboardingTokens.ruleStyle(figma.scale, color: color),
        ),
      ],
    );
  }
}
