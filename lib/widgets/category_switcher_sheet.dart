import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    barrierColor: const Color(0x8C3C3C3C),
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
  /// 저장 중인 카테고리 id — 저장이 끝날 때까지 다른 탭을 막는다.
  String? _savingId;

  @override
  void initState() {
    super.initState();
    _selectedId = resolveActiveInterestCategoryId(widget.initialSelectedIds) ??
        kInterestCategories.first.id;
  }

  Future<void> _selectCategory(String id) async {
    if (_savingId != null || _selectedId == id) return;

    setState(() => _savingId = id);
    final error = await AuthService.instance.saveInterestCategories([id]);

    if (!mounted) return;
    if (error != null) {
      setState(() => _savingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    setState(() {
      _selectedId = id;
      _savingId = null;
    });
    widget.onCategoriesChanged([id]);
  }

  @override
  Widget build(BuildContext context) {
    // Figma: 학습 카테고리창 v01 (576:1258)
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(44, 15.6, 44, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 53,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(31),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  '학습 카테고리',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  '6개 중 1개만 선택할 수 있어요.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA7A6A6),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  '선택한 카테고리의 문제가 출제됩니다.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFC8C8C8),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              for (var row = 0; row < kInterestCategories.length; row += 3) ...[
                if (row > 0) const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final category
                        in kInterestCategories.skip(row).take(3))
                      _CategoryIconButton(
                        category: category,
                        selected: _selectedId == category.id,
                        saving: _savingId == category.id,
                        onTap: _savingId != null
                            ? null
                            : () => _selectCategory(category.id),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryIconButton extends StatelessWidget {
  const _CategoryIconButton({
    required this.category,
    required this.selected,
    required this.saving,
    required this.onTap,
  });

  static const _tileColor = Color(0xFFF4F4F4);

  final InterestCategory category;
  final bool selected;
  final bool saving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _tileColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppTheme.figmaYellow : _tileColor,
                  width: 2,
                ),
              ),
              child: saving
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.figmaYellow,
                        ),
                      ),
                    )
                  // 테두리(2px) 안쪽에서도 Figma 좌표 그대로 보이도록 64x64로 그린다.
                  : OverflowBox(
                      maxWidth: 64,
                      maxHeight: 64,
                      child: SvgPicture.asset(
                        'assets/figma/category/${category.id}.svg',
                        width: 64,
                        height: 64,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              // Figma 표기는 '용돈/지출관리'처럼 슬래시를 쓴다.
              category.name.replaceAll('&', '/'),
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
