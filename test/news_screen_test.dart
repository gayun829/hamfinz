import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:testapp/data/finance_terms.dart';
import 'package:testapp/data/interest_categories.dart';
import 'package:testapp/screens/news/news_screen.dart';

/// 제목에서 [term]이 그대로 잡히는 기사 제목. 잡히지 않으면 테스트 전제가 깨진 것이다.
String _titleFor(FinanceTerm term) {
  final title = '${term.term} 관련 소식';
  expect(matchFinanceTerm(title)?.term, term.term, reason: title);
  return title;
}

String _chipLabel(FinanceTerm term) =>
    '${findInterestCategory(term.categoryId)?.emoji ?? '📰'} ${term.term}';

/// 뜻이 있는 용어 3개.
///
/// [NewsService]가 목록을 캐시해서 테스트 사이에 같은 피드를 써야 한다.
final _withSummary = [
  for (final term in kFinanceTerms)
    if (term.summary.isNotEmpty &&
        matchFinanceTerm('${term.term} 관련 소식')?.term == term.term)
      term,
].take(3).toList();


String get _rss {
  final titles = _withSummary.map(_titleFor).toList();
  final items = [
    for (var i = 0; i < titles.length; i++)
      '<item><title>${titles[i]}</title><link>https://example.com/$i</link>'
          '<pubDate>Tue, 02 Sep 2025 01:23:45 GMT</pubDate></item>',
  ];
  return '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>'
      '<title>t</title>${items.join()}</channel></rss>';
}

void main() {
  Future<void> pumpNews(
    WidgetTester tester, {
    double statusBar = 0,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    tester.view.padding = FakeViewPadding(top: statusBar);
    tester.view.viewPadding = FakeViewPadding(top: statusBar);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const Scaffold(body: NewsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// [body]를 목 RSS 응답 아래에서 실행한다.
  Future<void> withFeed(Future<void> Function() body) => http.runWithClient(
    body,
    () => MockClient(
      (_) async => http.Response(
        _rss,
        200,
        headers: {'content-type': 'application/xml; charset=utf-8'},
      ),
    ),
  );

  final chipFinder = find.text(_chipLabel(_withSummary.first));
  final tipFinder = find.text(_withSummary.first.summary);

  testWidgets('기사에서 잡은 용어를 칩으로 올린다', (tester) async {
    await withFeed(() async {
      await pumpNews(tester);
      for (final term in _withSummary) {
        expect(find.text(_chipLabel(term)), findsOneWidget, reason: term.term);
      }
    });
  });

  testWidgets('칩을 누르면 뜻이 뜨고, 같은 칩을 다시 누르면 닫힌다', (tester) async {
    await withFeed(() async {
      await pumpNews(tester);
      expect(tipFinder, findsNothing);

      await tester.tap(chipFinder);
      await tester.pump();
      expect(tipFinder, findsOneWidget);

      await tester.tap(chipFinder);
      await tester.pump();
      expect(tipFinder, findsNothing);
    });
  });

  testWidgets('바깥을 누르면 말풍선이 닫힌다', (tester) async {
    await withFeed(() async {
      await pumpNews(tester);
      await tester.tap(chipFinder);
      await tester.pump();
      expect(tipFinder, findsOneWidget);

      await tester.tapAt(const Offset(200, 780));
      await tester.pump();
      expect(tipFinder, findsNothing);
    });
  });

  testWidgets('상태바 여백이 있어도 말풍선은 칩 바로 아래에 붙는다', (tester) async {
    Future<double> gapWith(double statusBar) async {
      late double gap;
      await withFeed(() async {
        await pumpNews(tester, statusBar: statusBar);
        final chipBottom = tester.getRect(chipFinder).bottom;
        await tester.tap(chipFinder);
        await tester.pump();
        gap = tester.getRect(tipFinder).top - chipBottom;
      });
      return gap;
    }

    final flat = await gapWith(0);
    final notch = await gapWith(47);
    // 여백만큼 밀리면 47px 벌어진다.
    expect(notch, closeTo(flat, 0.5));
  });

  testWidgets('목록을 밀기 시작하면 말풍선이 닫힌다', (tester) async {
    await withFeed(() async {
      await pumpNews(tester);
      await tester.tap(chipFinder);
      await tester.pump();
      expect(tipFinder, findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -60));
      await tester.pump();
      expect(tipFinder, findsNothing);
    });
  });

  testWidgets('글자를 키워도 칩 글씨가 잘리지 않는다', (tester) async {
    await withFeed(() async {
      await pumpNews(tester, textScaler: const TextScaler.linear(1.6));
      final label = tester.renderObject<RenderParagraph>(chipFinder);
      // 칩이 글씨보다 낮으면 글씨가 자기 박스보다 커서 위아래가 잘린다.
      final natural = label.getMinIntrinsicHeight(label.size.width);
      expect(label.size.height, greaterThanOrEqualTo(natural - 0.5));
      expect(tester.takeException(), isNull);
    });
  });
}
