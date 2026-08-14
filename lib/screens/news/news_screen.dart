import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/interest_categories.dart';
import '../../services/news_service.dart';
import '../../theme/app_theme.dart';

/// 하단 네비 첫 번째 탭. 6개 관심 주제별로 인기 뉴스 1·2·3위를 보여준다.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<_Section>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// 카테고리별로 따로 잡아서, 한 주제가 실패해도 나머지는 그대로 보이게 한다.
  Future<List<_Section>> _load() {
    return Future.wait(
      kInterestCategories.map((category) async {
        try {
          return _Section(category, await NewsService.topFor(category.id));
        } catch (_) {
          return _Section(category, const [], failed: true);
        }
      }),
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _open(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('뉴스 페이지를 열지 못했어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.figmaHomeBackground,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<_Section>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final sections = snapshot.data ?? const <_Section>[];
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const Text(
                    '오늘의 금융 뉴스',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '주제별 인기 뉴스 TOP 3',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  for (final section in sections) ...[
                    _SectionCard(section: section, onOpen: _open),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section {
  const _Section(this.category, this.items, {this.failed = false});

  final InterestCategory category;
  final List<NewsItem> items;
  final bool failed;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onOpen});

  final _Section section;
  final ValueChanged<Uri> onOpen;

  @override
  Widget build(BuildContext context) {
    final more = NewsService.searchPageFor(section.category.id);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.figmaMintLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${section.category.emoji} ${section.category.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.figmaTeal,
            ),
          ),
          const SizedBox(height: 8),
          if (section.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                section.failed ? '뉴스를 불러오지 못했어요.' : '표시할 뉴스가 없어요.',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            for (var i = 0; i < section.items.length; i++)
              _NewsRow(
                rank: i + 1,
                item: section.items[i],
                onTap: () => onOpen(Uri.parse(section.items[i].url)),
              ),
          if (more != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onOpen(more),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.figmaTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('더보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.rank, required this.item, required this.onTap});

  final int rank;
  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank == 1 ? AppTheme.figmaOrange : AppTheme.figmaMintDeep,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
