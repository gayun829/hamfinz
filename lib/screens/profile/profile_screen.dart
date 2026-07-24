import 'package:flutter/material.dart';

import '../../data/hamster_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hamster_avatar.dart';
import '../../widgets/xp_progress_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  final UserProfile profile;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _selectHamster(String id) async {
    setState(() => _profile.selectedHamsterId = id);
    await AuthService.instance.saveProfile(_profile);
  }

  Future<void> _logout() async {
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
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  HamsterAvatar(hamsterId: _profile.selectedHamsterId, size: 96),
                  const SizedBox(height: 12),
                  Text(
                    _profile.nickname,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile.email,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  XpProgressBar(
                    level: _profile.level,
                    levelTitle: _profile.levelTitle,
                    progress: _profile.levelProgress,
                    xpInLevel: _profile.xpInCurrentLevel,
                    xpForNext: _profile.xpForNextLevel,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '햄스터 컬렉션',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...HamsterData.items.map((item) {
            final unlocked = _profile.unlockedHamsterIds.contains(item.id);
            final selected = _profile.selectedHamsterId == item.id;
            return Card(
              child: ListTile(
                leading: Text(
                  item.emoji,
                  style: TextStyle(
                    fontSize: 28,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: unlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                subtitle: Text(
                  unlocked ? item.unlockDescription : '아직 잠금',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: unlocked
                    ? (selected
                        ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                        : TextButton(
                            onPressed: () => _selectHamster(item.id),
                            child: const Text('대표 설정'),
                          ))
                    : const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            '학습 기록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (_profile.learningHistory.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('아직 학습 기록이 없습니다.'),
              ),
            )
          else
            ..._profile.learningHistory.take(7).map(
                  (record) => Card(
                    child: ListTile(
                      title: Text(record.date),
                      subtitle: Text('정답 ${record.correctCount}/${record.totalCount}'),
                      trailing: Text(
                        '+${record.xpEarned} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ),
          if (_profile.categoryStats.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '카테고리별 정답률',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ..._profile.categoryStats.entries.map(
              (entry) {
                final accuracy = (entry.value.accuracy * 100).round();
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    trailing: Text(
                      '$accuracy%',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
