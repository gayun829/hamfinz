import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/services/quiz_service.dart';

void main() {
  test('열린 세션을 모두 닫는다', () async {
    final closed = <String>[];

    await closeOpenSessions(
      openSessionIds: () async => ['s1', 's2', 's3'],
      abandon: (id) async => closed.add(id),
    );

    expect(closed, ['s1', 's2', 's3']);
  });

  test('한 세션을 닫지 못해도 나머지는 닫는다', () async {
    final closed = <String>[];

    await closeOpenSessions(
      openSessionIds: () async => ['s1', 's2', 's3'],
      abandon: (id) async {
        if (id == 's2') throw Exception('network');
        closed.add(id);
      },
    );

    expect(closed, ['s1', 's3']);
  });

  test('열린 세션을 찾지 못하면 아무것도 하지 않고 끝낸다', () async {
    var abandonCalls = 0;

    await closeOpenSessions(
      openSessionIds: () => Future.error(Exception('offline')),
      abandon: (_) async => abandonCalls++,
    );

    expect(abandonCalls, 0);
  });

  test('세션 조회가 바로 던져도 학습 시작을 막지 않는다', () async {
    await closeOpenSessions(
      openSessionIds: () => throw StateError('no Firebase app'),
      abandon: (_) async {},
    );
  });
}
