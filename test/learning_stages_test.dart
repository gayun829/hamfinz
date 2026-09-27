import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/learning_stages.dart';

void main() {
  test('tier progress counts stages reached within the current tier', () {
    // 초급 1~3
    expect(tierProgress(1), closeTo(1 / 3, 1e-9));
    expect(tierProgress(3), 1.0);
    // 중급 4~7 — 새 티어에 들어서면 처음부터 다시 찬다.
    expect(tierProgress(4), 0.25);
    expect(tierProgress(5), 0.5);
    expect(tierProgress(7), 1.0);
    // 고급 8~10
    expect(tierProgress(8), closeTo(1 / 3, 1e-9));
    expect(tierProgress(10), 1.0);
  });

  test('tier progress clamps out-of-range stages', () {
    expect(tierProgress(0), closeTo(1 / 3, 1e-9));
    expect(tierProgress(99), 1.0);
  });
}
