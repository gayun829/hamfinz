import 'package:flutter/material.dart';

import '../../data/interest_categories.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// 회원가입 직후 관심 카테고리를 고르는 화면.
///
/// 카테고리 목록은 [kInterestCategories]를 사용한다. 나중에 "관심 카테고리 위주로
/// 일일 퀴즈 출제" 같은 기능을 붙일 때 `question.category.name`과 바로 비교할 수 있다.
class CategorySelectScreen extends StatefulWidget {
  const CategorySelectScreen({super.key});

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  final Set<String> _selected = {};
  bool _saving = false;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _complete() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _saving = true);

    await AuthService.instance.saveInterestCategories(_selected.toList());

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // 가입이 이미 완료된 상태이므로 뒤로가기로 회원가입 폼에 돌아가지 않게 막는다.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('관심 카테고리'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '어떤 금융 주제가 궁금하세요?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '선택한 주제를 중심으로 퀴즈를 추천해드려요. (복수 선택 가능)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: kInterestCategories.length,
                        itemBuilder: (context, index) {
                          final item = kInterestCategories[index];
                          return _CategoryCard(
                            item: item,
                            selected: _selected.contains(item.id),
                            onTap: () => _toggle(item.id),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selected.isEmpty
                          ? '1개 이상 선택해주세요'
                          : '${_selected.length}개 선택됨',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          _selected.isEmpty || _saving ? null : _complete,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('햄핀즈 시작하기'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final InterestCategory item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withValues(alpha: 0.10)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: selected ? 1 : 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 38)),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.name,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
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
