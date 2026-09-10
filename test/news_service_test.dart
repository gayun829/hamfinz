import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/finance_terms.dart';
import 'package:testapp/services/news_service.dart';

const _sampleRss = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel>
<title>비즈니스 - Google 뉴스</title>
<item><title>기준금리 인하에 예금 &amp; 적금 금리 &#39;뚝&#39; - 한국경제</title>
<link>https://news.google.com/rss/articles/AAA?oc=5</link>
<pubDate>Tue, 02 Sep 2025 01:23:45 GMT</pubDate>
<description><![CDATA[<a href="https://x">기사</a>]]></description>
<source url="https://hankyung.com">한국경제</source></item>
<item><title>메디포스트, 삼성바이오 출신 대표 영입 - 매일경제</title><link>https://news.google.com/rss/articles/BBB</link>
<source url="https://mk.co.kr">매일경제</source></item>
<item><title>주택담보대출 - 갈아타기 수요 급증 - Chosunbiz</title><link>https://news.google.com/rss/articles/CCC</link>
<source url="https://biz.chosun.com">Chosunbiz</source></item>
<item><title>8월 반도체 수출 역대 최대 - 중앙일보</title><link>https://news.google.com/rss/articles/DDD</link>
<source url="https://joongang.co.kr">중앙일보</source></item>
</channel></rss>
''';

void main() {
  test('금융 용어가 걸린 기사만 남기고 나머지는 버린다', () {
    final items = NewsService.parseRss(_sampleRss);

    // 4건 중 기업 인사·반도체 수출 기사는 학습 소재가 아니라 빠진다.
    expect(items.length, 2);
    // 채널 <title>은 무시하고, HTML 엔티티는 풀고, <source>와 같은 꼬리만 떼어낸다.
    expect(items.first.title, "기준금리 인하에 예금 & 적금 금리 '뚝'");
    expect(items.first.url, 'https://news.google.com/rss/articles/AAA?oc=5');
    // 제목 안의 하이픈은 건드리지 않고 언론사 꼬리만 잘라야 한다.
    expect(items.last.title, '주택담보대출 - 갈아타기 수요 급증');
    // 언론사와 발행 시각도 같이 들고 온다 — 목록 두 번째 줄에 쓴다.
    expect(items.first.source, '한국경제');
    expect(items.first.publishedAt, DateTime.utc(2025, 9, 2, 1, 23, 45));
    // pubDate가 없는 기사는 시각을 비워 두고, 화면에서도 안 띄운다.
    expect(items.last.publishedAt, isNull);
    expect(items.last.relativeTime, '');
  });

  test('연합뉴스 피드: <source> 없는 기사는 연합뉴스로, 사진과 +0900 시각을 읽는다', () {
    const yna = '''
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"><channel>
<item>
  <title><![CDATA[국고채 금리 대체로 상승…3년물 연 3.930%]]></title>
  <link>https://www.yna.co.kr/view/AKR1</link>
  <pubDate>Thu, 10 Sep 2026 19:21:09 +0900</pubDate>
  <description><![CDATA[(서울=연합뉴스) ...]]></description>
  <media:content url="https://img.yna.co.kr/photo/a.jpg" type="image/jpeg"></media:content>
  <media:content url="https://img.yna.co.kr/photo/b.jpg" type="image/jpeg"></media:content>
</item>
<item>
  <title><![CDATA[환율 3.1원 오른 1,339.2원]]></title>
  <link>https://www.yna.co.kr/view/AKR2</link>
  <pubDate>Thu, 10 Sep 2026 19:00:00 +0900</pubDate>
