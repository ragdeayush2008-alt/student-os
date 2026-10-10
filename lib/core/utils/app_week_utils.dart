/// Centralized week-boundary utilities for the Student OS ecosystem.
///
/// All week calculations (Plan, Progress, Goals) use these shared helpers
/// so the user's week-start preference is respected everywhere.
abstract final class AppWeekUtils {
  /// Returns the start-of-week date containing [day].
  ///
  /// When [startsMonday] is true, the week starts on Monday (default).
  /// When false, the week starts on Sunday.
  static DateTime startOfWeek(DateTime day, {bool startsMonday = true}) {
    final date = DateTime(day.year, day.month, day.day);
    if (startsMonday) {
      return date.subtract(Duration(days: date.weekday - 1));
    }
    // Sunday start: weekday 7 = Sunday → offset 0
    return date.subtract(Duration(days: date.weekday % 7));
  }

  /// Returns the end-of-week (exclusive) containing [day].
  static DateTime endOfWeek(DateTime day, {bool startsMonday = true}) =>
      startOfWeek(day, startsMonday: startsMonday).add(const Duration(days: 7));

  /// The seven dates of the week containing [day], in display order.
  static List<DateTime> weekDates(DateTime day, {bool startsMonday = true}) {
    final start = startOfWeek(day, startsMonday: startsMonday);
    return List<DateTime>.generate(7, (i) => start.add(Duration(days: i)));
  }

  /// Ordered weekday abbreviations matching the chosen start day.
  static List<String> weekdayLabels({bool startsMonday = true}) {
    if (startsMonday) {
      return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
    return const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  }

  /// Ordered full weekday names matching the chosen start day.
  static List<String> weekdayFullLabels({bool startsMonday = true}) {
    if (startsMonday) {
      return const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
    }
    return const [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
  }

  /// Normalizes a [DateTime] to its date (ignoring time-of-day).
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Normalizes a nullable [DateTime] to its date, or returns null.
  static DateTime? dateOnlyOrNull(DateTime? value) =>
      value == null ? null : dateOnly(value);

  /// Full name of a month (1-12).
  static String monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  /// 3-letter abbreviation of a month (1-12).
  static String monthAbbr(int month) {
    const abbrs = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return abbrs[month - 1];
  }

  /// Full name of a weekday (1 = Mon, ..., 7 = Sun).
  static String weekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  /// 3-letter abbreviation of a weekday (1 = Mon, ..., 7 = Sun).
  static String weekdayAbbr(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }

  /// Formats a date for headers, e.g. "Monday, Sep 22".
  static String formatDateHeader(DateTime date) {
    final day = weekdayName(date.weekday);
    final month = monthAbbr(date.month);
    return '$day, $month ${date.day}';
  }
}
