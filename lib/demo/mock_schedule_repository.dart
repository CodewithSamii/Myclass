import '../core/models.dart';
import '../core/repositories.dart';
import '../core/clock.dart';
import 'mock_store.dart';
import 'demo_controller.dart';
import 'fixtures.dart';
import '../core/format.dart';

class MockScheduleRepository implements ScheduleRepository {
  MockScheduleRepository(this.store);
  final MockStore store;
  @override
  Stream<Feed<ClassSession>> watchRoutine(String sectionId) => store.watch(
    () => Feed(
      store.demo.state.scenario == DemoScenario.unknownSchedule
          ? <ClassSession>[]
          : List.unmodifiable(store.routineFor(sectionId)),
      unavailable: store.demo.state.scenario == DemoScenario.unknownSchedule,
      offline: store.demo.state.offline,
      stale: store.demo.state.stale,
      updatedAt: store.updatedAt,
    ),
  );
  @override
  Future<List<Course>> courses(String sectionId) async {
    await store.delay();
    return Fixtures.coursesFor(sectionId);
  }

  @override
  Future<List<AcademicPeriod>> periods(String sectionId) async => [
    AcademicPeriod(
      title: "Midterm assessment period",
      start: DateTime(2026, 9, 24),
      end: DateTime(2026, 10, 1),
    ),
    AcademicPeriod(
      title: "Exam day · Regular classes suspended",
      start: DateTime(2026, 9, 24),
      end: DateTime(2026, 9, 24),
      classesSuspended: true,
    ),
    AcademicPeriod(
      title: "Semester break",
      start: DateTime(2026, 10, 17),
      end: DateTime(2026, 11, 1),
      classesSuspended: true,
    ),
  ];
  @override
  Future<void> saveSession(ClassSession session) async {
    await store.checkWrite(shared: true, section: session.sectionId);
    final list = store.routineFor(session.sectionId);
    final i = list.indexWhere((s) => s.id == session.id);
    final old = i < 0 ? null : list[i];
    if (i < 0) {
      list.add(session);
    } else {
      list[i] = session;
    }
    final name = Fixtures.courses
        .firstWhere((c) => c.id == session.courseId)
        .compactName;
    store.updates
        .putIfAbsent(session.sectionId, () => [])
        .insert(
          0,
          UpdateFeedItem(
            id: 'routine-${DateTime.now().microsecondsSinceEpoch}',
            eventId: '',
            sessionId: session.id,
            title: '$name routine updated',
            detail: session.cancelled
                ? 'Repeating class cancelled'
                : old?.room != session.room
                ? 'Room ${old?.room ?? 'TBA'} → ${session.room?.isEmpty == false ? session.room : 'TBA'}'
                : '${old == null ? 'New session' : Fmt.minute(old.startMinute)} → ${Fmt.minute(session.startMinute)}',
            at: store.demo.now,
          ),
        );
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }

  @override
  Future<List<TimeSlot>> timeSlots(String sectionId) async {
    await store.delay();
    return List.unmodifiable(store.timeSlotsFor(sectionId));
  }

  @override
  Future<void> saveTimeSlots(String sectionId, List<TimeSlot> slots) async {
    await store.checkWrite(shared: true, section: sectionId);
    store.timeSlots[sectionId] = List.from(slots);
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }

  @override
  Future<void> saveRoutine(String sectionId, List<ClassSession> sessions) async {
    await store.checkWrite(shared: true, section: sectionId);
    store.routines[sectionId] = List.from(sessions);
    store.updates
        .putIfAbsent(sectionId, () => [])
        .insert(
          0,
          UpdateFeedItem(
            id: 'routine-bulk-${DateTime.now().microsecondsSinceEpoch}',
            eventId: '',
            sessionId: '',
            title: 'Class Routine updated',
            detail: 'Weekly schedule has been updated by class admin.',
            at: store.demo.now,
          ),
        );
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }

