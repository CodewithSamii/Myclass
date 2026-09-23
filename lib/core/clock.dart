abstract interface class AppClock {
  DateTime get now;
  Stream<DateTime> get ticks;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
DateTime weekStart(DateTime d) =>
    dateOnly(d).subtract(Duration(days: d.weekday % 7));