</item>
</channel></rss>
''';
    final items = NewsService.parseRss(yna);

    expect(items.length, 2);
    expect(items.first.source, '연합뉴스');
    // 제목에 " - 언론사" 꼬리가 없으니 그대로 둔다.
    expect(items.first.title, '국고채 금리 대체로 상승…3년물 연 3.930%');
    // 첫 사진만 쓴다.
    expect(items.first.imageUrl, 'https://img.yna.co.kr/photo/a.jpg');
    // +0900은 UTC로 환산한다.
    expect(items.first.publishedAt, DateTime.utc(2026, 9, 10, 10, 21, 9));
    // 사진이 없는 기사는 null — 화면에서 이모지 자리로 대체한다.
    expect(items.last.imageUrl, isNull);
  });

  test('RFC 822 pubDate를 읽고 깨진 값은 버린다', () {
    // HttpDate.parse는 dart:io라 웹 빌드에서 못 써서 직접 읽는다.
    expect(
      NewsService.parsePubDate('Tue, 02 Sep 2025 01:23:45 GMT'),
      DateTime.utc(2025, 9, 2, 1, 23, 45),
    );
    expect(NewsService.parsePubDate('Mon, 9 Jun 2025 23:00:00 GMT'),
        DateTime.utc(2025, 6, 9, 23));
    expect(NewsService.parsePubDate('Thu, 10 Sep 2026 19:21:09 +0900'),
        DateTime.utc(2026, 9, 10, 10, 21, 9));
    expect(NewsService.parsePubDate('Thu, 10 Sep 2026 01:00:00 -0500'),
        DateTime.utc(2026, 9, 10, 6));
    expect(NewsService.parsePubDate('Tue, 02 Xyz 2025 01:23:45 GMT'), isNull);
    expect(NewsService.parsePubDate('어제'), isNull);
    expect(NewsService.parsePubDate(null), isNull);
  });

  test('상대 시각은 분·시간·일로 끊어 준다', () {
    NewsItem at(Duration ago) => NewsItem(
          title: 't',
          url: 'u',
          term: kFinanceTerms.first,
          publishedAt: DateTime.now().toUtc().subtract(ago),
        );

    expect(at(const Duration(seconds: 20)).relativeTime, '방금');
    expect(at(const Duration(minutes: 5)).relativeTime, '5분 전');
    expect(at(const Duration(hours: 3)).relativeTime, '3시간 전');
    expect(at(const Duration(days: 2)).relativeTime, '2일 전');
  });

  test('제목에서 가장 긴 용어를 고른다', () {
    // '주택담보대출'이 걸렸는데 '대출'로 가르치면 기사와 어긋난다.
    expect(matchFinanceTerm('주택담보대출 갈아타기 급증')?.term, '주택담보대출');
    expect(matchFinanceTerm('소비자물가 3.1% 상승')?.term, '소비자물가');
    expect(matchFinanceTerm('메디포스트, 신임 대표 영입'), isNull);
  });

  test('용어마다 실재하는 관심 카테고리 id가 붙어 있다', () {
    const validIds = {
      'allowance',
      'saving',
      'stock',
      'insurance',
      'tax',
      'credit',
    };
    for (final term in kFinanceTerms) {
      expect(validIds.contains(term.categoryId), isTrue, reason: term.term);
    }
  });

  test('더보기는 같은 연합뉴스 경제 섹션 페이지를 가리킨다', () {
    final uri = NewsService.morePageUri;

    expect(uri.host, 'www.yna.co.kr');
    expect(uri.path, '/economy/all');
  });

  test('학습이 붙은 용어는 OX 2문제와 해설을 다 갖고 있다', () {
    final lessons = kFinanceTerms.where((t) => t.hasLesson).toList();
    // 자주 걸리는 용어부터 채운다. 하나도 없으면 뉴스 학습이 통째로 안 뜬다.
    expect(lessons.length, greaterThanOrEqualTo(10));

    for (final term in lessons) {
      expect(term.summary.trim(), isNotEmpty, reason: term.term);
      expect(term.forMe.trim(), isNotEmpty, reason: term.term);
      expect(term.quiz.length, 2, reason: term.term);
      for (final q in term.quiz) {
        expect(q.statement.trim(), isNotEmpty, reason: term.term);
        // 해설이 없으면 틀려도 왜 틀렸는지를 못 알려준다.
        expect(q.why.trim(), isNotEmpty, reason: term.term);
      }
      // O만 둘, X만 둘이면 찍어서 맞는다.
      expect(term.quiz.map((q) => q.answer).toSet().length, 2,
          reason: term.term);
    }
  });

  test('설명이 없는 용어는 학습으로 안 이어진다', () {
    final bare = kFinanceTerms.firstWhere((t) => t.quiz.isEmpty);
    expect(bare.hasLesson, isFalse);
  });
}