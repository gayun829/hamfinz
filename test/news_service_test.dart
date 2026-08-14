import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/services/news_service.dart';

const _sampleRss = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel>
<title>"예금" - Google 뉴스</title>
<item><title>기준금리 인하에 예금 &amp; 적금 금리 &#39;뚝&#39; - 한국경제</title>
<link>https://news.google.com/rss/articles/AAA?oc=5</link>
<description><![CDATA[<a href="https://x">기사</a>]]></description>
<source url="https://hankyung.com">한국경제</source></item>
<item><title>2위 기사 제목 - 매일경제</title><link>https://news.google.com/rss/articles/BBB</link>
<source url="https://mk.co.kr">매일경제</source></item>
<item><title>3위 - 제목에 하이픈 있음 - Chosunbiz</title><link>https://news.google.com/rss/articles/CCC</link>
<source url="https://biz.chosun.com">Chosunbiz</source></item>
<item><title>4위 기사 제목 - 중앙일보</title><link>https://news.google.com/rss/articles/DDD</link></item>
</channel></rss>
''';

void main() {
  test('RSS에서 상위 3건의 제목/링크를 뽑는다', () {
    final items = NewsService.parseRss(_sampleRss);

    expect(items.length, 3);
    // 채널 <title>은 무시하고, HTML 엔티티는 풀고, <source>와 같은 꼬리만 떼어낸다.
    expect(items.first.title, "기준금리 인하에 예금 & 적금 금리 '뚝'");
    expect(items.first.url, 'https://news.google.com/rss/articles/AAA?oc=5');
    // 제목 안의 하이픈은 건드리지 않고 언론사 꼬리만 잘라야 한다.
    expect(items.last.title, '3위 - 제목에 하이픈 있음');
  });

  test('6개 카테고리 모두 검색 질의를 갖는다', () {
    expect(NewsService.categoryQueries.length, 6);
  });

  test('더보기는 같은 질의의 구글뉴스 검색 페이지를 가리킨다', () {
    final uri = NewsService.searchPageFor('saving')!;

    expect(uri.host, 'news.google.com');
    expect(uri.path, '/search');
    expect(uri.queryParameters['q'], NewsService.categoryQueries['saving']);
    expect(NewsService.searchPageFor('없는카테고리'), isNull);
  });
}
