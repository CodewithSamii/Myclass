import 'package:flutter_test/flutter_test.dart';
import 'package:myclass/core/models.dart';

void main() {
  group('Firestore Models Serialization Tests', () {
    test('AcademicEvent roundtrip serialization', () {
      final original = AcademicEvent(
        id: 'test-event-1',
        title: 'Midterm Exam',
        type: AcademicEventType.exam,
        courseId: 'cse3115',
        date: DateTime(2026, 9, 25),
        sectionId: 'bsc-cse-64-I',
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 21),
        startsAt: DateTime(2026, 9, 25, 10, 0),
        endsAt: DateTime(2026, 9, 25, 12, 0),
        deadline: null,
        location: 'Room 401',
        syllabus: const ['Chapter 1', 'Chapter 2'],
        status: EventStatus.scheduled,
        instructions: 'Bring your student ID.',
      );

      final json = original.toJson();
      final restored = AcademicEvent.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.type, original.type);
      expect(restored.courseId, original.courseId);
      expect(restored.date, original.date);
      expect(restored.sectionId, original.sectionId);
      expect(restored.location, original.location);
      expect(restored.syllabus, original.syllabus);
      expect(restored.status, original.status);
      expect(restored.instructions, original.instructions);
    });

    test('ClassSession roundtrip serialization', () {
      const original = ClassSession(
        id: 'test-session-1',
        sectionId: 'bsc-cse-64-I',
        courseId: 'cse3213',
        weekday: 1,
        startMinute: 540,
        endMinute: 605,
        room: 'RKB-407',
        isLab: false,
        isOnline: false,
        customCourseName: 'Software Engineering',
        facultyName: 'Dr. Ahmed',
      );

      final json = original.toJson();
      final restored = ClassSession.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.sectionId, original.sectionId);
      expect(restored.courseId, original.courseId);
      expect(restored.weekday, original.weekday);
      expect(restored.startMinute, original.startMinute);
      expect(restored.endMinute, original.endMinute);
      expect(restored.room, original.room);
      expect(restored.customCourseName, original.customCourseName);
      expect(restored.facultyName, original.facultyName);
    });

    test('UserProfile roundtrip serialization', () {
      const membership = SectionMembership(
        sectionId: 'bsc-cse-64-I',
        programId: 'bsc-cse',
        batchId: '64',
        programName: 'B.Sc. in CSE',
        batchName: '64th Batch',
        sectionName: 'Section I',
        role: UserRole.sectionAdmin,
      );

      const original = UserProfile(
        uid: 'usr-1',
        name: 'Sami',
        email: 'sami@example.com',
        activeSectionId: 'bsc-cse-64-I',
        memberships: [membership],
      );

      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.uid, original.uid);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.activeSectionId, original.activeSectionId);
      expect(restored.memberships.length, 1);
      expect(restored.memberships.first.role, UserRole.sectionAdmin);
    });

    test('PersonalNote roundtrip serialization', () {
      final original = PersonalNote(
        id: 'note-1',
        uid: 'usr-1',
        text: 'Review UML state machine chapter.',
        updatedAt: DateTime(2026, 9, 21, 15, 30),
      );

      final json = original.toJson();
      final restored = PersonalNote.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.uid, original.uid);
      expect(restored.text, original.text);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('PersonalProgress roundtrip serialization', () {
      const original = PersonalProgress(
        eventId: 'event-101',
        completed: true,
        reminderOffsets: [15, 60],
      );

      final json = original.toJson();
      final restored = PersonalProgress.fromJson(json);

      expect(restored.eventId, original.eventId);
      expect(restored.completed, isTrue);
      expect(restored.reminderOffsets, const [15, 60]);
    });

    test('TimeSlot roundtrip serialization', () {
      const original = TimeSlot(
        id: 'ts1',
        label: '9:00–10:05',
        startMinute: 540,
        endMinute: 605,
        orderIndex: 0,
      );

      final json = original.toJson();
      final restored = TimeSlot.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.label, original.label);
      expect(restored.startMinute, original.startMinute);
      expect(restored.endMinute, original.endMinute);
      expect(restored.orderIndex, original.orderIndex);
    });

    test('AcademicPeriod roundtrip serialization', () {
      final original = AcademicPeriod(
        title: 'Midterm Break',
        start: DateTime(2026, 9, 24),
        end: DateTime(2026, 10, 1),
        classesSuspended: true,
      );

      final json = original.toJson();
      final restored = AcademicPeriod.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.start, original.start);
      expect(restored.end, original.end);
      expect(restored.classesSuspended, isTrue);
    });

    test('UpdateFeedItem roundtrip serialization', () {
      final original = UpdateFeedItem(
        id: 'upd-1',
        eventId: 'event-1',
        title: 'Room Changed',
        detail: 'Room 401 to Room 407',
        at: DateTime(2026, 9, 21, 10, 0),
      );

      final json = original.toJson();
      final restored = UpdateFeedItem.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.eventId, original.eventId);
      expect(restored.title, original.title);
      expect(restored.detail, original.detail);
      expect(restored.at, original.at);
    });
  });
}
