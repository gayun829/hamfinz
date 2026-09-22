import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_auth_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/figma_auth_widgets.dart';
import '../legal/legal_document_screen.dart';
import 'category_select_screen.dart';

/// 소셜 로그인(구글·카카오)으로 처음 들어온 계정의 가입 마무리 화면.
/// 이메일 인증까지 마치고 약관 전에 그만둔 계정이 로그인으로 들어와도 여기서 마친다.
///
/// 제공자가 준 이름을 그대로 닉네임으로 박아 넣지 않고, 이메일 가입과 똑같이
/// 닉네임을 직접 고르고 약관에 동의하게 한다. 여기서 [AuthService.completeSocialSignUp]이
/// 성공해야 `users/{uid}` 문서가 생기고, 이어서 카테고리 선택까지 마치면 온보딩이 끝난다.
///
/// 중간에 나가면 프로필 문서가 없는 계정이 남으므로 로그아웃시켜 되돌린다.
class SocialProfileSetupScreen extends StatefulWidget {
  const SocialProfileSetupScreen({
    super.key,
    required this.suggestedNickname,
    required this.onCompleted,
    required this.onCancelled,
  });

  /// 제공자 이름 → 이메일 앞부분 순으로 채운 닉네임 기본값. 비어 있을 수 있다.
  final String suggestedNickname;

  /// 닉네임·약관·카테고리까지 모두 끝났을 때.
  final VoidCallback onCompleted;

  /// 사용자가 중간에 그만뒀을 때. 호출 전에 로그아웃까지 끝낸다.
  final VoidCallback onCancelled;

  /// 로그인·회원가입 화면에서 띄울 때 쓴다. 온보딩을 끝냈으면 true.
  static Future<bool> push(
    BuildContext context, {
    required String suggestedNickname,
  }) async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => SocialProfileSetupScreen(
          suggestedNickname: suggestedNickname,
          onCompleted: () => Navigator.of(routeContext).pop(true),
          onCancelled: () => Navigator.of(routeContext).pop(false),
        ),
      ),
    );
    return completed ?? false;
  }

  @override
  State<SocialProfileSetupScreen> createState() =>
      _SocialProfileSetupScreenState();
}

class _SocialProfileSetupScreenState extends State<SocialProfileSetupScreen> {
  late final _nicknameController = TextEditingController(
    text: widget.suggestedNickname,
  );
  String? _error;
  String? _notice;
  bool _loading = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 닉네임 옆 "중복확인". 소셜 로그인은 이미 인증된 상태라 예약 인덱스를 읽을 수 있다.
  ///
  /// `_loading` 동안은 뒤로가기·취소·시작하기가 모두 잠기므로, 실패해도 반드시
  /// 풀어야 한다 — 안 그러면 앱을 끄는 것 말고는 빠져나갈 길이 없다.
  Future<void> _checkNicknameDuplicate() async {
    final nickname = _nicknameController.text.trim();
    final invalid = AuthService.nicknameError(nickname);
    if (invalid != null) {
      setState(() {
        _error = invalid;
        _notice = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    try {
      final taken = await AuthService.instance.isNicknameTaken(nickname);
      if (!mounted) return;
      setState(() {
        if (taken) {
          _error = '이미 사용 중인 닉네임이에요. 다른 닉네임을 입력해주세요.';
        } else {
          _notice = '사용할 수 있는 닉네임이에요.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '중복 확인에 실패했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_agreeTerms || !_agreePrivacy) {
      setState(() {
        _error = '이용약관과 개인정보 처리방침에 동의해 주세요.';
        _notice = null;
      });
      return;
    }
    final invalid = AuthService.nicknameError(_nicknameController.text);
    if (invalid != null) {
      setState(() {
        _error = invalid;
        _notice = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    String? error;
    try {
      error = await AuthService.instance.completeSocialSignUp(
        nickname: _nicknameController.text,
      );
    } catch (_) {
      error = '가입을 마치지 못했어요. 잠시 후 다시 시도해 주세요.';
    }

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
    widget.onCompleted();
  }

  /// 가입을 그만둔다. 프로필 문서가 없는 계정으로 로그인만 남으면
  /// 다음에 앱을 켤 때 애매한 상태가 되므로 로그아웃까지 한다.
  Future<void> _cancel() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.logout();
    } catch (_) {
      // 로그아웃이 실패해도 화면에 가두지 않는다. 프로필 없는 세션이 남으면
      // 다음 실행 때 AuthGate가 이 화면으로 다시 데려온다.
    }
    if (!mounted) return;
    widget.onCancelled();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_loading) _cancel();
      },
      child: Scaffold(
        backgroundColor: FigmaAuthTokens.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FigmaHamsterHero(useSignupAsset: true),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: fieldPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: s(FigmaAuthTokens.signupHeroToForm)),
                      Text(
                        '어떤 이름으로 부를까요?',
                        style: TextStyle(
                          fontSize: s(FigmaAuthTokens.labelFontSize),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: s(16)),
                      Text(
                        '닉네임은 친구 찾기에도 쓰여요.',
                        style: FigmaAuthTokens.bodyStyle(
                          figma.scale,
                          color: FigmaAuthTokens.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: nicknamePad, right: fieldPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: s(40)),
                      FigmaAuthField(
                        label: '닉네임',
                        controller: _nicknameController,
                        placeholder: '닉네임을 입력하세요',
                        borderColor: FigmaAuthTokens.inputBorder,
                        trailing: FigmaDuplicateCheckButton(
                          onPressed: _loading ? null : _checkNicknameDuplicate,
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
                      if (_error != null || _notice != null) ...[
                        SizedBox(height: s(16)),
                        Text(
                          _error ?? _notice!,
                          style: TextStyle(
                            fontSize: s(28),
                            color: _error != null
                                ? AppTheme.error
                                : FigmaAuthTokens.link,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: s(40)),
                      FigmaLegalAgreementRow(
                        scale: figma.scale,
                        value: _agreeTerms,
                        onChanged: (value) =>
                            setState(() => _agreeTerms = value ?? false),
                        labelPrefix: '(필수) ',
                        linkLabel: '이용약관',
                        labelSuffix: '에 동의합니다',
                        onOpenDocument: () =>
                            LegalDocumentScreen.openTerms(context),
                      ),
                      SizedBox(height: s(20)),
                      FigmaLegalAgreementRow(
                        scale: figma.scale,
                        value: _agreePrivacy,
                        onChanged: (value) =>
                            setState(() => _agreePrivacy = value ?? false),
                        labelPrefix: '(필수) ',
                        linkLabel: '개인정보 처리방침',
                        labelSuffix: '에 동의합니다',
                        onOpenDocument: () =>
                            LegalDocumentScreen.openPrivacy(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: s(80)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: buttonPad),
                  child: FigmaAuthPrimaryButton(
                    label: '시작하기',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                ),
                SizedBox(height: s(32)),
                FigmaAuthFooterLink(
                  prefix: '다른 계정으로 시작할까요?',
                  actionLabel: '취소',
                  onAction: _loading ? () {} : _cancel,
                ),
                SizedBox(height: s(32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
