import 'package:intl/intl.dart';

/// Date utility helpers for the app
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');
  static final DateFormat _monthDisplayFormat = DateFormat('MMMM yyyy');
  static final DateFormat _monthDisplayArFormat = DateFormat('MMMM yyyy', 'ar');
  static final DateFormat _dayFormat = DateFormat('d MMM');
  static final DateFormat _fullDateFormat = DateFormat('d MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Format DateTime to YYYY-MM (used as session month key)
  static String toMonthKey(DateTime date) => _monthKeyFormat.format(date);

  /// Format month key to human-readable (e.g. "April 2026")
  static String monthKeyToDisplay(String monthKey, {bool arabic = false}) {
    final date = DateTime.parse('$monthKey-01');
    return arabic ? _monthDisplayArFormat.format(date) : _monthDisplayFormat.format(date);
  }

  /// Display format for a date
  static String formatDay(DateTime date) => _dayFormat.format(date);

  /// Full date format
  static String formatFull(DateTime date) => _fullDateFormat.format(date);

  /// Time only
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Current month key
  static String get currentMonthKey => toMonthKey(DateTime.now());

  /// Get the number of days in a month
  static int daysInMonth(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTime(year, month + 1, 0).day;
  }

  /// Days passed in the current month (up to today)
  static int daysPassed(String monthKey) {
    final now = DateTime.now();
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    if (now.year == year && now.month == month) {
      return now.day;
    }
    return daysInMonth(monthKey);
  }

  /// Remaining days in the month
  static int remainingDays(String monthKey) {
    return daysInMonth(monthKey) - daysPassed(monthKey);
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Get month start date
  static DateTime monthStart(String monthKey) {
    final parts = monthKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  /// Get month end date
  static DateTime monthEnd(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }

  /// Human-readable relative day (Today, Yesterday, or date)
  static String relativeDay(DateTime date, {bool arabic = false}) {
    final now = DateTime.now();
    if (isSameDay(date, now)) return arabic ? 'اليوم' : 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (isSameDay(date, yesterday)) return arabic ? 'أمس' : 'Yesterday';
    return formatDay(date);
  }

  /// Month name from monthKey 'YYYY-MM' in a given language (en/ar/fr)
  static String getMonthName(String monthKey, String lang) {
    const months = <String, List<String>>{
      'en': [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ],
      'ar': [
        'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
        'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ],
      'fr': [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
      ],
    };
    final parts = monthKey.split('-');
    final monthIndex = int.parse(parts[1]) - 1;
    final year = parts[0];
    final names = months[lang] ?? months['en']!;
    return '${names[monthIndex]} $year';
  }
}
