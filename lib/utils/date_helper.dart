class DateHelper {
  /// KST calendar components, independent of the device time zone.
  static DateTime koreaNow([DateTime? instant]) =>
      (instant ?? DateTime.now()).toUtc().add(const Duration(hours: 9));

  /// Format calendar components without applying a time-zone conversion.
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String todayKey([DateTime? instant]) => dateKey(koreaNow(instant));

  static String yesterdayKey([DateTime? instant]) =>
      dateKey(koreaNow(instant).subtract(const Duration(days: 1)));

  static bool isToday(String? dateKey) => dateKey == todayKey();
  static bool isYesterday(String? dateKey) => dateKey == yesterdayKey();
}
