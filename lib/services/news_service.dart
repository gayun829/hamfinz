import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// 뉴스 한 건. 제목 한 줄 + 원문 링크.
class NewsItem {
  const NewsItem({required this.title, required this.url});

  final String title;
  final String url;
}

/// 관심 카테고리별 구글뉴스 RSS 검색.
///
/// API 키가 필요 없고, 검색 결과가 관련도(=인기) 순으로 내려오므로
/// 앞에서 3개만 잘라 쓰면 그대로 1·2·3순위가 된다.
class NewsService {
  NewsService._();

  /// 카테고리 id -> 구글뉴스 검색 질의.
  /// `when:7d`로 최근 일주일 기사만 잡아서 오래된 기사가 상위에 남지 않게 한다.
  static const Map<String, String> categoryQueries = {
    'allowance': '용돈 OR 생활비 OR 소비습관 when:7d',
    'saving': '예금 OR 적금 OR 저축 금리 when:7d',
    'stock': '주식 OR 증시 OR 투자 when:7d',
    'insurance': '보험 when:7d',
    'tax': '세금 OR 연말정산 OR 소득공제 when:7d',
    'credit': '신용점수 OR 대출 when:7d',
  };

  /// 웹으로 띄웠을 때만 쓰는 우회로. 브라우저는 구글뉴스 응답에 CORS 헤더가
  /// 없어서 막아버린다. `--dart-define=NEWS_PROXY=...`로 직접 지정하지 않으면
  /// (예: 로컬 `tool/cors_proxy.dart`) 웹에서는 공개 CORS 프록시로 자동 우회하고,
  /// 모바일/데스크톱 빌드는 구글뉴스를 그대로 호출한다.
  static const _definedProxy = String.fromEnvironment('NEWS_PROXY');
  static String get _proxy =>
      _definedProxy.isNotEmpty ? _definedProxy : (kIsWeb ? 'https://corsproxy.io/?url=' : '');

  /// '더보기'용 구글뉴스 검색 결과 페이지. RSS와 같은 질의라 목록도 같은 순서로 이어진다.
  /// 사람이 보는 페이지라 프록시를 태우지 않는다.
  static Uri? searchPageFor(String categoryId) {
    final query = categoryQueries[categoryId];
    if (query == null) return null;
    return Uri.https('news.google.com', '/search', {
      'q': query,
      'hl': 'ko',
      'gl': 'KR',
      'ceid': 'KR:ko',
    });
  }

  static Future<List<NewsItem>> topFor(String categoryId, {int limit = 3}) async {
    final query = categoryQueries[categoryId];
    if (query == null) return const [];

    final uri = Uri.https('news.google.com', '/rss/search', {
      'q': query,
      'hl': 'ko',
      'gl': 'KR',
      'ceid': 'KR:ko',
    });
    final target = _proxy.isEmpty
        ? uri
        : Uri.parse(_proxy).replace(queryParameters: {'url': uri.toString()});

    // 무료 공개 프록시는 6개 카테고리를 동시에 때리면 순간 과부하로 502/503을
    // 뱉을 때가 있다. 그런 일시 오류만 한 번 재시도한다.
    http.Response res;
    try {
      res = await http.get(target).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 500) throw Exception('구글뉴스 응답 오류 (${res.statusCode})');
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 800));
      res = await http.get(target).timeout(const Duration(seconds: 10));
    }
    if (res.statusCode != 200) {
      throw Exception('구글뉴스 응답 오류 (${res.statusCode})');
    }
    // http 패키지는 charset 헤더가 없으면 latin1로 디코딩하므로 직접 utf8로 읽는다.
    return parseRss(utf8.decode(res.bodyBytes), limit: limit);
  }

  static final _itemPattern = RegExp(r'<item>(.*?)</item>', dotAll: true);
  static final _titlePattern = RegExp(r'<title>(.*?)</title>', dotAll: true);
  static final _linkPattern = RegExp(r'<link>(.*?)</link>', dotAll: true);
  static final _sourcePattern = RegExp(r'<source[^>]*>(.*?)</source>', dotAll: true);

  /// RSS 본문에서 상위 [limit]건의 제목/링크를 뽑는다.
  static List<NewsItem> parseRss(String xml, {int limit = 3}) {
    final items = <NewsItem>[];

    for (final match in _itemPattern.allMatches(xml)) {
      if (items.length >= limit) break;

      final block = match.group(1)!;
      final rawTitle = _titlePattern.firstMatch(block)?.group(1);
      final rawLink = _linkPattern.firstMatch(block)?.group(1);
      if (rawTitle == null || rawLink == null) continue;

      // 구글뉴스 제목은 "기사 제목 - 언론사" 형태고, 그 언론사명이 <source>에 그대로
      // 들어있다. 문자열로 자르지 말고 <source> 값과 일치하는 꼬리만 정확히 떼어낸다.
      final source = _sourcePattern.firstMatch(block)?.group(1);
      var title = _unescape(rawTitle).trim();
      if (source != null && source.isNotEmpty) {
        final suffix = ' - ${_unescape(source).trim()}';
        if (title.endsWith(suffix)) {
          title = title.substring(0, title.length - suffix.length).trim();
        }
      }

      final url = _unescape(rawLink).trim();
      if (title.isEmpty || url.isEmpty) continue;

      items.add(NewsItem(title: title, url: url));
    }

    return items;
  }

  static String _unescape(String value) => value
      .replaceAll('<![CDATA[', '')
      .replaceAll(']]>', '')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
