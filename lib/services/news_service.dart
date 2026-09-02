import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../data/finance_terms.dart';

/// 뉴스 한 건. 제목 + 원문 링크 + 제목에서 잡힌 금융 용어 + 출처/시각.
class NewsItem {
  const NewsItem({
    required this.title,
    required this.url,
    required this.term,
    this.source = '',
    this.publishedAt,
  });

  final String title;
  final String url;

  /// 제목에 들어 있던 금융 용어. 이게 있어야 학습으로 이어갈 수 있어서,
  /// 목록에 올리는 기사는 전부 값이 있다.
  final FinanceTerm term;

  /// 언론사명(`<source>`). 제목 꼬리를 떼는 데 쓰고 버리던 값이라 그냥 들고 있는다.
  final String source;

  /// `<pubDate>`. 형식이 깨졌으면 null이고, 그때는 화면에서 시각을 안 띄운다.
  final DateTime? publishedAt;

  /// '3시간 전'처럼 사람이 읽는 상대 시각. 시각이 없으면 빈 문자열.
  String get relativeTime {
    final at = publishedAt;
    if (at == null) return '';
    final gap = DateTime.now().toUtc().difference(at.toUtc());
    if (gap.isNegative || gap.inMinutes < 1) return '방금';
    if (gap.inMinutes < 60) return '${gap.inMinutes}분 전';
    if (gap.inHours < 24) return '${gap.inHours}시간 전';
    return '${gap.inDays}일 전';
  }
}

/// 구글뉴스 비즈니스 헤드라인에서 **금융 용어가 걸린 기사 TOP N**을 뽑는다.
///
/// 순서는 구글이 매긴 헤드라인 순위를 그대로 쓴다. RSS에는 조회수가 없다 —
/// item이 주는 건 `title / link / source / pubDate / guid / description`뿐이라,
/// "조회수 TOP 10"은 이 소스로 만들 수 없다.
class NewsService {
  NewsService._();

  /// 비즈니스 토픽 헤드라인. 검색 질의가 아니라 구글이 고른 주요 뉴스 묶음이라,
  /// 넓은 검색어(`금융 OR 경제`)보다 큰 기사가 위로 온다.
  static Uri get _feedUri => Uri.https(
    'news.google.com',
    '/rss/headlines/section/topic/BUSINESS',
    const {'hl': 'ko', 'gl': 'KR', 'ceid': 'KR:ko'},
  );

  /// '더보기'용 사람이 보는 페이지. 같은 비즈니스 섹션이라 목록이 이어진다.
  static Uri get morePageUri => Uri.https(
    'news.google.com',
    '/headlines/section/topic/BUSINESS',
    const {'hl': 'ko', 'gl': 'KR', 'ceid': 'KR:ko'},
  );

  /// 웹으로 띄웠을 때만 쓰는 우회로. 브라우저는 구글뉴스 응답에 CORS 헤더가
  /// 없어서 막아버린다. 기본값은 로컬 `dart run tool/cors_proxy.dart`이고,
  /// 다른 주소를 쓰려면 `--dart-define=NEWS_PROXY=...`로 덮어쓴다.
  /// 모바일/데스크톱 빌드는 CORS가 없으므로 구글뉴스를 그대로 호출한다.
  static const _definedProxy = String.fromEnvironment('NEWS_PROXY');
  static String get _proxy => _definedProxy.isNotEmpty
      ? _definedProxy
      : (kIsWeb ? 'http://localhost:8766?url=' : '');

  /// 목록 갱신 주기.
  ///
  /// 피드 70건의 기사 나이 중앙값이 약 19시간이고 1시간 이내 신규는 3건 남짓이다.
  /// 용어 필터 통과율(약 24%)을 곱하면 목록에 새로 들어오는 건 시간당 1건 꼴 —
  /// 더 짧게 잡으면 대부분 같은 목록을 다시 받아온다.
  static const refreshInterval = Duration(hours: 1);

  static List<NewsItem>? _cache;
  static DateTime? _cachedAt;

