import '../../../core/models.dart';
import '../../../core/clock.dart';
import '../../../core/format.dart';

class AgendaEntry {
  const AgendaEntry({
    required this.at,
    required this.course,
    this.event,
    this.session,
    required this.day,
  });
  final DateTime at, day;
  final Course course;
  final AcademicEvent? event;
  final ClassSession? session;
  String get id => event?.id ?? '${session!.id}-${day.toIso8601String()}';
  String get title => event?.title ?? course.name;
  bool get cancelled =>
      event?.status == EventStatus.cancelled || session?.cancelled == true;
  bool get deadline => event?.deadline != null;
  DateTime? get end => event?.endsAt ?? session?.endOn(day);
  bool get timeUnknown =>
      event != null && event!.startsAt == null && event!.deadline == null;
  String get location {
    final value = event?.location ?? session?.room;
    return value == null || value.trim().isEmpty
        ? 'Room to be announced'
        : value;
  }

  String get timeLabel => timeUnknown ? 'TBA' : Fmt.time(at, suffix: false);
  String get typeLabel =>
      event?.type.label ?? (session!.isLab ? 'Lab' : 'Class');
}

abstract final class AgendaProjection {
  static List<AgendaEntry> day({
    required DateTime day,
    required List<ClassSession> sessions,
    required List<AcademicEvent> events,
    required List<Course> courses,
    bool omitRoutine = false,
    List<AcademicPeriod> periods = const [],
  }) {
    Course course(String id) => courses.firstWhere(
      (c) => c.id == id,
      orElse: () => Course(
        id: id,
        name: 'Course details pending',
        facultyId: '',
        departmentId: '',
      ),
    );
    final list = <AgendaEntry>[
      if (!omitRoutine &&
          !periods.any((p) => p.classesSuspended && p.includes(day)))
        for (final s in sessions.where((s) => s.weekday == day.weekday))
          AgendaEntry(
            at: s.startOn(day),
            day: day,
            course: course(s.courseId),
            session: s,
          ),
      for (final e in events.where((e) => sameDay(e.date, day)))
        AgendaEntry(
          at: e.effectiveAt,
          day: day,
          course: course(e.courseId),
          event: e,
        ),
    ];
    list.sort((a, b) {
      if (a.timeUnknown != b.timeUnknown) return a.timeUnknown ? 1 : -1;
      return a.at.compareTo(b.at);
    });
    return list;
  }

  static List<AgendaEntry> conflicts(List<AgendaEntry> entries) => entries
      .where(
        (a) =>
            !a.cancelled &&
            !a.deadline &&
            !a.timeUnknown &&
            entries.any(
              (b) =>
                  a.id != b.id &&
                  !b.cancelled &&
                  !b.deadline &&
                  !b.timeUnknown &&
                  a.at.isBefore(b.end ?? b.at.add(const Duration(hours: 1))) &&
                  b.at.isBefore(a.end ?? a.at.add(const Duration(hours: 1))),
            ),
      )
      .toList();
}

class HomeProjection {
  HomeProjection({
    required this.now,
    required this.today,
    required this.tomorrow,
    required this.events,
    required this.progress,
  });
  final DateTime now;
  final List<AgendaEntry> today, tomorrow;
  final List<AcademicEvent> events;
  final List<PersonalProgress> progress;
  bool done(String id) => progress.any((p) => p.eventId == id && p.completed);
  AgendaEntry? get current => _first(
    today.where(
      (e) =>
          !e.cancelled &&
          !e.deadline &&
          !e.timeUnknown &&
          !e.at.isAfter(now) &&
          (e.end ?? e.at.add(const Duration(hours: 1))).isAfter(now),
    ),
  );
  AgendaEntry? get next => _first(
    today.where(
      (e) => !e.cancelled && !e.deadline && !e.timeUnknown && e.at.isAfter(now),
    ),
  );
  List<AcademicEvent> get dueToday =>
      events
          .where(
            (e) =>
                sameDay(e.date, now) &&
                e.deadline != null &&
                e.actionable &&
                !done(e.id),
          )
          .toList()
        ..sort((a, b) => a.effectiveAt.compareTo(b.effectiveAt));
  AcademicEvent? get prepareFor {
    final list = events
        .where(
          (e) =>
              e.actionable &&
              e.type.isExam &&
              e.date.isAfter(dateOnly(now)) &&
              e.date.isBefore(dateOnly(now).add(const Duration(days: 2))) &&
              !done(e.id),
        )
        .toList();
    return _first(list);
  }

  String get headline => current != null
      ? 'Happening now'
      : next != null
      ? 'Up next'
      : dueToday.isNotEmpty
      ? (dueToday.length == 1
            ? 'One thing to finish'
            : '${dueToday.length} things to finish')
      : prepareFor != null
      ? 'Prepare for tomorrow'
      : 'Room to breathe';
  String get quietTitle =>
      today.isEmpty ? 'Nothing scheduled today.' : 'Today is wrapped up.';
  T? _first<T>(Iterable<T> values) => values.isEmpty ? null : values.first;
}
