import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models.dart';
import '../../schedule/repositories/schedule_repository.dart';
import '../../../demo/fixtures.dart';

class FirestoreScheduleRepository implements ScheduleRepository {
  FirestoreScheduleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _sectionDoc(String sectionId) =>
      _firestore.collection('sections').doc(sectionId);

  CollectionReference<Map<String, dynamic>> _routineCol(String sectionId) =>
      _sectionDoc(sectionId).collection('routine');

  CollectionReference<Map<String, dynamic>> _coursesCol(String sectionId) =>
      _sectionDoc(sectionId).collection('courses');

  CollectionReference<Map<String, dynamic>> _slotsCol(String sectionId) =>
      _sectionDoc(sectionId).collection('time_slots');

  CollectionReference<Map<String, dynamic>> _updatesCol(String sectionId) =>
      _sectionDoc(sectionId).collection('updates');

  @override
  Stream<Feed<ClassSession>> watchRoutine(String sectionId) {
    return _routineCol(sectionId).snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        // Return default fixture routine and optionally seed in background
        final defaultSessions = Fixtures.routine(sectionId);
        _seedRoutineIfNeeded(sectionId, defaultSessions);
        return Feed(defaultSessions, updatedAt: DateTime.now());
      }
      final items = snap.docs.map((d) => ClassSession.fromJson(d.data())).toList();
      return Feed(items, updatedAt: DateTime.now());
    });
  }

  Future<void> _seedRoutineIfNeeded(String sectionId, List<ClassSession> sessions) async {
    try {
      final snap = await _routineCol(sectionId).limit(1).get();
      if (snap.docs.isEmpty && sessions.isNotEmpty) {
        final batch = _firestore.batch();
        for (final s in sessions) {
          batch.set(_routineCol(sectionId).doc(s.id), s.toJson());
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  @override
  Future<List<Course>> courses(String sectionId) async {
    try {
      final snap = await _coursesCol(sectionId).get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => Course.fromJson(d.data())).toList();
      }
      // Seed default courses
      final defaultCourses = Fixtures.coursesFor(sectionId);
      _seedCourses(sectionId, defaultCourses);
      return defaultCourses;
    } catch (_) {
      return Fixtures.coursesFor(sectionId);
    }
  }

  Future<void> _seedCourses(String sectionId, List<Course> coursesList) async {
    try {
      final batch = _firestore.batch();
      for (final c in coursesList) {
        batch.set(_coursesCol(sectionId).doc(c.id), c.toJson());
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  Future<List<AcademicPeriod>> periods(String sectionId) async {
    try {
      final snap = await _sectionDoc(sectionId).collection('periods').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => AcademicPeriod.fromJson(d.data())).toList();
      }
    } catch (_) {}
    return [
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
  }

  @override
  Future<List<TimeSlot>> timeSlots(String sectionId) async {
    try {
      final snap = await _slotsCol(sectionId).orderBy('orderIndex').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => TimeSlot.fromJson(d.data())).toList();
      }
    } catch (_) {}
    return Fixtures.defaultTimeSlots;
  }

  @override
  Future<void> saveTimeSlots(String sectionId, List<TimeSlot> slots) async {
    final batch = _firestore.batch();
    for (final s in slots) {
      batch.set(_slotsCol(sectionId).doc(s.id), s.toJson());
    }
    await batch.commit();
  }

  @override
  Future<void> saveRoutine(String sectionId, List<ClassSession> sessions) async {
    final batch = _firestore.batch();
    for (final s in sessions) {
      batch.set(_routineCol(sectionId).doc(s.id), s.toJson());
    }
    await batch.commit();
  }

  @override
  Future<void> saveSession(ClassSession session) async {
    await _routineCol(session.sectionId).doc(session.id).set(session.toJson());
  }

  @override
  Future<void> cancelSessionOnDate({
    required String sectionId,
    required ClassSession session,
    required DateTime date,
    required bool cancel,
    bool notifyStudents = true,
  }) async {
    final sessionRef = _routineCol(sectionId).doc(session.id);
    if (cancel) {
      final cancelledInstance = session.copyWith(
        id: '${session.id}_cancelled_${date.year}_${date.month}_${date.day}',
        cancelled: true,
        specificDate: date,
      );
      await _routineCol(sectionId).doc(cancelledInstance.id).set(cancelledInstance.toJson());
    } else {
      final cancelledId = '${session.id}_cancelled_${date.year}_${date.month}_${date.day}';
      await _routineCol(sectionId).doc(cancelledId).delete();
      await sessionRef.update({'cancelled': false});
    }

    if (notifyStudents) {
      final courseName = session.customCourseName?.isNotEmpty == true
          ? session.customCourseName!
          : (Fixtures.courses.where((c) => c.id == session.courseId).firstOrNull?.compactName ?? 'Class');
      final updateItem = UpdateFeedItem(
        id: 'upd_cancel_${DateTime.now().millisecondsSinceEpoch}',
        eventId: '',
        sessionId: session.id,
        title: cancel
            ? '$courseName cancelled on ${date.day}/${date.month}'
            : '$courseName restored on ${date.day}/${date.month}',
        detail: cancel
            ? 'Scheduled class at ${TimeSlot.formatMin(session.startMinute)} has been marked as cancelled.'
            : 'Class will take place as scheduled at ${TimeSlot.formatMin(session.startMinute)}.',
        at: DateTime.now(),
      );
      await _updatesCol(sectionId).doc(updateItem.id).set(updateItem.toJson());
    }
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
    bool notifyStudents = true,
  }) async {
    final origTimeStr = '${TimeSlot.formatMin(session.startMinute)} – ${TimeSlot.formatMin(session.endMinute)}';

    // 1. Mark original session as shifted/cancelled on sourceDate
    final sourceCancelledInstance = session.copyWith(
      id: '${session.id}_shifted_from_${sourceDate.year}_${sourceDate.month}_${sourceDate.day}',
      cancelled: true,
      specificDate: sourceDate,
    );
    await _routineCol(sectionId).doc(sourceCancelledInstance.id).set(sourceCancelledInstance.toJson());

    // 2. Insert target shifted session on targetDate
    final targetShiftedInstance = session.copyWith(
      id: '${session.id}_shifted_to_${targetDate.year}_${targetDate.month}_${targetDate.day}',
      weekday: targetDate.weekday,
      startMinute: newStartMinute,
      endMinute: newEndMinute,
      room: newRoom ?? session.room,
      specificDate: targetDate,
      isShifted: true,
      cancelled: false,
      originalDate: sourceDate,
      originalTimeLabel: origTimeStr,
    );
    await _routineCol(sectionId).doc(targetShiftedInstance.id).set(targetShiftedInstance.toJson());

    if (notifyStudents) {
      final courseName = session.customCourseName?.isNotEmpty == true
          ? session.customCourseName!
          : (Fixtures.courses.where((c) => c.id == session.courseId).firstOrNull?.compactName ?? 'Class');
      final updateItem = UpdateFeedItem(
        id: 'upd_shift_${DateTime.now().millisecondsSinceEpoch}',
        eventId: '',
        sessionId: session.id,
        title: '$courseName shifted to ${targetDate.day}/${targetDate.month}',
        detail: 'Moved from ${sourceDate.day}/${sourceDate.month} (${TimeSlot.formatMin(session.startMinute)}) to ${targetDate.day}/${targetDate.month} ($origTimeStr).',
        at: DateTime.now(),
      );
      await _updatesCol(sectionId).doc(updateItem.id).set(updateItem.toJson());
    }
  }

  @override
  Future<void> saveTemporaryClass(ClassSession session) async {
    await _routineCol(session.sectionId).doc(session.id).set(session.toJson());

    final courseName = session.customCourseName?.isNotEmpty == true
        ? session.customCourseName!
        : (Fixtures.courses.where((c) => c.id == session.courseId).firstOrNull?.compactName ?? 'Temporary Class');
    final dateStr = session.specificDate != null ? '${session.specificDate!.day}/${session.specificDate!.month}' : 'Scheduled Date';
    final updateItem = UpdateFeedItem(
      id: 'upd_temp_${DateTime.now().millisecondsSinceEpoch}',
      eventId: '',
      sessionId: session.id,
      title: 'Temporary Class: $courseName on $dateStr',
      detail: '${session.isOnline ? "Online class" : "Room ${session.room ?? "TBA"}"} · ${TimeSlot.formatMin(session.startMinute)}–${TimeSlot.formatMin(session.endMinute)}',
      at: DateTime.now(),
    );
    await _updatesCol(session.sectionId).doc(updateItem.id).set(updateItem.toJson());
  }

  @override
  Future<void> deleteTemporaryClass(String sectionId, String sessionId) async {
    await _routineCol(sectionId).doc(sessionId).delete();

    final updateItem = UpdateFeedItem(
      id: 'upd_temp_del_${DateTime.now().millisecondsSinceEpoch}',
      eventId: '',
      sessionId: sessionId,
      title: 'Temporary Class removed',
      detail: 'The temporary class has been removed by class representative.',
      at: DateTime.now(),
    );
    await _updatesCol(sectionId).doc(updateItem.id).set(updateItem.toJson());
  }

  @override
  Future<void> refresh() async {}
}
