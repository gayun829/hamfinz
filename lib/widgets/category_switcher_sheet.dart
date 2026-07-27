import 'package:flutter/material.dart';

import '../data/interest_categories.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// 홈 화면 좌측 상단 아이콘을 눌렀을 때 뜨는 관심 카테고리 스위처.
///
/// 이미 등록한 카테고리를 위쪽에 보여주고, '+' 버튼을 누르면 같은 시트 안에서
/// 아직 선택하지 않은 카테고리들을 펼쳐 추가로 등록할 수 있게 한다.
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
  String? _activeId;
  bool _showAdd = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.initialSelectedIds);
    _activeId = _selectedIds.isNotEmpty ? _selectedIds.first : null;
  }

  List<InterestCategory> get _selectedCategories => _selectedIds
      .map((id) => kInterestCategories.firstWhere((c) => c.id == id))
      .toList();

  List<InterestCategory> get _remainingCategories => kInterestCategories
      .where((c) => !_selectedIds.contains(c.id))
      .toList();

  Future<void> _addCategory(String id) async {
    if (_saving || _selectedIds.contains(id)) return;
    setState(() => _saving = true);

    final updated = [..._selectedIds, id];
    await AuthService.instance.saveInterestCategories(updated);

    if (!mounted) return;
    setState(() {
      _selectedIds = updated;
      _activeId = id;
      _showAdd = false;
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
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in _selectedCategories)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _CategoryIconButton(
                        category: category,
                        selected: category.id == _activeId,
                        onTap: () =>
                            setState(() => _activeId = category.id),
                      ),
                    ),
                  _AddCategoryButton(
                    expanded: _showAdd,
                    enabled: _remainingCategories.isNotEmpty,
                    onTap: () => setState(() => _showAdd = !_showAdd),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: !_showAdd
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _remainingCategories.isEmpty
                          ? const Text(
                              '모든 카테고리를 이미 선택했어요',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: AppTheme.textSecondary),
                            )
                          : Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final category in _remainingCategories)
                                  _CategoryIconButton(
                                    category: category,
                                    selected: false,
                                    onTap: () => _addCategory(category.id),
                                  ),
                              ],
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  const _AddCategoryButton({
    required this.expanded,
    required this.enabled,
    required this.onTap,
  });

  final bool expanded;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.card : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: expanded ? AppTheme.primaryGreen : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          expanded ? Icons.close : Icons.add,
          color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
