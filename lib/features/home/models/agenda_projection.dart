import '../../../core/models.dart';
import '../../../core/clock.dart';
import '../../../core/format.dart';

class AgendaEntry {
  const AgendaEntry({
    required this.at,
    required this.course,
    this.event,
    this.events = const [],
    this.session,
    required this.day,
  });
  final DateTime at, day;
  final Course course;
  final AcademicEvent? event;
  final List<AcademicEvent> events;
  final ClassSession? session;
  String get id => event?.id ?? (events.isNotEmpty ? events.first.id : '${session!.id}-${day.toIso8601String()}');
  String get title =>
      event?.title ??
      (session?.customCourseName?.isNotEmpty == true
          ? session!.customCourseName!
          : course.name);
  bool get cancelled =>
      event?.status == EventStatus.cancelled || session?.cancelled == true;
  bool get deadline => event?.deadline != null;
  DateTime? get end => event?.endsAt ?? session?.endOn(day);
  bool get timeUnknown =>
      event != null && event!.startsAt == null && event!.deadline == null;
  bool get isTemporary => session?.isTemporary == true;
  bool get isShifted => session?.isShifted == true;
  bool get isOnline => session?.isOnline == true;
  String? get notes => session?.notes;
  String? get meetingLink => session?.meetingLink;
  String? get facultyName => session?.facultyName;
  DateTime? get originalDate => session?.originalDate;
  String? get originalTimeLabel => session?.originalTimeLabel;

  String get location {
    if (session?.isOnline == true) {
      if (session?.meetingLink != null && session!.meetingLink!.trim().isNotEmpty) {
        return session!.meetingLink!;
      }
      return 'Online meeting';
    }
    final value = event?.location ?? session?.room;
    return value == null || value.trim().isEmpty
        ? 'Room to be announced'
        : value;
  }

  String get timeLabel => timeUnknown ? 'TBA' : Fmt.time(at, suffix: false);
  String get typeLabel =>
      isTemporary
          ? 'Temporary Class'
          : isShifted
          ? 'Shifted Class'
          : event?.type.label ?? (session!.isLab ? 'Lab' : 'Class');
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
    Course course(String id, {String? customName, String? facultyName}) => courses.firstWhere(
      (c) => c.id == id,
      orElse: () => Course(
        id: id,
        name: customName?.isNotEmpty == true ? customName! : 'Course details pending',
        facultyId: facultyName ?? '',
        departmentId: '',
      ),
    );

    final dayEvents = events.where((e) => sameDay(e.date, day)).toList();

    // 1. Recurring weekly sessions for this weekday (where specificDate is null)
    final recurringSessions = sessions
        .where((s) => s.specificDate == null && s.weekday == day.weekday)
        .toList();

    // 2. Specific-date sessions on this exact day (shifts, cancellations, temporary classes)
    final specificDateSessions = sessions
        .where((s) => s.specificDate != null && sameDay(s.specificDate!, day))
        .toList();

    final daySessions = <ClassSession>[];

    // For each recurring session, check if there's a specific-date override for today
    for (final rec in recurringSessions) {
      final overrideId = '${rec.id}-override-${day.year}-${day.month}-${day.day}';
      final override = specificDateSessions.firstWhere(
        (sp) => sp.id == overrideId || sp.id == rec.id,
        orElse: () => rec,
      );
      daySessions.add(override);
    }

    // Add any specific-date sessions that are not overrides of recurring sessions (e.g. temporary classes or shifted-in classes)
    for (final sp in specificDateSessions) {
      final isOverride = recurringSessions.any(
        (rec) => sp.id == '${rec.id}-override-${day.year}-${day.month}-${day.day}' || sp.id == rec.id,
      );
      if (!isOverride) {
        daySessions.add(sp);
      }
    }

    final list = <AgendaEntry>[];

    if (!omitRoutine && !periods.any((p) => p.classesSuspended && p.includes(day))) {
      for (final s in daySessions) {
        final matchingEvents = dayEvents.where((e) => e.courseId == s.courseId).toList();
        list.add(
          AgendaEntry(
            at: s.startOn(day),
            day: day,
            course: course(s.courseId, customName: s.customCourseName, facultyName: s.facultyName),
            session: s,
            events: matchingEvents,
            event: matchingEvents.isNotEmpty ? matchingEvents.first : null,
          ),
        );
      }
    }

    // Include any standalone events on this day whose course is not already in daySessions
    for (final e in dayEvents) {
      final alreadyInSession = daySessions.any((s) => s.courseId == e.courseId);
      if (!alreadyInSession) {
        list.add(
          AgendaEntry(
            at: e.effectiveAt,
            day: day,
            course: course(e.courseId),
            event: e,
            events: [e],
          ),
        );
      }
    }

    list.sort((a, b) {
      if (a.timeUnknown != b.timeUnknown) return a.timeUnknown ? 1 : -1;
      return a.at.compareTo(b.at);
    });
    return list;
  }

  static bool isAllCancelled(List<AgendaEntry> entries) {
    if (entries.isEmpty) return false;
    return entries.every((e) => e.cancelled);
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
