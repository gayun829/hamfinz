import 'package:flutter/material.dart';

import '../../data/learning_stages.dart';
import '../../constants/figma_assets.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/figma_settings_tokens.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/learning_stage_sheet.dart';
import '../../widgets/settings_menu_button.dart';
import '../friends/add_friend_screen.dart';
import '../legal/legal_document_screen.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.profile,
    required this.onLogout,
    this.onComplete,
    this.onProfileChanged,
  });

  final UserProfile profile;
  final VoidCallback onLogout;
  final VoidCallback? onComplete;
  final ValueChanged<int>? onProfileChanged;

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaSettingsTokens.designWidth,
    );
    final s = figma.s;

    final menuItems = [
      (
        '친구',
        () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddFriendScreen()),
          );
        },
      ),
      ('연락처 연동', () => _showComingSoon(context, '연락처 연동')),
      (
        '학습과정 (${learningStageLabel(profile.learningStage)})',
        () => _openLearningStage(context),
      ),
      ('개인정보 설정', () => _showComingSoon(context, '개인정보 설정')),
      ('규정& 개인정보 처리 방침', () => _openLegal(context)),
      ('피드백', () => _showComingSoon(context, '피드백')),
      ('로그아웃', () => _logout(context)),
    ];

    return Scaffold(
      backgroundColor: FigmaSettingsTokens.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: s(88)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: ClipOval(
                                child: Image.asset(
                                  FigmaAssets.hamsterAuth,
                                  width: s(FigmaSettingsTokens.profileSize),
                                  height: s(FigmaSettingsTokens.profileSize),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: s(FigmaSettingsTokens.profileLinkGap)),
                            SettingsMenuButton(
                              label: '프로필 설정',
                              onPressed: () =>
                                  _showComingSoon(context, '프로필 설정'),
                            ),
                            SizedBox(height: s(FigmaSettingsTokens.sectionTopGap)),
                            Text(
                              '설정',
                              style: FigmaSettingsTokens.sectionTitleStyle(
                                figma.scale,
                              ),
                            ),
                            SizedBox(height: s(FigmaSettingsTokens.sectionTitleGap)),
                            ...menuItems.map(
                              (item) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: s(FigmaSettingsTokens.menuItemGap),
                                ),
                                child: SettingsMenuButton(
                                  label: item.$1,
                                  onPressed: item.$2,
                                ),
                              ),
                            ),
                            SizedBox(height: s(FigmaSettingsTokens.withdrawTopGap)),
                            SettingsMenuButton(
                              label: '회원 탈퇴',
                              destructive: true,
                              onPressed: () => _withdraw(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                s(FigmaSettingsTokens.buttonHorizontal),
                0,
                s(FigmaSettingsTokens.buttonHorizontal),
                s(FigmaSettingsTokens.buttonBottom),
              ),
              child: SettingsPrimaryButton(
                label: '설정 완료',
                onPressed: onComplete ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
