import 'package:flutter/material.dart';

import '../../../constants/figma_assets.dart';
import '../../../services/auth_service.dart';
import '../../../theme/figma_onboarding_tokens.dart';
import '../../../widgets/figma/figma_asset_image.dart';
import '../../../widgets/figma/figma_scale.dart';
import '../../../widgets/figma_onboarding_widgets.dart';
import '../../legal/legal_document_screen.dart';
import '../category_select_screen.dart';
import 'signup_draft.dart';

/// 가입 5단계 — 약관 동의 (Figma `439:2779`).
///
/// "회원가입"에서 `users/{uid}` 문서가 처음 만들어지고, 이어서 관심 카테고리까지
/// 고르면 가입이 끝난다.
class TermsStepScreen extends StatefulWidget {
  const TermsStepScreen({super.key, required this.draft});

  final SignupDraft draft;

  @override
  State<TermsStepScreen> createState() => _TermsStepScreenState();
}

class _TermsStepScreenState extends State<TermsStepScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _marketing = false;
  String? _error;
  bool _loading = false;

  bool get _allChecked => _terms && _privacy && _marketing;
  bool get _requiredChecked => _terms && _privacy;

  void _toggleAll() {
    final next = !_allChecked;
    setState(() {
      _terms = next;
      _privacy = next;
      _marketing = next;
      if (_requiredChecked) _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_requiredChecked) {
      setState(() => _error = '필수 약관에 동의해 주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.instance.completeSignUp(
      nickname: widget.draft.nickname,
      marketingConsent: _marketing,
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
    // 가입 흐름 전체를 닫고 첫 화면(AuthGate)이 세션을 다시 확인하게 한다.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return OnboardingStepScaffold(
      message: '가입약관을 확인해조~',
      onBack: () => Navigator.of(context).pop(),
      ctaLabel: '회원가입',
      ctaRounded: true,
      loading: _loading,
      onCta: _submit,
      children: [
        // 햄스터 블록 끝(191.83) → 첫 줄 top(233). 행 높이 78 안에서 동그라미가
        // 가운데라 디자인의 첫 동그라미 중심(272)에 맞는다.
        SizedBox(height: s(41.17)),
        _TermsRow(
          label: '전체 동의',
          checked: _allChecked,
          onTap: _toggleAll,
        ),
        _TermsRow(
          label: '이용 약관 동의(필수)',
          checked: _terms,
          onTap: () => setState(() {
            _terms = !_terms;
            if (_requiredChecked) _error = null;
          }),
          onOpenDocument: () => LegalDocumentScreen.openTerms(context),
        ),
        _TermsRow(
          label: '개인정보 수집 및 이용(필수)',
          checked: _privacy,
          onTap: () => setState(() {
            _privacy = !_privacy;
            if (_requiredChecked) _error = null;
          }),
          onOpenDocument: () => LegalDocumentScreen.openPrivacy(context),
        ),
        _TermsRow(
          label: '광고성 정보, 마케팅 활용 동의(선택)',
          checked: _marketing,
          onTap: () => setState(() => _marketing = !_marketing),
          onOpenDocument: () => LegalDocumentScreen.openMarketing(context),
        ),
        if (_error != null)
          OnboardingHelperLine(
            text: _error!,
            topGap: 12,
            left: FigmaOnboardingTokens.termsRowLeft,
            color: FigmaOnboardingTokens.timer,
          ),
      ],
    );
  }
}

/// 동그란 체크 + 문구 + 본문 열기 화살표 (`439:2887`).
class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.label,
    required this.checked,
    required this.onTap,
    this.onOpenDocument,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  /// null이면 화살표를 그리지 않는다 ("전체 동의"는 본문이 없다).
  final VoidCallback? onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaOnboardingTokens.designWidth,
    );
    final s = figma.s;

    return SizedBox(
      height: s(FigmaOnboardingTokens.termsRowPitch),
      child: Row(
        children: [
          SizedBox(width: s(FigmaOnboardingTokens.termsRowLeft)),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: s(FigmaOnboardingTokens.termsCircleBox),
              height: s(FigmaOnboardingTokens.termsCircleBox),
              child: Center(
                child: Container(
                  width: s(FigmaOnboardingTokens.termsCircleSize),
                  height: s(FigmaOnboardingTokens.termsCircleSize),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: checked
                        ? FigmaOnboardingTokens.accent
                        : FigmaOnboardingTokens.checkOff,
                    shape: BoxShape.circle,
                  ),
                  child: FigmaSvg(
                    FigmaAssets.onboardingCheckMark,
                    width: s(FigmaOnboardingTokens.termsCheckWidth),
                    height: s(FigmaOnboardingTokens.termsCheckHeight),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: s(
              FigmaOnboardingTokens.termsTextLeft -
                  FigmaOnboardingTokens.termsRowLeft -
                  FigmaOnboardingTokens.termsCircleBox,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                label,
                style: FigmaOnboardingTokens.termsStyle(figma.scale),
              ),
            ),
          ),
          if (onOpenDocument != null)
            GestureDetector(
              onTap: onOpenDocument,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: s(10)),
                child: FigmaSvg(
                  FigmaAssets.onboardingChevron,
                  width: s(FigmaOnboardingTokens.termsChevronWidth),
                  height: s(FigmaOnboardingTokens.termsChevronHeight),
                ),
              ),
            ),
          SizedBox(width: s(FigmaOnboardingTokens.termsChevronRight - 24)),
        ],
      ),
    );
  }
}
