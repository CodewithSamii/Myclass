import '../core/models.dart';
import '../core/repositories.dart';
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
  Future<void> refresh() async {
    await store.delay();
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }
}