  @override
  Future<void> cancelSessionOnDate({
    required String sectionId,
    required ClassSession session,
    required DateTime date,
    required bool cancel,
  }) async {
    await store.checkWrite(shared: true, section: sectionId);
    final list = store.routineFor(sectionId);
    final overrideId = '${session.id}-override-${date.year}-${date.month}-${date.day}';
    final i = list.indexWhere((s) => s.id == overrideId);

    if (cancel) {
      final override = session.copyWith(
        id: overrideId,
        specificDate: DateTime(date.year, date.month, date.day),
        weekday: date.weekday,
        cancelled: true,
        changed: true,
      );
      if (i < 0) {
        list.add(override);
      } else {
        list[i] = override;
      }
    } else {
      if (i >= 0) {
        list.removeAt(i);
      } else if (session.cancelled) {
        final override = session.copyWith(
          id: overrideId,
          specificDate: DateTime(date.year, date.month, date.day),
          weekday: date.weekday,
          cancelled: false,
          changed: true,
        );
        list.add(override);
      }
    }

    final courseName = session.customCourseName?.isNotEmpty == true
        ? session.customCourseName!
        : (Fixtures.courses.where((c) => c.id == session.courseId).firstOrNull?.compactName ?? 'Class');

    store.updates
        .putIfAbsent(sectionId, () => [])
        .insert(
          0,
          UpdateFeedItem(
            id: 'cancel-${DateTime.now().microsecondsSinceEpoch}',
            eventId: '',
            sessionId: session.id,
            title: cancel
                ? '$courseName cancelled on ${Fmt.shortDate(date)}'
                : '$courseName restored on ${Fmt.shortDate(date)}',
            detail: cancel
                ? 'Scheduled class at ${Fmt.minute(session.startMinute)} has been marked as cancelled.'
                : 'Class will take place as scheduled at ${Fmt.minute(session.startMinute)}.',
            at: store.demo.now,
          ),
        );
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }

  @override
  Future<void> shiftSession({
    required String sectionId,
    required ClassSession session,
    required DateTime sourceDate,
    required DateTime targetDate,
    required int newStartMinute,
    required int newEndMinute,
    String? newRoom,
  }) async {
    await store.checkWrite(shared: true, section: sectionId);
    final list = store.routineFor(sectionId);

    // 1. Mark cancelled on source date
    final sourceOverrideId = '${session.id}-override-${sourceDate.year}-${sourceDate.month}-${sourceDate.day}';
    final sourceIdx = list.indexWhere((s) => s.id == sourceOverrideId);
    final sourceOverride = session.copyWith(
      id: sourceOverrideId,
      specificDate: DateTime(sourceDate.year, sourceDate.month, sourceDate.day),
      weekday: sourceDate.weekday,
      cancelled: true,
      isShifted: true,
      notes: 'Shifted to ${Fmt.shortDate(targetDate)} at ${Fmt.minute(newStartMinute)}',
      changed: true,
    );
    if (sourceIdx < 0) {
      list.add(sourceOverride);
    } else {
      list[sourceIdx] = sourceOverride;
    }

    // 2. Add shifted session on target date
    final targetShiftId = 'shift-${session.id}-${targetDate.year}-${targetDate.month}-${targetDate.day}';
    final targetIdx = list.indexWhere((s) => s.id == targetShiftId);
    final shiftedSession = ClassSession(
      id: targetShiftId,
      sectionId: sectionId,
      courseId: session.courseId,
      weekday: targetDate.weekday,
      startMinute: newStartMinute,
      endMinute: newEndMinute,
      room: newRoom ?? session.room,
      isLab: session.isLab,
      isOnline: session.isOnline,
      cancelled: false,
      changed: true,
      specificDate: DateTime(targetDate.year, targetDate.month, targetDate.day),
      isShifted: true,
      originalDate: DateTime(sourceDate.year, sourceDate.month, sourceDate.day),
      originalTimeLabel: '${Fmt.weekday(sourceDate)} ${Fmt.minute(session.startMinute)}–${Fmt.minute(session.endMinute)}',
      customCourseName: session.customCourseName,
      facultyName: session.facultyName,
    );
    if (targetIdx < 0) {
      list.add(shiftedSession);
    } else {
      list[targetIdx] = shiftedSession;
    }

    // Automatically transfer any attached events for this course from sourceDate to targetDate
    final events = store.eventsFor(sectionId);
    for (var i = 0; i < events.length; i++) {
      final ev = events[i];
      if (sameDay(ev.date, sourceDate) && ev.courseId == session.courseId) {
        events[i] = ev.copyWith(
          date: targetDate,
          startsAt: ev.startsAt != null
              ? DateTime(targetDate.year, targetDate.month, targetDate.day, newStartMinute ~/ 60, newStartMinute % 60)
              : null,
          endsAt: ev.endsAt != null
              ? DateTime(targetDate.year, targetDate.month, targetDate.day, newEndMinute ~/ 60, newEndMinute % 60)
              : null,
          updatedAt: store.demo.now,
        );
      }
    }

    final courseName = session.customCourseName?.isNotEmpty == true
        ? session.customCourseName!
        : (Fixtures.courses.where((c) => c.id == session.courseId).firstOrNull?.compactName ?? 'Class');

    store.updates
        .putIfAbsent(sectionId, () => [])
        .insert(
          0,
          UpdateFeedItem(
            id: 'shift-${DateTime.now().microsecondsSinceEpoch}',
            eventId: '',
            sessionId: session.id,
            title: '$courseName shifted to ${Fmt.shortDate(targetDate)}',
            detail: 'Moved from ${Fmt.shortDate(sourceDate)} (${Fmt.minute(session.startMinute)}) to ${Fmt.shortDate(targetDate)} (${Fmt.minute(newStartMinute)}–${Fmt.minute(newEndMinute)}).',
            at: store.demo.now,
          ),
        );
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }

