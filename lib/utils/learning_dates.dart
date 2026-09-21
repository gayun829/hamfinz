import 'date_helper.dart';

/// Calendar-only dates: today and the preceding 31 calendar days.
abstract final class LearningDates {
  static const retentionDays = 32;

  static List<String> fromUser(
    Map<String, dynamic> user, {
    required String today,
    bool markToday = false,
  }) {
    final raw = user['learningDates'];
    final dates = <String>[if (raw is List) ...raw.whereType<String>()];
    final end = DateTime.parse('${today}T00:00:00Z');
    final start = DateHelper.dateKey(
      end.subtract(const Duration(days: retentionDays - 1)),
    );
    final result = <String>{};
    for (final date in [...dates, if (markToday) today]) {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) continue;
      final parsed = DateTime.tryParse('${date}T00:00:00Z');
      if (parsed == null || DateHelper.dateKey(parsed) != date) continue;
      if (date.compareTo(start) >= 0 && date.compareTo(today) <= 0) {
        result.add(date);
      }
    }
    return result.toList()..sort((a, b) => b.compareTo(a));
  }
}