  /// 마지막으로 받아온 시각. 목록 위에 '방금 업데이트'를 띄우는 데 쓴다.
  static DateTime? get cachedAt => _cachedAt;

  /// 마지막으로 받아온 지 [refreshInterval]이 지났는지.
  static bool get isStale {
    final at = _cachedAt;
    return at == null || DateTime.now().difference(at) >= refreshInterval;
  }

  /// 캐시가 살아 있으면 그대로 준다. [force]는 당겨서 새로고침할 때만 쓴다.
  static Future<List<NewsItem>> topFinance({
    int limit = 10,
    bool force = false,
  }) async {
    final cached = _cache;
    if (!force && cached != null && !isStale) return cached;

    try {
      final items = await _fetch(limit);
      _cache = items;
      _cachedAt = DateTime.now();
      return items;
    } catch (_) {
      // 갱신에 실패했다고 이미 보여주던 목록을 지울 이유는 없다.
      // 첫 로딩이라 캐시가 아예 없을 때만 화면에 오류를 띄운다.
      if (cached != null) return cached;
      rethrow;
    }
  }

  static Future<List<NewsItem>> _fetch(int limit) async {
    final target = _proxy.isEmpty
        ? _feedUri
        : Uri.parse(_proxy).replace(
            queryParameters: {'url': _feedUri.toString()},
          );

    http.Response res;
    try {
      res = await http.get(target).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 500) {
        throw Exception('구글뉴스 응답 오류 (${res.statusCode})');
      }
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
  static final _sourcePattern = RegExp(
    r'<source[^>]*>(.*?)</source>',
    dotAll: true,
  );
  static final _datePattern = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true);

  /// RFC 822 `Tue, 02 Sep 2025 01:23:00 GMT`를 읽는다.
  /// `HttpDate.parse`는 dart:io라 웹 빌드에서 못 쓴다.
  static final _rfc822 = RegExp(
    r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})',
  );
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static DateTime? parsePubDate(String? raw) {
    if (raw == null) return null;
    final m = _rfc822.firstMatch(raw);
    if (m == null) return null;
    final month = _months.indexOf(m.group(2)!) + 1;
    if (month == 0) return null;
    return DateTime.utc(
      int.parse(m.group(3)!),
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
  }

  /// RSS에서 **금융 용어가 걸린** 기사만 상위 [limit]건 뽑는다.
  /// 용어가 없는 기사는 학습으로 이어갈 수 없어서 목록에 올리지 않는다.
  static List<NewsItem> parseRss(String xml, {int limit = 10}) {
    final items = <NewsItem>[];

    for (final match in _itemPattern.allMatches(xml)) {
      if (items.length >= limit) break;

      final block = match.group(1)!;
      final rawTitle = _titlePattern.firstMatch(block)?.group(1);
      final rawLink = _linkPattern.firstMatch(block)?.group(1);
      if (rawTitle == null || rawLink == null) continue;

      // 구글뉴스 제목은 "기사 제목 - 언론사" 형태고, 그 언론사명이 <source>에 그대로
      // 들어있다. 문자열로 자르지 말고 <source> 값과 일치하는 꼬리만 정확히 떼어낸다.
      final rawSource = _sourcePattern.firstMatch(block)?.group(1);
      final source = rawSource == null ? '' : _unescape(rawSource).trim();
      var title = _unescape(rawTitle).trim();
      if (source.isNotEmpty) {
        final suffix = ' - $source';
        if (title.endsWith(suffix)) {
          title = title.substring(0, title.length - suffix.length).trim();
        }
      }

      final url = _unescape(rawLink).trim();
      if (title.isEmpty || url.isEmpty) continue;

      final term = matchFinanceTerm(title);
      if (term == null) continue;

      items.add(
        NewsItem(
          title: title,
          url: url,
          term: term,
          source: source,
          publishedAt: parsePubDate(_datePattern.firstMatch(block)?.group(1)),
        ),
      );
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
