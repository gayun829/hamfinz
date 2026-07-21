class DateHelper {
  static String todayKey([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String yesterdayKey([DateTime? date]) {
    final now = date ?? DateTime.now();
    return todayKey(now.subtract(const Duration(days: 1)));
  }

  static bool isToday(String? dateKey) => dateKey == todayKey();

  static bool isYesterday(String? dateKey) => dateKey == yesterdayKey();
}
