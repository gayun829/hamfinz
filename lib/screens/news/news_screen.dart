import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/finance_terms.dart';
import '../../data/interest_categories.dart';
import '../../services/news_service.dart';
import '../../theme/app_theme.dart';
import 'article_screen.dart';
import 'term_quiz_screen.dart';

/// 목록에서 기사를 여는 콜백.
typedef OpenArticle = void Function(NewsItem item);

// Figma `뉴스화면` 393폭 프레임 값.
const _bg = Color(0xFFFBFBFB);
const _headerBlue = Color(0xFF3CC6FF);
const _rowDivider = Color(0xFFE8E8E8);
const _thumbWidth = 132.0;
const _thumbHeight = 88.0;
const _pagePad = 20.0;

/// 용어 칩 팔레트. 카테고리가 아니라 **줄에 놓인 순서**대로 돈다 —
/// Figma에서 코스피와 ETF가 같은 주식 카테고리인데 색이 다르다.
const _chipPalette = [
  (Color(0xFFDCEBFB), Color(0xFFAFD3F2)),
  (Color(0xFFE0F3DC), Color(0xFFB6E0AE)),
  (Color(0xFFFCE3D8), Color(0xFFF4BFA6)),
  (Color(0xFFF1E4FB), Color(0xFFD3B6EC)),
];

