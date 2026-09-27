import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/figma_assets.dart';
import '../../data/learning_stages.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_settings_tokens.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/home_bottom_nav.dart';
import '../../widgets/learning_stage_sheet.dart';
import '../friends/add_friend_screen.dart';
import '../legal/legal_document_screen.dart';

/// 마이페이지 (Figma `273:181` 마이페이지 수정). 하단 탭 오른쪽.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    this.onProfileChanged,
  });

  final UserProfile profile;
  final VoidCallback onLogout;

  /// 학습과정을 바꾸면 새 단계를 알려준다 — 홈이 프로필을 다시 불러온다.
  final ValueChanged<int>? onProfileChanged;

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: FigmaSettingsTokens.scrim,
      builder: (_) => const _LogoutDialog(),
    );

    if (confirmed != true) return;

    await AuthService.instance.logout();
    if (!context.mounted) return;
    onLogout();
  }

  Future<void> _withdraw(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말 탈퇴하시겠어요? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '탈퇴',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    String? password;
    if (AuthService.instance.requiresPasswordToWithdraw) {
      password = await _askPassword(context);
      if (password == null || password.isEmpty || !context.mounted) return;
    }

    final error = await AuthService.instance.withdraw(password: password);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    onLogout();
  }

  /// 이메일 계정은 계정 삭제 직전에 Firebase가 재인증을 요구한다.
  Future<String?> _askPassword(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 확인'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: '비밀번호'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('확인', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label 기능은 준비 중이에요.')),
    );
  }

  Future<void> _openLegal(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '규정 & 개인정보 처리 방침',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('이용약관'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, 'terms'),
              ),
              ListTile(
                title: const Text('개인정보 처리방침'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, 'privacy'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || choice == null) return;
    if (choice == 'terms') {
      await LegalDocumentScreen.openTerms(context);
    } else {
      await LegalDocumentScreen.openPrivacy(context);
    }
  }

  void _openLearningStage(BuildContext context) {
    showLearningStageSheet(
      context: context,
      initialStage: profile.learningStage,
      onStageChanged: (stage) => onProfileChanged?.call(stage),
      bottomGap: HomeBottomNav.heightFor(MediaQuery.sizeOf(context).width),
    );
  }

  void _openFriends(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddFriendScreen()),
    );
  }

  Future<bool> _saveBio(BuildContext context, String bio) async {
    try {
      await AuthService.instance.updateBio(bio);
      profile.bio = bio;
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('한줄소개를 저장하지 못했어요.')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaSettingsTokens.designWidth,
    );
    final s = figma.s;

    final rows = [
      ('개인정보 설정', () => _showComingSoon(context, '개인정보 설정')),
      ('만족도 조사', () => _showComingSoon(context, '만족도 조사')),
      ('규정 & 개인정보 처리 방침', () => _openLegal(context)),
      ('로그아웃/ 계정전환', () => _logout(context)),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: FigmaSettingsTokens.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                figma: figma,
                nickname: profile.nickname,
                bio: profile.bio,
                onSaveBio: (bio) => _saveBio(context, bio),
                onCameraTap: () => _showComingSoon(context, '프로필 사진 변경'),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  s(FigmaSettingsTokens.menuHorizontal),
                  s(FigmaSettingsTokens.menuTop - FigmaSettingsTokens.headerHeight),
                  s(FigmaSettingsTokens.menuHorizontal),
                  s(FigmaSettingsTokens.menuHorizontal),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LearningStageCard(
                      figma: figma,
                      stage: profile.learningStage,
                      onTap: () => _openLearningStage(context),
                    ),
                    SizedBox(height: s(FigmaSettingsTokens.menuGap)),
                    SizedBox(
                      height: s(FigmaSettingsTokens.topRowHeight),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 202.59 : 11.41 : 131 (Figma 273:236 / 273:228)
                          Expanded(
                            flex: 20259,
                            child: _SettingsCard(
                              figma: figma,
                              label: '친구 목록',
                              onTap: () => _openFriends(context),
                              trailing: FigmaSvg(
                                FigmaAssets.settingsPlus,
                                width: s(24),
                                height: s(20.87),
                              ),
                              trailingRight: 10.59,
                            ),
                          ),
                          SizedBox(width: s(11.41)),
                          Expanded(
                            flex: 13100,
                            child: _SettingsCard(
                              figma: figma,
                              label: '연락처 연동',
                              onTap: () => _showComingSoon(context, '연락처 연동'),
                              trailing: _Chevron(
                                asset: FigmaAssets.settingsChevronSmall,
                                width: s(6.877),
                                height: s(9.972),
                              ),
                              trailingRight: 11.81,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final row in rows) ...[
                      SizedBox(height: s(FigmaSettingsTokens.menuGap)),
                      _SettingsRow(figma: figma, label: row.$1, onTap: row.$2),
                    ],
                    SizedBox(height: s(FigmaSettingsTokens.menuGap)),
                    _SettingsRow(
                      figma: figma,
                      label: '회원탈퇴',
                      destructive: true,
                      onTap: () => _withdraw(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 그라데이션 헤더 — 타이틀·프로필·닉네임·한줄소개 (Figma y 0~296).
class _Header extends StatelessWidget {
  const _Header({
    required this.figma,
    required this.nickname,
    required this.bio,
    required this.onSaveBio,
    required this.onCameraTap,
  });

  final FigmaScale figma;
  final String nickname;
  final String bio;
  final Future<bool> Function(String bio) onSaveBio;
  final VoidCallback onCameraTap;

  static const _titleTop = 58.0;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    // Figma 프레임은 타이틀이 상태바 바로 아래(y 58)에 온다. 노치가 더 깊은
    // 기기에서만 그만큼 내용을 내린다.
    final topShift = math.max(
      0.0,
      MediaQuery.paddingOf(context).top - s(_titleTop),
    );

    return Container(
      height: s(FigmaSettingsTokens.headerHeight) + topShift,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: FigmaSettingsTokens.headerGradientFrom,
          end: FigmaSettingsTokens.headerGradientTo,
          colors: [
            FigmaSettingsTokens.headerGradientStart,
            FigmaSettingsTokens.headerGradientEnd,
          ],
          stops: FigmaSettingsTokens.headerGradientStops,
        ),
      ),
      padding: EdgeInsets.only(top: topShift),
      child: Stack(
        children: [
          FigmaBox(
            figma: figma,
            left: 26,
            top: _titleTop,
            child: Text(
              '마이페이지',
              style: FigmaSettingsTokens.titleStyle(figma.scale),
            ),
          ),
          FigmaBox(
            figma: figma,
            left: 25,
            top: 110,
            width: 161,
            height: 161,
            child: const FigmaSvg(FigmaAssets.settingsProfile, fit: BoxFit.fill),
          ),
          // 카메라 배지 (Ellipse 210) 탭 영역
          FigmaBox(
            figma: figma,
            left: 141.11,
            top: 231.97,
            width: 37.08,
            height: 37.08,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCameraTap,
            ),
          ),
          FigmaBox(
            figma: figma,
            left: 211,
            top: 131,
            width: FigmaSettingsTokens.designWidth - 211 - 24,
            child: Text(
              nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FigmaSettingsTokens.nicknameStyle(figma.scale),
            ),
          ),
          FigmaBox(
            figma: figma,
            left: 211,
            top: 160,
            width: 122,
            height: 84,
            child: _BioBox(figma: figma, bio: bio, onSave: onSaveBio),
          ),
        ],
      ),
    );
  }
}

/// 한줄소개 박스 — 탭하면 바로 입력, 포커스가 빠지거나 완료를 누르면 저장한다.
class _BioBox extends StatefulWidget {
  const _BioBox({
    required this.figma,
    required this.bio,
    required this.onSave,
  });

  final FigmaScale figma;
  final String bio;

  /// 저장에 실패하면 false — 입력을 이전 값으로 되돌린다.
  final Future<bool> Function(String bio) onSave;

  @override
  State<_BioBox> createState() => _BioBoxState();
}

class _BioBoxState extends State<_BioBox> {
  late final _controller = TextEditingController(text: widget.bio);
  final _focusNode = FocusNode();
  late String _savedBio = widget.bio;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _BioBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 프로필을 다시 불러온 경우 — 편집 중이 아닐 때만 서버 값을 반영한다.
    if (widget.bio != oldWidget.bio && !_focusNode.hasFocus) {
      _savedBio = widget.bio;
      _controller.text = widget.bio;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  Future<void> _commit() async {
    final bio = _controller.text.trim();
    _controller.text = bio;
    if (bio == _savedBio) return;

    final previous = _savedBio;
    _savedBio = bio;
    final saved = await widget.onSave(bio);
    if (!saved && mounted) {
      _savedBio = previous;
      _controller.text = previous;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.figma.s;
    final textStyle = FigmaSettingsTokens.bioStyle(widget.figma.scale);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: Container(
        padding: EdgeInsets.all(s(10)),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          // 편집 중에도 흰 박스를 덧씌우지 않고 하늘색 박스 안에서 바로 입력한다.
          color: FigmaSettingsTokens.bioBoxFill,
          borderRadius: BorderRadius.circular(s(FigmaSettingsTokens.bioBoxRadius)),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: textStyle,
          cursorColor: Colors.white,
          minLines: 1,
          maxLines: 3,
          maxLength: FigmaSettingsTokens.bioMaxLength,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              null,
          onSubmitted: (_) => _focusNode.unfocus(),
          onTapOutside: (_) => _focusNode.unfocus(),
          // 앱 전체 테마의 흰 배경·테두리 입력칸 스타일을 쓰지 않는다 —
          // 하늘색 박스 자체가 입력칸이라 안에 흰 박스가 또 생기면 안 된다.
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: '터치해서\n한줄소개 입력',
            hintMaxLines: 3,
            hintStyle: textStyle.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// 한 줄 라벨 + 오른쪽 아이콘 카드.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.figma,
    required this.label,
    required this.onTap,
    required this.trailing,
    required this.trailingRight,
    this.destructive = false,
  });

  final FigmaScale figma;
  final String label;
  final VoidCallback onTap;
  final Widget trailing;

  /// 카드 오른쪽 끝에서 아이콘까지 Figma 간격.
  final double trailingRight;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;

    return _CardSurface(
      figma: figma,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: s(FigmaSettingsTokens.textLeft),
          right: s(trailingRight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FigmaSettingsTokens.menuStyle(
                  figma.scale,
                  destructive: destructive,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// 흰 카드 + 블러 그림자 (Figma `캘린더 그림자` + `Rectangle 536`).
class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.figma,
    required this.onTap,
    required this.child,
  });

  final FigmaScale figma;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final radius = BorderRadius.circular(s(FigmaSettingsTokens.cardRadius));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: FigmaSettingsTokens.cardShadow,
            blurRadius: s(FigmaSettingsTokens.cardShadowBlur),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

/// 40px 한 줄 메뉴 (개인정보 설정 ~ 회원탈퇴).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.figma,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final FigmaScale figma;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return SizedBox(
      height: s(FigmaSettingsTokens.rowHeight),
      child: _SettingsCard(
        figma: figma,
        label: label,
        onTap: onTap,
        destructive: destructive,
        trailing: _Chevron(
          asset: FigmaAssets.settingsChevron,
          width: s(6.513),
          height: s(10.908),
        ),
        trailingRight: 11.22,
      ),
    );
  }
}

/// Figma에서 `rotate-180 -scale-y-100`(= 좌우 반전)으로 `<`를 `>`로 쓴다.
class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: true,
      child: FigmaSvg(asset, width: width, height: height),
    );
  }
}

