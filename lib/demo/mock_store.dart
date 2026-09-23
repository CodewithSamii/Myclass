import 'dart:async';
import '../core/models.dart';
import 'demo_controller.dart';
import 'fixtures.dart';

/// Shared local transport for mock adapters only. UI never imports this store.
class MockStore {
  MockStore(this.demo);
  final DemoController demo;
  UserProfile? profile;
  DateTime updatedAt = DateTime(2026, 9, 21, 10, 42);
  final events = <String, List<AcademicEvent>>{};
  final routines = <String, List<ClassSession>>{};
  final timeSlots = <String, List<TimeSlot>>{};
  final notes = <String, List<PersonalNote>>{};
  final progress = <String, List<PersonalProgress>>{};
  final updates = <String, List<UpdateFeedItem>>{};
  final changes = StreamController<void>.broadcast();
  void notify() => changes.add(null);
  List<AcademicEvent> eventsFor(String section) =>
      events.putIfAbsent(section, () => Fixtures.events(section));
  List<ClassSession> routineFor(String section) =>
      routines.putIfAbsent(section, () => Fixtures.routine(section));
  List<TimeSlot> timeSlotsFor(String section) =>
      timeSlots.putIfAbsent(section, () => [
        const TimeSlot(id: 'ts1', label: '10:00–11:00', startMinute: 600, endMinute: 660, orderIndex: 0),
        const TimeSlot(id: 'ts2', label: '11:00–12:00', startMinute: 660, endMinute: 720, orderIndex: 1),
        const TimeSlot(id: 'ts3', label: '12:00–1:00', startMinute: 720, endMinute: 780, orderIndex: 2),
        const TimeSlot(id: 'ts4', label: '1:00–2:00', startMinute: 780, endMinute: 840, orderIndex: 3),
      ]);

  Future<void> delay() =>
      Future<void>.delayed(const Duration(milliseconds: 260));
  Future<void> checkWrite({bool shared = false, String? section}) async {
    await delay();
    if (demo.consumeSaveFailure()) {
      throw const AppFailure(
        'Your changes could not be saved. Your draft is still here. Try again.',
      );
    }
    if (shared &&
        (profile == null ||
            !profile!.membership.canManage ||
            profile!.activeSectionId != section)) {
      throw const AppFailure(
        'Only a representative of this section can make this change.',
        phase: LoadPhase.permissionDenied,
      );
    }
    if (shared && demo.state.offline) {
      throw const AppFailure(
        'Shared changes need a connection. Reconnect and try again.',
      );
    }
  }

  Stream<T> watch<T>(T Function() read) async* {
    yield read();
    yield* changes.stream.map((_) => read());
  }

  void dispose() => changes.close();
}
