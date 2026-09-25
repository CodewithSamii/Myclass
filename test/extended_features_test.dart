import 'package:flutter_test/flutter_test.dart';
import 'package:myclass/core/models.dart';
import 'package:myclass/core/clock.dart';
import 'package:myclass/core/format.dart';
import 'package:myclass/demo/demo_controller.dart';
import 'package:myclass/demo/mock_store.dart';
import 'package:myclass/demo/mock_schedule_repository.dart';
import 'package:myclass/demo/fixtures.dart';
import 'package:myclass/features/home/models/agenda_projection.dart';
import 'package:myclass/features/profile/models/user_profile.dart';
import 'support/harness.dart';

void main() {
  const section = 'bsc-cse-64-I';
  late DemoController demo;
  late MockStore store;
  late MockScheduleRepository scheduleRepo;

  setUp(() {
    demo = DemoController();
    store = MockStore(demo);
    store.profile = sampleProfile(role: UserRole.sectionAdmin);
    scheduleRepo = MockScheduleRepository(store);
  });

  tearDown(() async {
    store.dispose();
    await demo.close();
  });

  group('Feature 1: Class Cancellation & Class Shift', () {
    test('cancels class for a specific date without deleting routine, and notifies students', () async {
      final initialRoutine = store.routineFor(section);
      final firstSession = initialRoutine.first;
      final targetDate = DateTime(2026, 9, 21); // Monday

      await scheduleRepo.cancelSessionOnDate(
        sectionId: section,
        session: firstSession,
        date: targetDate,
        cancel: true,
      );

      // Verify notification in store updates
      final updates = store.updates[section]!;
      expect(updates.first.title, contains('cancelled on'));

      // Check projection for targetDate
      final courses = await scheduleRepo.courses(section);
      final routine = store.routineFor(section);
      final dayEntries = AgendaProjection.day(
        day: targetDate,
        sessions: routine,
        events: store.eventsFor(section),
        courses: courses,
      );

      final entry = dayEntries.firstWhere((e) => e.course.id == firstSession.courseId);
      expect(entry.cancelled, isTrue);

      // Restoring class
      await scheduleRepo.cancelSessionOnDate(
        sectionId: section,
        session: firstSession,
        date: targetDate,
        cancel: false,
      );
      expect(store.updates[section]!.first.title, contains('restored on'));
    });

    test('AgendaProjection.isAllCancelled detects when all classes on a day are cancelled', () {
      final session1 = ClassSession(
        id: 's1',
        sectionId: section,
        courseId: 'c1',
        weekday: 1,
        startMinute: 540,
        endMinute: 605,
        cancelled: true,
      );
      final session2 = ClassSession(
        id: 's2',
        sectionId: section,
        courseId: 'c2',
        weekday: 1,
        startMinute: 605,
        endMinute: 670,
        cancelled: true,
      );
      final day = DateTime(2026, 9, 21);
      final entries = [
        AgendaEntry(at: session1.startOn(day), course: const Course(id: 'c1', name: 'Course 1', facultyId: '', departmentId: ''), session: session1, day: day),
        AgendaEntry(at: session2.startOn(day), course: const Course(id: 'c2', name: 'Course 2', facultyId: '', departmentId: ''), session: session2, day: day),
      ];

      expect(AgendaProjection.isAllCancelled(entries), isTrue);
    });

    test('shifts class to another date/slot, preserves class info, transfers attached events, and notifies students', () async {
      final initialRoutine = store.routineFor(section);
      final session = initialRoutine.first;
      final sourceDate = DateTime(2026, 9, 21);
      final targetDate = DateTime(2026, 9, 23);

      // Attach a test event to this course on sourceDate
      final events = store.eventsFor(section);
      events.add(
        AcademicEvent(
          id: 'test-event-shift',
          title: 'Quiz 1',
          type: AcademicEventType.quiz,
          courseId: session.courseId,
          date: sourceDate,
          sectionId: section,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
          startsAt: session.startOn(sourceDate),
          endsAt: session.endOn(sourceDate),
        ),
      );

      await scheduleRepo.shiftSession(
        sectionId: section,
        session: session,
        sourceDate: sourceDate,
        targetDate: targetDate,
        newStartMinute: 15 * 60 + 30, // 3:30 PM unusual time
        newEndMinute: 16 * 60 + 45,
        newRoom: 'Room 501',
      );

      // 1. Attached event was transferred to targetDate
      final shiftedEvent = events.firstWhere((e) => e.id == 'test-event-shift');
      expect(sameDay(shiftedEvent.date, targetDate), isTrue);
      expect(shiftedEvent.startsAt?.hour, 15);
      expect(shiftedEvent.startsAt?.minute, 30);

      // 2. Notification created
      final updates = store.updates[section]!;
      expect(updates.first.title, contains('shifted to'));

      // 3. Shifted class projected on targetDate
      final courses = await scheduleRepo.courses(section);
      final targetEntries = AgendaProjection.day(
        day: targetDate,
        sessions: store.routineFor(section),
        events: events,
        courses: courses,
      );
      final shiftedEntry = targetEntries.firstWhere((e) => e.isShifted && e.at.hour == 15);
      expect(shiftedEntry.isShifted, isTrue);
      expect(shiftedEntry.originalTimeLabel, contains(Fmt.weekday(sourceDate)));
    });
  });

  group('Feature 2: Temporary / Extra Class', () {
    test('creates and deletes temporary class without altering weekly routine matrix', () async {
      final initialRoutineLength = store.routineFor(section).length;
      final tempDate = DateTime(2026, 9, 27); // Sunday
      final tempSession = ClassSession(
        id: 'temp-12345',
        sectionId: section,
        courseId: 'custom-extra-algo',
        weekday: tempDate.weekday,
        startMinute: 10 * 60,
        endMinute: 11 * 60 + 30,
        isOnline: true,
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        notes: 'Special guest lecture on Dynamic Programming',
        specificDate: tempDate,
        isTemporary: true,
        customCourseName: 'Advanced Algorithms Extra Class',
        facultyName: 'Dr. Tariq',
      );

      await scheduleRepo.saveTemporaryClass(tempSession);

      // Check notification
      final updates = store.updates[section]!;
      expect(updates.first.title, contains('Temporary Class'));

      // Check Sunday agenda
      final courses = await scheduleRepo.courses(section);
      final sundayEntries = AgendaProjection.day(
        day: tempDate,
        sessions: store.routineFor(section),
        events: store.eventsFor(section),
        courses: courses,
      );
      final entry = sundayEntries.firstWhere((e) => e.isTemporary);
      expect(entry.title, 'Advanced Algorithms Extra Class');
      expect(entry.isOnline, isTrue);
      expect(entry.location, 'https://meet.google.com/abc-defg-hij');
      expect(entry.typeLabel, 'Temporary Class');

      // Delete temporary class
      await scheduleRepo.deleteTemporaryClass(section, tempSession.id);
      expect(store.updates[section]!.first.title, contains('Temporary Class removed'));
      expect(store.routineFor(section).length, initialRoutineLength);
    });
  });

  group('Feature 3: Smart Bus Reminders & Preferences', () {
    test('saves bus reminder preference for student profile', () {
      final profile = sampleProfile();
      expect(profile.reminders.busReminderMinutes, 15); // default 15m

      final updated = profile.copyWith(
        reminders: profile.reminders.copyWith(busReminderMinutes: 60),
      );
      expect(updated.reminders.busReminderMinutes, 60);

      final json = updated.reminders.toJson();
      expect(json['bus'], 60);

      final fromJson = ReminderPreference.fromJson(json);
      expect(fromJson.busReminderMinutes, 60);
    });
  });
}
