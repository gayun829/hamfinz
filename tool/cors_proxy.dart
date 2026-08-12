// 개발 전용 CORS 프록시.
//
// 구글뉴스 RSS는 Access-Control-Allow-Origin을 안 주기 때문에 웹(Chrome)으로
// 띄운 앱에서는 브라우저가 응답을 막는다. 안드로이드/iOS에는 없는 문제라
// 앱 코드를 고치는 대신, 로컬에서 이 프록시를 띄우고 --dart-define으로
// 붙여 쓴다.
//
//   1) dart run tool/cors_proxy.dart
//   2) flutter run -d chrome --dart-define=NEWS_PROXY=http://localhost:8766
//
// 루프백에만 바인딩하므로 외부에서는 접근할 수 없다.
import 'dart:io';

const _port = 8766;

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
  final client = HttpClient();
  stdout.writeln('CORS proxy: http://localhost:$_port?url=<대상 URL>');

  await for (final req in server) {
    final res = req.response;
    res.headers.set('Access-Control-Allow-Origin', '*');

    final target = req.uri.queryParameters['url'];
    if (target == null) {
      res.statusCode = HttpStatus.badRequest;
      res.write('url 쿼리 파라미터가 필요합니다.');
      await res.close();
      continue;
    }

    try {
      final upstream = await (await client.getUrl(Uri.parse(target))).close();
      res.statusCode = upstream.statusCode;
      res.headers.contentType = ContentType('application', 'xml', charset: 'utf-8');
      await upstream.pipe(res);
    } catch (e) {
      res.statusCode = HttpStatus.badGateway;
      res.write('$e');
      await res.close();
    }
  }
}