/// 학습 과정 카드 (Figma `538:56` 마이페이지_학습과정_달리기) — 탭하면 단계 선택 시트.
class _LearningStageCard extends StatelessWidget {
  const _LearningStageCard({
    required this.figma,
    required this.stage,
    required this.onTap,
  });

  final FigmaScale figma;
  final int stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final current = normalizeLearningStage(stage);

    return SizedBox(
      height: s(FigmaSettingsTokens.learningCardHeight),
      child: _CardSurface(
        figma: figma,
        onTap: onTap,
        child: Stack(
          children: [
            FigmaBox(
              figma: figma,
              left: 19,
              top: 16,
              child: Text(
                '학습 과정',
                style: FigmaSettingsTokens.learningTitleStyle(figma.scale),
              ),
            ),
            FigmaBox(
              figma: figma,
              left: 19,
              top: 42,
              child: Text(
                '열심히 달리는 중이에요~~!',
                style: FigmaSettingsTokens.learningSubtitleStyle(figma.scale),
              ),
            ),
            FigmaBox(
              figma: figma,
              left: 19,
              top: 67,
              width: 32,
              height: 42.88,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const FigmaSvg(
                    FigmaAssets.settingsStageFlame,
                    fit: BoxFit.fill,
                  ),
                  // 숫자 중심이 불꽃 중심보다 6.6px 아래 (Figma 423 vs 416.4).
                  Padding(
                    padding: EdgeInsets.only(top: s(13.2)),
                    child: Center(
                      child: Text(
                        '$current',
                        style: FigmaSettingsTokens.stageNumberStyle(figma.scale),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: s(61),
              right: s(22),
              top: s(79),
              height: s(31.05),
              child: _StageProgressBar(
                figma: figma,
                progress: tierProgress(current),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 회색 트랙 + 노랑→주황 채움 + 윗부분 하이라이트 (Figma `538:149`).
class _StageProgressBar extends StatelessWidget {
  const _StageProgressBar({required this.figma, required this.progress});

  final FigmaScale figma;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final radius = BorderRadius.circular(height / 2);
        // 채움이 트랙 높이보다 짧으면 둥근 끝이 찌그러지므로 최소 높이만큼은 채운다.
        final fillWidth = (constraints.maxWidth * progress.clamp(0.0, 1.0))
            .clamp(height, constraints.maxWidth);
        final glossWidth = fillWidth - s(42);

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FigmaSettingsTokens.progressTrack,
                  borderRadius: radius,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: fillWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: const LinearGradient(
                    colors: [
                      FigmaSettingsTokens.progressFillLeft,
                      FigmaSettingsTokens.progressFillRight,
                    ],
                  ),
                ),
              ),
            ),
            if (glossWidth > 0)
              Positioned(
                left: s(21),
                top: s(5),
                width: glossWidth,
                height: s(5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: FigmaSettingsTokens.progressGloss,
                    borderRadius: BorderRadius.circular(s(65)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 로그아웃 확인 팝업 (Figma `546:1381` 마이페이지_로그아웃). 로그아웃이면 true.
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaSettingsTokens.designWidth,
    );
    final s = figma.s;
    final buttonStyle = FigmaSettingsTokens.dialogButtonStyle(figma.scale);

    return Dialog(
      backgroundColor: FigmaSettingsTokens.dialogFill,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: s(42)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(s(FigmaSettingsTokens.cardRadius)),
      ),
      child: SizedBox(
        width: s(FigmaSettingsTokens.dialogWidth),
        height: s(FigmaSettingsTokens.dialogHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(s(27), s(23), s(27), s(21)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '로그아웃',
                style: FigmaSettingsTokens.dialogTitleStyle(figma.scale),
              ),
              SizedBox(height: s(17)),
              Text(
                '정말 로그아웃하시겠어요?',
                style: FigmaSettingsTokens.dialogMessageStyle(figma.scale),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _DialogButton(
                    figma: figma,
                    label: '취소',
                    style: buttonStyle,
                    filled: true,
                    onTap: () => Navigator.pop(context, false),
                  ),
                  SizedBox(width: s(18)),
                  _DialogButton(
                    figma: figma,
                    label: '로그아웃',
                    style: buttonStyle,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 팝업 버튼 — `취소`는 하늘색 알약(70×33), `로그아웃`은 글자만.
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.figma,
    required this.label,
    required this.style,
    required this.onTap,
    this.filled = false,
  });

  final FigmaScale figma;
  final String label;
  final TextStyle style;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    final radius = BorderRadius.circular(s(100));

    return Material(
      color: filled ? FigmaSettingsTokens.dialogCancelFill : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: s(33),
          constraints: BoxConstraints(minWidth: filled ? s(70) : 0),
          alignment: Alignment.center,
          child: Text(label, style: style),
        ),
      ),
    );
  }
}
