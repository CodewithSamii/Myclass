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
      events.putIfAbsent(section, () => _isPrePopulated(section) ? Fixtures.events(section) : []);
  List<ClassSession> routineFor(String section) =>
      routines.putIfAbsent(section, () => _isPrePopulated(section) ? Fixtures.routine(section) : []);
  List<TimeSlot> timeSlotsFor(String section) =>
      timeSlots.putIfAbsent(section, () => _isPrePopulated(section) ? List.from(Fixtures.defaultTimeSlots) : []);

  bool _isPrePopulated(String section) =>
      section == 'bsc-cse-64-I' || section == 'bsc-cse-64-B';

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
