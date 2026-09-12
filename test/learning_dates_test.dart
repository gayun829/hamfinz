import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/utils/learning_dates.dart';

void main() {
  test(
    'many sessions on one day occupy only one date and retain month start',
    () {
      final history = [
        {'date': '2026-09-01', 'correctCount': 4},
        ...List.generate(60, (_) => {'date': '2026-09-12', 'xpEarned': 100}),
      ];
      expect(
        LearningDates.fromUser(
          {'learningHistory': history},
          today: '2026-09-12',
          markToday: true,
        ),
        ['2026-09-12', '2026-09-01'],
      );
    },
  );

  test(
    '32-day window is inclusive, crosses months and drops future/invalid dates',
    () {
      expect(
        LearningDates.fromUser({
          'learningDates': [
            '2026-08-11',
            '2026-08-12',
            '2026-09-12',
            '2026-09-13',
            '2026-08-32',
            '2026-9-1',
            null,
          ],
        }, today: '2026-09-12'),
        ['2026-09-12', '2026-08-12'],
      );
    },
  );

  test('leap day and year boundaries use calendar days', () {
    expect(
      LearningDates.fromUser(
        {
          'learningDates': ['2024-02-28', '2024-02-29'],
        },
        today: '2024-03-31',
        markToday: true,
      ),
      ['2024-03-31', '2024-02-29'],
    );
    expect(
      LearningDates.fromUser(
        {
          'learningDates': ['2025-12-01', '2025-12-02'],
        },
        today: '2026-01-02',
        markToday: true,
      ),
      ['2026-01-02', '2025-12-02'],
    );
  });

  test('new field is authoritative and at most 32 dates survive', () {
    expect(
      LearningDates.fromUser({
        'learningDates': [],
        'learningHistory': [
          {'date': '2026-09-12'},
        ],
      }, today: '2026-09-12'),
      isEmpty,
    );
    final dates = List.generate(
      70,
      (i) => DateTime.utc(
        2026,
        9,
        12,
      ).subtract(Duration(days: i)).toIso8601String().substring(0, 10),
    );
    final saved = LearningDates.fromUser(
      {'learningDates': dates},
      today: '2026-09-12',
      markToday: true,
    );
    expect(saved.length, 32);
    expect(saved.last, '2026-08-12');
    expect(
      LearningDates.fromUser(
        {'learningDates': saved},
        today: '2026-09-13',
        markToday: true,
      ).length,
      32,
    );
    expect(
      LearningDates.fromUser({'learningDates': saved}, today: '2026-11-01'),
      isEmpty,
    );
  });
}
