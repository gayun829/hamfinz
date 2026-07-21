import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.level,
    required this.levelTitle,
    required this.progress,
    required this.xpInLevel,
    required this.xpForNext,
  });

  final int level;
  final String levelTitle;
  final double progress;
  final int xpInLevel;
  final int xpForNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lv.$level $levelTitle',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '$xpInLevel / ${xpInLevel + xpForNext} XP',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: const Color(0xFFE5E7EB),
            color: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }
}
