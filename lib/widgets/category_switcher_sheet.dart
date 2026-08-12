import 'package:flutter/material.dart';

import '../data/interest_categories.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// 홈 화면 좌측 상단 아이콘을 눌렀을 때 뜨는 관심 카테고리 관리 시트.
///
/// 모든 카테고리를 한 화면에 보여 주고, 탭으로 선택(초록) / 해제한다.
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
  late List<String> _selectedIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.initialSelectedIds);
  }

  Future<void> _toggleCategory(String id) async {
    if (_saving) return;

    final isSelected = _selectedIds.contains(id);
    if (isSelected && _selectedIds.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관심 카테고리는 최소 1개 이상 선택해야 해요.')),
      );
      return;
    }

    final updated = isSelected
        ? _selectedIds.where((item) => item != id).toList()
        : [..._selectedIds, id];

    setState(() => _saving = true);
    await AuthService.instance.saveInterestCategories(updated);

    if (!mounted) return;
    setState(() {
      _selectedIds = updated;
      _saving = false;
    });
    widget.onCategoriesChanged(updated);
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
              '내 관심 카테고리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '카테고리를 탭해 추가하거나 해제할 수 있어요 (최소 1개)',
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
                    selected: _selectedIds.contains(category.id),
                    onTap: _saving ? null : () => _toggleCategory(category.id),
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
