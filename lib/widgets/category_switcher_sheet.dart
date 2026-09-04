import 'package:flutter/material.dart';

import '../data/interest_categories.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// 홈 화면 좌측 상단 아이콘 — 학습 카테고리 6개 중 1개 선택.
Future<void> showCategorySwitcherSheet({
  required BuildContext context,
  required List<String> interestCategoryIds,
  required ValueChanged<List<String>> onCategoriesChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategorySwitcherSheet(
      initialSelectedIds: interestCategoryIds,
      onCategoriesChanged: onCategoriesChanged,
    ),
  );
}

class CategorySwitcherSheet extends StatefulWidget {
  const CategorySwitcherSheet({
    super.key,
    required this.initialSelectedIds,
    required this.onCategoriesChanged,
  });

  final List<String> initialSelectedIds;
  final ValueChanged<List<String>> onCategoriesChanged;

  @override
  State<CategorySwitcherSheet> createState() => _CategorySwitcherSheetState();
}

class _CategorySwitcherSheetState extends State<CategorySwitcherSheet> {
  late String _selectedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedId = resolveActiveInterestCategoryId(widget.initialSelectedIds) ??
        kInterestCategories.first.id;
  }

  Future<void> _selectCategory(String id) async {
    if (_saving || _selectedId == id) return;

    setState(() => _saving = true);
    await AuthService.instance.saveInterestCategories([id]);

    if (!mounted) return;
    setState(() {
      _selectedId = id;
      _saving = false;
    });
    widget.onCategoriesChanged([id]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '학습 카테고리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '6개 중 1개만 선택할 수 있어요. 선택한 카테고리 문제가 출제됩니다.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final category in kInterestCategories)
                  _CategoryIconButton(
                    category: category,
                    selected: _selectedId == category.id,
                    onTap: _saving ? null : () => _selectCategory(category.id),
                  ),
              ],
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIconButton extends StatelessWidget {
  const _CategoryIconButton({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final InterestCategory category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                    : AppTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryGreen
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(category.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
