import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/utils/date_helper.dart';

void main() {
  test('study day switches at Korean midnight, not UTC midnight', () {
    expect(
      DateHelper.todayKey(DateTime.parse('2026-09-12T14:59:59Z')),
      '2026-09-12',
    );
    expect(
      DateHelper.todayKey(DateTime.parse('2026-09-12T15:00:00Z')),
      '2026-09-13',
    );
    expect(
      DateHelper.yesterdayKey(DateTime.parse('2026-09-12T15:00:00Z')),
      '2026-09-12',
    );
  });
  test('offsets and year rollover use the same Korean date', () {
    expect(
      DateHelper.todayKey(DateTime.parse('2026-09-12T08:00:00-07:00')),
      '2026-09-13',
    );
    expect(
      DateHelper.todayKey(DateTime.parse('2025-12-31T15:00:00Z')),
      '2026-01-01',
    );
    expect(
      DateHelper.yesterdayKey(DateTime.parse('2025-12-31T15:00:00Z')),
      '2025-12-31',
    );
    expect(DateHelper.dateKey(DateTime.utc(2026, 9, 12, 23)), '2026-09-12');
  });
}