  @override
  Future<void> saveTemporaryClass(ClassSession session) async {
    await store.checkWrite(shared: true, section: session.sectionId);
    final list = store.routineFor(session.sectionId);
    final i = list.indexWhere((s) => s.id == session.id);
    if (i < 0) {
      list.add(session);
    } else {
      list[i] = session;
    }

    final courseName = session.customCourseName?.isNotEmpty == true
        ? session.customCourseName!
        : (Fixtures.courses.where((c) => c.id == session.courseId).firstOrNull?.compactName ?? 'Temporary Class');

    final dateStr = session.specificDate != null ? Fmt.shortDate(session.specificDate!) : 'Scheduled Date';
    store.updates
        .putIfAbsent(session.sectionId, () => [])
        .insert(
          0,
          UpdateFeedItem(
            id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
            eventId: '',
            sessionId: session.id,
            title: 'Temporary Class: $courseName on $dateStr',
            detail: '${session.isOnline ? "Online class" : "Room ${session.room ?? "TBA"}"} · ${Fmt.minute(session.startMinute)}–${Fmt.minute(session.endMinute)}',
            at: store.demo.now,
          ),
        );
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }

  @override
  Future<void> deleteTemporaryClass(String sectionId, String sessionId) async {
    await store.checkWrite(shared: true, section: sectionId);
    final list = store.routineFor(sectionId);
    final i = list.indexWhere((s) => s.id == sessionId);
    if (i >= 0) {
      final removed = list.removeAt(i);
      final courseName = removed.customCourseName?.isNotEmpty == true
          ? removed.customCourseName!
          : (Fixtures.courses.where((c) => c.id == removed.courseId).firstOrNull?.compactName ?? 'Temporary Class');
      store.updates
          .putIfAbsent(sectionId, () => [])
          .insert(
            0,
            UpdateFeedItem(
              id: 'temp-del-${DateTime.now().microsecondsSinceEpoch}',
              eventId: '',
              sessionId: sessionId,
              title: 'Temporary Class removed: $courseName',
              detail: 'The temporary class has been removed by class admin.',
              at: store.demo.now,
            ),
          );
      if (!store.demo.state.offline) store.updatedAt = store.demo.now;
      store.notify();
    }
  }

  @override
  Future<void> refresh() async {
    await store.delay();
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }
}

