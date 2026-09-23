import 'clock.dart';

abstract final class Fmt {
  static const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const months = [
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
  static String weekday(DateTime d, {bool short = false}) =>
      short ? days[d.weekday - 1].substring(0, 3) : days[d.weekday - 1];
  static String month(DateTime d, {bool short = false}) =>
      short ? months[d.month - 1].substring(0, 3) : months[d.month - 1];
  static String date(DateTime d) => '${month(d, short: true)} ${d.day}';
  static String fullDate(DateTime d) => '${weekday(d)} · ${date(d)}';
  static String time(DateTime d, {bool suffix = true}) =>
      '${d.hour % 12 == 0 ? 12 : d.hour % 12}:${d.minute.toString().padLeft(2, '0')}${suffix ? ' ${d.hour < 12 ? 'AM' : 'PM'}' : ''}';
  static String minute(int m, {bool suffix = true}) =>
      time(DateTime(2026, 1, 1, m ~/ 60, m % 60), suffix: suffix);
  static String relativeDay(DateTime d, DateTime now) => sameDay(d, now)
      ? 'Today'
      : sameDay(d, now.add(const Duration(days: 1)))
      ? 'Tomorrow'
      : fullDate(d);
  static String offset(int minutes) => minutes % 1440 == 0
      ? '${minutes ~/ 1440} ${minutes == 1440 ? 'day' : 'days'}'
      : minutes % 60 == 0
      ? '${minutes ~/ 60} ${minutes == 60 ? 'hour' : 'hours'}'
      : '$minutes min';
  static String offsets(List<int> values) =>
      values.isEmpty ? 'Off' : values.map(offset).join(' · ');
  static String until(DateTime d, DateTime now) {
    final m = d.difference(now).inMinutes;
    if (m < 1) return 'Now';
    if (m < 60) return 'In $m min';
    if (m < 1440) return 'In ${m ~/ 60}h${m % 60 > 0 ? ' ${m % 60}m' : ''}';
    return relativeDay(d, now);
  }

  static String ago(DateTime d, DateTime now) {
    final m = now.difference(d).inMinutes;
    if (m < 1) return 'Just now';
    if (m < 60) return '${m}m ago';
    if (m < 1440) return '${m ~/ 60}h ago';
    return date(d);
  }
}
