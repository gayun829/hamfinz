import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/services/incorrect_question_counts_backfill.dart';

void main() {
  late List<Map<String, dynamic>> docs;
  late int loadCalls;
  late List<Map<String, int>> storeCalls;
  late bool canWrite;
  late Future<Map<String, int>> Function(Map<String, int> counts) store;

  IncorrectQuestionCountsBackfill backfill() => IncorrectQuestionCountsBackfill(
    loadIncorrectDocs: (_) async {
      loadCalls++;
      return docs;
    },
    storeIfMissing: (_, counts) {
      storeCalls.add(counts);
      return store(counts);
    },
    canWrite: () => canWrite,
  );

  setUp(() {
    docs = [];
    loadCalls = 0;
    storeCalls = [];
    canWrite = true;
    store = (counts) async => counts;
  });

  test('categoryId가 없는 오답 문서는 용돈 관리로 센다', () async {
    docs = [
      {'categoryId': 'saving'},
      {'categoryId': 'saving'},
      <String, dynamic>{},
    ];

    final counts = await backfill().run('u1');

    expect(counts, {'saving': 2, 'allowance': 1});
    expect(storeCalls.single, {'saving': 2, 'allowance': 1});
  });

  test('오답이 없으면 빈 맵을 저장하고 다시 읽지 않는다', () async {
    final subject = backfill();

    expect(await subject.run('u1'), isEmpty);
    expect(storeCalls.single, isEmpty);
    expect(subject.isStored('u1'), isTrue);
  });

  test('그 사이 다른 제출이 맵을 만들었으면 저장된 값을 쓴다', () async {
    docs = [
      {'categoryId': 'saving'},
    ];
    store = (_) async => {'saving': 2};

    expect(await backfill().run('u1'), {'saving': 2});
  });

  test('쓰기가 거절되면 집계값을 돌려주고 다음에 다시 시도한다', () async {
    docs = [
      {'categoryId': 'stock'},
    ];
    store = (_) => Future.error(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    final subject = backfill();

    expect(await subject.run('u1'), {'stock': 1});
    expect(subject.isStored('u1'), isFalse);

    await subject.run('u1');
    expect(loadCalls, 2);
  });

  test('쓸 수 없는 모드에서는 저장하지 않고 집계를 한 번만 한다', () async {
    canWrite = false;
    docs = [
      {'categoryId': 'saving'},
    ];
    final subject = backfill();

    expect(await subject.run('u1'), {'saving': 1});
    expect(await subject.run('u1'), {'saving': 1});
    expect(loadCalls, 1);
    expect(storeCalls, isEmpty);
  });

  test('오답 정리 결과를 기억해 둔 집계에 반영한다', () async {
    canWrite = false;
    docs = [
      for (var i = 0; i < 11; i++) {'categoryId': 'saving'},
      {'categoryId': 'stock'},
    ];
    final subject = backfill();
    expect(await subject.run('u1'), {'saving': 11, 'stock': 1});

    // 11개 중 3개가 복습할 수 없어 8개로 다시 셌다.
    subject.applyReconciled('u1', 'saving', 8);
    expect(await subject.run('u1'), {'saving': 8, 'stock': 1});

    subject.applyReconciled('u1', 'stock', 0);
    expect(await subject.run('u1'), {'saving': 8});
    expect(loadCalls, 1);
  });

  test('기억해 둔 집계가 없으면 오답 정리 결과를 무시한다', () async {
    final subject = backfill();
    subject.applyReconciled('u1', 'saving', 3);

    docs = [
      {'categoryId': 'saving'},
    ];
    expect(await subject.run('u1'), {'saving': 1});
  });

  test('맵이 저장된 것을 확인하면 기억해 둔 집계를 버린다', () async {
    canWrite = false;
    docs = [
      {'categoryId': 'saving'},
    ];
    final subject = backfill();
    await subject.run('u1');

    subject.markStored('u1');
    expect(subject.isStored('u1'), isTrue);

    docs = [
      {'categoryId': 'saving'},
      {'categoryId': 'saving'},
    ];
    expect(await subject.run('u1'), {'saving': 2});
    expect(loadCalls, 2);
  });
}
