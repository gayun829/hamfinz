import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../data/finance_terms.dart';

/// 뉴스 한 건. 제목 + 원문 링크 + 제목에서 잡힌 금융 용어 + 출처/시각 + 대표 이미지.
class NewsItem {
  const NewsItem({
    required this.title,
    required this.url,
    required this.term,
    this.source = '',
    this.publishedAt,
    this.imageUrl,
  });

  final String title;
  final String url;

  /// `<media:content url>`의 첫 사진. 없는 기사(속보·표 기사)는 null이고,
  /// 목록에서는 그 자리에 용어 이모지를 띄운다.
  final String? imageUrl;

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

/// 연합뉴스 경제 RSS에서 **금융 용어가 걸린 기사 TOP N**을 뽑는다.
///
/// 구글뉴스 비즈니스 헤드라인을 쓰다가 바꿨다. 구글 RSS는 사진이 없고 링크가
/// 리다이렉트라 사진을 얻을 길이 없는데, 연합뉴스 RSS는 기사마다
/// `<media:content>`로 사진을 주고(120건 중 9할) 링크도 기사 원문이라
/// WebView에서 바로 열린다. 순서는 피드가 준 최신순 그대로다.
/// RSS에는 조회수가 없어서 "조회수 TOP 10"은 어느 소스로도 못 만든다.
class NewsService {
  NewsService._();

  /// 연합뉴스 경제 섹션. 하루 100건 남짓 올라와서 용어 필터를 거쳐도 10건이 남는다.
  static Uri get _feedUri => Uri.https('www.yna.co.kr', '/rss/economy.xml');

  /// '더보기'용 사람이 보는 페이지. 같은 경제 섹션이라 목록이 이어진다.
  static Uri get morePageUri => Uri.https('www.yna.co.kr', '/economy/all');

  /// 피드에 `<source>`가 없을 때 쓰는 언론사명. 연합뉴스 피드는 전부 자사 기사라 태그가 없다.
  static const _defaultSource = '연합뉴스';

  /// 웹 빌드에서만 쓰는 우회로. 브라우저는 RSS 응답에 CORS 헤더가 없어서
  /// 막아버린다. `dart run tool/cors_proxy.dart`를 띄우고
  /// `--dart-define=NEWS_PROXY=http://localhost:8766`으로 넘기면 그 프록시를 쓰고,
  /// 안 넘기면 Cloud Functions `fetchNewsFeed`가 대신 받아온다(배포돼 있어야 함).
  /// 모바일/데스크톱은 CORS가 없어서 RSS를 직접 부른다.
  static const _definedProxy = String.fromEnvironment('NEWS_PROXY');

  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-northeast3');

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

    // 앱 시작 때 홈과 뉴스 탭이 동시에 부르므로, 진행 중인 요청이 있으면 같이 쓴다.
    return _inflight ??= _refresh(
      limit,
      cached,
    ).whenComplete(() => _inflight = null);
  }

  static Future<List<NewsItem>>? _inflight;

  static Future<List<NewsItem>> _refresh(
    int limit,
    List<NewsItem>? cached,
  ) async {
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
    final xml = kIsWeb && _definedProxy.isEmpty
        ? await _fetchViaFunction()
        : await _fetchViaHttp();
    return parseRss(xml, limit: limit);
  }

  /// 웹 기본 경로. 서버가 XML 문자열을 그대로 돌려준다.
  static Future<String> _fetchViaFunction() async {
    final callable = _functions.httpsCallable('fetchNewsFeed');
    final response = await callable.call<Map<String, dynamic>>({
      'url': _feedUri.toString(),
    });
    final xml = response.data['xml'] as String?;
    if (xml == null || xml.isEmpty) {
      throw Exception('뉴스 응답이 비어 있어요.');
    }
    return xml;
  }

  /// 모바일/데스크톱 직접 호출. 웹에서 `NEWS_PROXY`를 넘겼을 때도 이 경로다.
  static Future<String> _fetchViaHttp() async {
    final target = _definedProxy.isEmpty
        ? _feedUri
        : Uri.parse(_definedProxy).replace(
            queryParameters: {'url': _feedUri.toString()},
          );

    http.Response res;
    try {
      res = await http.get(target).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 500) {
        throw Exception('뉴스 응답 오류 (${res.statusCode})');
      }
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 800));
      res = await http.get(target).timeout(const Duration(seconds: 10));
    }
    if (res.statusCode != 200) {
      throw Exception('뉴스 응답 오류 (${res.statusCode})');
    }
    // http 패키지는 charset 헤더가 없으면 latin1로 디코딩하므로 직접 utf8로 읽는다.
    return utf8.decode(res.bodyBytes);
  }

  static final _itemPattern = RegExp(r'<item>(.*?)</item>', dotAll: true);
  static final _titlePattern = RegExp(r'<title>(.*?)</title>', dotAll: true);
  static final _linkPattern = RegExp(r'<link>(.*?)</link>', dotAll: true);
  static final _sourcePattern = RegExp(
    r'<source[^>]*>(.*?)</source>',
    dotAll: true,
  );
  static final _datePattern = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true);
  static final _mediaPattern = RegExp(
    r'<media:content[^>]*url="([^"]+)"',
    dotAll: true,
  );
  static final _enclosurePattern = RegExp(
    r'<enclosure[^>]*url="([^"]+)"[^>]*type="image/',
    dotAll: true,
  );

  /// RFC 822 `Tue, 02 Sep 2025 01:23:00 GMT` / `... +0900`을 읽는다.
  /// `HttpDate.parse`는 dart:io라 웹 빌드에서 못 쓴다.
  static final _rfc822 = RegExp(
    r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})(?:\s+([+-]\d{4}))?',
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
    final local = DateTime.utc(
      int.parse(m.group(3)!),
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
    // `+0900`처럼 오프셋이 붙어 있으면 그만큼 빼서 UTC로 맞춘다. 없으면(GMT) 그대로.
    final tz = m.group(7);
    if (tz == null) return local;
    final sign = tz.startsWith('-') ? -1 : 1;
    final offset = Duration(
      hours: int.parse(tz.substring(1, 3)),
      minutes: int.parse(tz.substring(3, 5)),
    );
    return local.subtract(offset * sign);
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

      // 구글뉴스처럼 제목이 "기사 제목 - 언론사" 형태면 그 언론사명이 <source>에
      // 그대로 들어있다. 문자열로 자르지 말고 <source> 값과 일치하는 꼬리만 떼어낸다.
      // <source>가 없는 피드(연합뉴스)는 피드 기본 언론사명을 쓴다.
      final rawSource = _sourcePattern.firstMatch(block)?.group(1);
      final source = rawSource == null
          ? _defaultSource
          : _unescape(rawSource).trim();
      var title = _unescape(rawTitle).trim();
      if (rawSource != null && source.isNotEmpty) {
        final suffix = ' - $source';
        if (title.endsWith(suffix)) {
          title = title.substring(0, title.length - suffix.length).trim();
        }
      }

      final url = _unescape(rawLink).trim();
      if (title.isEmpty || url.isEmpty) continue;

      final term = matchFinanceTerm(title);
      if (term == null) continue;

      final rawImage = _mediaPattern.firstMatch(block)?.group(1) ??
          _enclosurePattern.firstMatch(block)?.group(1);
      final imageUrl = rawImage == null ? null : _unescape(rawImage).trim();

      items.add(
        NewsItem(
          title: title,
          url: url,
          term: term,
          source: source,
          publishedAt: parsePubDate(_datePattern.firstMatch(block)?.group(1)),
          imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
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