/// 하단 네비 첫 번째 탭. 지금 가장 큰 금융 뉴스 10건을 사진과 함께 보여준다.
///
/// 카테고리로 나누지 않는다. 카테고리별로 쿼리를 6번 던지면 보험·세금처럼
/// 기사가 적은 주제는 섹션이 비어버리는데, 경제 피드 한 번에서 금융 용어가
/// 걸린 기사만 추리면 목록이 항상 채워진다.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with WidgetsBindingObserver {
  late Future<List<NewsItem>> _future;
  Timer? _timer;

  /// 지금 말풍선이 떠 있는 용어. null이면 아무것도 안 떠 있다.
  FinanceTerm? _tipTerm;

  /// 말풍선이 가리킬 칩의 위치. 칩을 누를 때 재 두고, 말풍선 층([_stackKey])의
  /// 좌표로 바꿔 둔다.
  Rect? _tipAnchor;

  /// 말풍선 층의 좌표계. SafeArea 안쪽 Stack이라 화면 좌표와 위쪽 여백만큼 다르다.
  final _stackKey = GlobalKey();

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
    setState(() {
      _future = future;
      _tipTerm = null;
    });
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

  void _toggleTip(FinanceTerm term, Rect globalAnchor) {
    // 칩은 화면 좌표(localToGlobal)로 알려 준다. 말풍선은 SafeArea 안쪽 Stack에
    // 그려서, 그대로 쓰면 상태바 여백만큼 아래로 밀린다.
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final anchor = stack == null
        ? globalAnchor
        : stack.globalToLocal(globalAnchor.topLeft) & globalAnchor.size;
    setState(() {
      final same = _tipTerm?.term == term.term;
      _tipTerm = same ? null : term;
      _tipAnchor = same ? null : anchor;
    });
  }

  void _closeTip() {
    if (!mounted || _tipTerm == null) return;
    setState(() => _tipTerm = null);
  }

  /// 회전·키보드로 화면 크기가 바뀌면 재 둔 칩 위치가 맞지 않는다.
  @override
  void didChangeMetrics() => _closeTip();

  @override
  Widget build(BuildContext context) {
    final tipTerm = _tipTerm;
    final tipAnchor = _tipAnchor;

    return ColoredBox(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Stack(
          key: _stackKey,
          children: [
            Column(
              children: [
                const _NewsHeader(),
                Expanded(
                  // 재 둔 위치에 떠 있는 말풍선은 스크롤하면 칩과 어긋난다.
                  // 세로 목록이든 가로 칩 줄이든 밀기 시작하면 닫는다.
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: (_) {
                      _closeTip();
                      return false;
                    },
                    child: FutureBuilder<List<NewsItem>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: _buildList(
                            snapshot.data ?? const <NewsItem>[],
                            snapshot.hasError,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // 말풍선은 목록 위에 떠야 해서 화면 맨 위 층에 그린다.
            if (tipTerm != null && tipAnchor != null)
              _TermTooltipLayer(
                term: tipTerm,
                anchor: tipAnchor,
                onDismiss: _closeTip,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<NewsItem> items, bool failed) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: _pagePad),
          child: Text(
            '오늘의 금융 뉴스',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pagePad),
          child: Text(
            _subtitle(items.length),
            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(_pagePad, 20, _pagePad, 0),
            child: Text(
              failed ? '뉴스를 불러오지 못했어요.' : '표시할 뉴스가 없어요.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          )
        else ...[
          const SizedBox(height: 14),
          _TermChips(items: items, onTap: _toggleTip, selected: _tipTerm),
          const SizedBox(height: 6),
          for (final item in items) ...[
            const Divider(height: 1, thickness: 1, color: _rowDivider),
            _NewsRow(item: item, onTap: () => _open(item)),
          ],
          const Divider(height: 1, thickness: 1, color: _rowDivider),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: _pagePad - 8, top: 4),
              child: TextButton(
                onPressed: _openMore,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.figmaTeal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '더보기',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _subtitle(int count) {
    if (count == 0) return '지금 가장 핫한 금융 뉴스';
    final at = NewsService.cachedAt;
    if (at == null) return '지금 가장 핫한 금융 뉴스 TOP $count';
    final gap = DateTime.now().difference(at);
    final when = gap.inMinutes < 1 ? '방금' : '${gap.inMinutes}분 전';
    return '지금 가장 핫한 금융 뉴스 TOP $count · $when 업데이트';
  }
}

/// 하늘색 머리띠. 가운데 「햄뉴스」.
class _NewsHeader extends StatelessWidget {
  const _NewsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 59,
      alignment: Alignment.center,
      color: _headerBlue,
      child: const Text(
        '햄뉴스',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// 오늘 목록에 걸린 용어를 칩으로 훑어 준다. 누르면 뜻이 말풍선으로 뜬다.
class _TermChips extends StatelessWidget {
  const _TermChips({
    required this.items,
    required this.onTap,
    required this.selected,
  });

  final List<NewsItem> items;
  final void Function(FinanceTerm term, Rect anchor) onTap;
  final FinanceTerm? selected;

  @override
  Widget build(BuildContext context) {
    // 뜻이 있는 용어만 올린다. 눌렀는데 말풍선이 비면 안 누른 것만 못하다.
    final seen = <String>{};
    final terms = [
      for (final item in items)
        if (item.term.summary.isNotEmpty && seen.add(item.term.term)) item.term,
    ];
    if (terms.isEmpty) return const SizedBox.shrink();

    // 칩 안 글씨가 커지면 칩도 커진다. 높이를 32로 못 박으면 위아래가 잘린다.
    final textScale = MediaQuery.textScalerOf(context).scale(13) / 13;
    return SizedBox(
      height: 32 * (textScale < 1 ? 1.0 : textScale),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _pagePad),
        itemCount: terms.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 2),
                child: Text(
                  '오늘의 용어',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }
          final term = terms[index - 1];
          return _TermChip(
            term: term,
            palette: _chipPalette[(index - 1) % _chipPalette.length],
            active: selected?.term == term.term,
            onTap: onTap,
          );
        },
      ),
    );
  }
}

class _TermChip extends StatefulWidget {
  const _TermChip({
    required this.term,
    required this.palette,
    required this.active,
    required this.onTap,
  });

  final FinanceTerm term;
  final (Color, Color) palette;
  final bool active;
  final void Function(FinanceTerm term, Rect anchor) onTap;

  @override
  State<_TermChip> createState() => _TermChipState();
}

class _TermChipState extends State<_TermChip> {
  final _key = GlobalKey();

  void _handleTap() {
    // 말풍선 꼬리를 칩 아래에 맞추려면 눌린 칩의 화면 좌표가 필요하다.
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    widget.onTap(widget.term, box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        key: _key,
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.palette.$1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.palette.$2,
              width: widget.active ? 1.4 : 1,
            ),
          ),
          child: Text(
            '${_emoji(widget.term.categoryId)} ${widget.term.term}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 칩 아래에 붙는 말풍선. 바깥을 누르면 닫힌다.
class _TermTooltipLayer extends StatelessWidget {
  const _TermTooltipLayer({
    required this.term,
    required this.anchor,
    required this.onDismiss,
  });

  final FinanceTerm term;
  final Rect anchor;
  final VoidCallback onDismiss;

  static const _tailWidth = 18.0;
  static const _tailHeight = 9.0;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // [anchor]와 같은 좌표계(이 층)의 폭을 쓴다. 화면 폭과 다를 수 있다.
      child: LayoutBuilder(
        builder: (context, constraints) => _bubble(constraints.maxWidth),
      ),
    );
  }

  Widget _bubble(double screen) {
    // 칩 왼쪽에 맞춰 열되, 오른쪽이 화면 밖으로 나가면 끌어당긴다.
    final width = (screen - _pagePad * 2).clamp(0.0, 300.0);
    final maxLeft = screen - _pagePad - width;
    final left = (anchor.left - 8).clamp(
      _pagePad,
      maxLeft < _pagePad ? _pagePad : maxLeft,
    );
    final tailCenter = (anchor.center.dx - left).clamp(
      _tailWidth,
      width - _tailWidth,
    );

    return Stack(
      children: [
        // 바깥 아무 데나 누르면 닫힌다. 목록 스크롤을 막지 않게 탭만 잡는다.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        Positioned(
          left: left,
          top: anchor.bottom + 6,
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: tailCenter - _tailWidth / 2),
                child: CustomPaint(
                  size: const Size(_tailWidth, _tailHeight),
                  painter: _TailPainter(),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  term.summary,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE2E2E2));
    // 테두리 위에 흰 삼각형을 덮어 말풍선과 이어 붙인다.
    final inner = Path()
      ..moveTo(size.width / 2, 1.8)
      ..lineTo(size.width - 1.8, size.height)
      ..lineTo(1.8, size.height)
      ..close();
    canvas.drawPath(inner, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 기사 한 줄 — 왼쪽 사진, 오른쪽 제목 두 줄과 출처.
class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.source.isNotEmpty) item.source,
      if (item.relativeTime.isNotEmpty) item.relativeTime,
    ].join('  ·  ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _pagePad,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(item: item),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }
}

String _emoji(String categoryId) =>
    findInterestCategory(categoryId)?.emoji ?? '📰';

/// 기사 대표 사진. 연합뉴스 RSS의 `<media:content>`를 그대로 쓴다.
///
/// 사진이 없거나(속보·표 기사) 못 받아오면 같은 크기 자리에 용어 이모지를 띄워서
/// 목록의 왼쪽 세로선이 흔들리지 않게 한다.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _thumbWidth,
        height: _thumbHeight,
        child: url == null
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                // 사진 크기가 제각각이라 목록 폭에 맞춰 줄여 받아 메모리를 아낀다.
                cacheWidth: (_thumbWidth * 3).round(),
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
        style: const TextStyle(fontSize: 30),
      ),
    ),
  );
}
