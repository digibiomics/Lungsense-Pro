/// Date labels used in lists and headers, without the intl package.
/// All inputs are converted to local time first.
abstract final class LsDates {
  static const _months = [
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
  static const _monthsLong = [
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
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _daysLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// "10:52"
  static String time(DateTime d) {
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  /// "21 Oct"
  static String dayMonth(DateTime d) {
    final l = d.toLocal();
    return '${l.day} ${_months[l.month - 1]}';
  }

  /// "21 Oct 2026"
  static String dayMonthYear(DateTime d) {
    final l = d.toLocal();
    return '${l.day} ${_months[l.month - 1]} ${l.year}';
  }

  /// "Sun, 25 Oct"
  static String weekdayDayMonth(DateTime d) {
    final l = d.toLocal();
    return '${_days[l.weekday - 1]}, ${dayMonth(l)}';
  }

  static bool sameDay(DateTime a, DateTime b) {
    final x = a.toLocal(), y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  /// "Today", "Yesterday" or "Thursday, 22 October".
  static String dayHeading(DateTime d, DateTime now) {
    if (sameDay(d, now)) return 'Today';
    if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    final l = d.toLocal();
    return '${_daysLong[l.weekday - 1]}, ${l.day} ${_monthsLong[l.month - 1]}';
  }

  /// "Today, 10:52", "Yesterday, 16:05" or "21 Oct, 15:30".
  static String dayAndTime(DateTime d, DateTime now) {
    if (sameDay(d, now)) return 'Today, ${time(d)}';
    if (sameDay(d, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday, ${time(d)}';
    }
    return '${dayMonth(d)}, ${time(d)}';
  }

  /// "Today" or "22 Oct" (list "last session" column).
  static String shortDay(DateTime d, DateTime now) =>
      sameDay(d, now) ? 'Today' : dayMonth(d);

  /// ISO calendar date for query parameters: "2026-10-27".
  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
