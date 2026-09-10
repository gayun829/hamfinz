import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/interest_categories.dart';
import '../../services/news_service.dart';
import '../../theme/app_theme.dart';
import 'article_screen.dart';
import 'term_quiz_screen.dart';

/// 목록에서 기사를 여는 콜백.
typedef OpenArticle = void Function(NewsItem item);

/// 하단 네비 첫 번째 탭. 지금 가장 큰 금융 뉴스 10건을 한 줄 목록으로 보여준다.
///
/// 카테고리로 나누지 않는다. 카테고리별로 쿼리를 6번 던지면 보험·세금처럼
/// 기사가 적은 주제는 섹션이 비어버리는데, 비즈니스 헤드라인 한 번에서
/// 금융 용어가 걸린 기사만 추리면 목록이 항상 채워진다.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with WidgetsBindingObserver {
  late Future<List<NewsItem>> _future;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 탭이 IndexedStack에 물려 있어서 이 화면은 앱 실행당 한 번만 만들어진다.
    // 타이머가 없으면 앱을 켜둔 동안 목록이 영영 그대로다.
    WidgetsBinding.instance.addObserver(this);
    _future = NewsService.topFinance();
    _timer = Timer.periodic(
      NewsService.refreshInterval,
      (_) => _refreshIfStale(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 백그라운드에 있는 동안은 타이머가 밀릴 수 있어서, 돌아올 때 한 번 더 본다.
    if (state == AppLifecycleState.resumed) _refreshIfStale();
  }

  void _refreshIfStale() {
    if (!mounted || !NewsService.isStale) return;
    // 화살표 함수로 쓰면 Future를 반환해서 setState가 디버그에서 assert를 던진다.
    final future = NewsService.topFinance();
    setState(() {
      _future = future;
    });
  }

  /// 당겨서 새로고침 — 주기와 상관없이 바로 받아온다.
  Future<void> _refresh() async {
    final future = NewsService.topFinance(force: true);
    setState(() => _future = future);
    await future.catchError((_) => <NewsItem>[]);
  }

  /// 기사를 열고, 학습 내용이 있는 용어면 그 자리에서 학습으로 이어 준다.
  Future<void> _open(NewsItem item) => ArticleScreen.open(
    context,
    Uri.parse(item.url),
    item.title,
    onStartQuiz: item.term.hasLesson
        ? (_, _) => TermQuizScreen.open(context, item.term, item.title)
        : null,
  );

  Future<void> _openMore() =>
      ArticleScreen.open(context, NewsService.morePageUri, '금융 뉴스');

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.figmaHomeBackground,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<NewsItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data ?? const <NewsItem>[];
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
                  Text(
                    _subtitle(items.length),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _TermSummary(items: items),
                  ],
                  const SizedBox(height: 16),
                  _NewsCard(
                    items: items,
                    failed: snapshot.hasError,
                    onOpen: _open,
                    onOpenMore: _openMore,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _subtitle(int count) {
    if (count == 0) return '지금 가장 큰 금융 뉴스';
    final at = NewsService.cachedAt;
    if (at == null) return '지금 가장 큰 금융 뉴스 TOP $count';
    final gap = DateTime.now().difference(at);
    final when = gap.inMinutes < 1 ? '방금' : '${gap.inMinutes}분 전';
    return '지금 가장 큰 금융 뉴스 TOP $count · $when 업데이트';
  }
}

/// 오늘 목록에 걸린 금융 용어를 한 줄로 훑어 준다.
///
/// 목록은 제목만 나열해서 "오늘 뭘 배우게 되는지"가 안 보였다. 용어는 이미
/// 기사마다 붙어 있으니 중복만 걷어내면 공짜로 얻는 요약이다.
///
/// **일부러 알약/칩 모양을 안 쓴다.** 배경 깔린 둥근 조각은 눌러 보게 생겼는데
/// 여긴 누를 게 없다. 부제와 같은 회색 본문으로 둬야 읽고 넘어간다.
class _TermSummary extends StatelessWidget {
  const _TermSummary({required this.items});

  final List<NewsItem> items;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final labels = [
      for (final item in items)
        if (seen.add(item.term.term))
          '${_emoji(item.term.categoryId)} ${item.term.term}',
    ];

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: '오늘의 용어  ',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: labels.join('  ·  ')),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        height: 1.5,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

String _emoji(String categoryId) =>
    findInterestCategory(categoryId)?.emoji ?? '📰';

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.items,
    required this.failed,
    required this.onOpen,
    required this.onOpenMore,
  });

  final List<NewsItem> items;
  final bool failed;
  final OpenArticle onOpen;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
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
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                failed ? '뉴스를 불러오지 못했어요.' : '표시할 뉴스가 없어요.',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppTheme.figmaMintLight),
              _NewsRow(
                rank: i + 1,
                item: items[i],
                onTap: () => onOpen(items[i]),
              ),
            ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenMore,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.figmaTeal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '더보기',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
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
    // 언론사·시각은 RSS가 주는데 그동안 버리고 있었다. 있는 걸 쓰면 한 줄이 채워진다.
    final meta = [
      '${_emoji(item.term.categoryId)} ${item.term.term}',
      if (item.source.isNotEmpty) item.source,
      if (item.relativeTime.isNotEmpty) item.relativeTime,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // 상위 3건만 주황. 하나만 칠하면 나머지 9줄이 다 똑같아 보인다.
                color: rank <= 3 ? AppTheme.figmaOrange : AppTheme.figmaMintDeep,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: rank <= 3
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _Thumbnail(item: item),
          ],
        ),
      ),
    );
  }
}

/// 기사 대표 사진. 연합뉴스 RSS의 `<media:content>`를 그대로 쓴다.
///
/// 사진이 없거나(속보·표 기사) 못 받아오면 같은 크기 자리에 용어 이모지를 띄워서
/// 열 줄의 오른쪽 세로선이 흔들리지 않게 한다.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final NewsItem item;

  static const _width = 76.0;
  static const _height = 56.0;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _width,
        height: _height,
        child: url == null
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                // 사진 크기가 제각각이라 목록 폭에 맞춰 줄여 받아 메모리를 아낀다.
                cacheWidth: (_width * 3).round(),
                errorBuilder: (_, _, _) => _placeholder(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => ColoredBox(
    color: AppTheme.figmaMintLight,
    child: Center(
      child: Text(
        _emoji(item.term.categoryId),
        style: const TextStyle(fontSize: 22),
      ),
    ),
  );
}
