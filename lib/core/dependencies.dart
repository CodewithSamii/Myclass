import 'package:shared_preferences/shared_preferences.dart';
import 'repositories.dart';
import 'clock.dart';
import '../demo/demo_controller.dart';
import '../demo/mock_store.dart';
import '../demo/mock_auth_repository.dart';
import '../demo/mock_academic_structure_repository.dart';
import '../demo/mock_event_repository.dart';
import '../demo/mock_schedule_repository.dart';
import '../demo/mock_personal_repositories.dart';
import '../demo/mock_campus_repositories.dart';
import '../demo/mock_search_repository.dart';

/// Composition root. Substitute adapters here when connecting real services.
class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.structure,
    required this.events,
    required this.schedule,
    required this.profiles,
    required this.progress,
    required this.notes,
    required this.buses,
    required this.faculty,
    required this.search,
    required this.demo,
    required this.clock,
    void Function()? dispose,
  }) : _dispose = dispose;

  final AuthRepository auth;
  final AcademicStructureRepository structure;
  final EventRepository events;
  final ScheduleRepository schedule;
  final ProfileRepository profiles;
  final ProgressRepository progress;
  final NotesRepository notes;
  final BusRepository buses;
  final FacultyRepository faculty;
  final SearchRepository search;
  final DemoController demo;
  final AppClock clock;
  final void Function()? _dispose;

  factory AppDependencies.mock(SharedPreferences preferences) {
    final demo = DemoController();
    final store = MockStore(demo);
    final subscription = demo.stream.listen((_) => store.notify());
    return AppDependencies(
      auth: MockAuthRepository(preferences),
      structure: MockAcademicStructureRepository(),
      events: MockEventRepository(store),
      schedule: MockScheduleRepository(store),
      profiles: MockProfileRepository(store, preferences),
      progress: MockProgressRepository(store),
      notes: MockNotesRepository(store),
      buses: MockBusRepository(),
      faculty: MockFacultyRepository(),
      search: MockSearchRepository(store),
      demo: demo,
      clock: demo,
      dispose: () {
        subscription.cancel();
        store.dispose();
        demo.close();
      },
    );
  }

  factory AppDependencies.firebase({
    required SharedPreferences preferences,
    AuthRepository? auth,
    AcademicStructureRepository? structure,
    EventRepository? events,
    ScheduleRepository? schedule,
    ProfileRepository? profiles,
    ProgressRepository? progress,
    NotesRepository? notes,
    BusRepository? buses,
    FacultyRepository? faculty,
    SearchRepository? search,
    DemoController? demo,
    AppClock? clock,
  }) {
    final defaultDemo = demo ?? DemoController();
    final defaultStore = MockStore(defaultDemo);
    final subscription = defaultDemo.stream.listen((_) => defaultStore.notify());
    return AppDependencies(
      auth: auth ?? FirebaseAuthRepository(preferences: preferences),
      structure: structure ?? FirestoreAcademicStructureRepository(),
      events: events ?? FirestoreEventRepository(),
      schedule: schedule ?? FirestoreScheduleRepository(),
      profiles: profiles ?? FirestoreProfileRepository(preferences: preferences),
      progress: progress ?? FirestoreProgressRepository(),
      notes: notes ?? FirestoreNotesRepository(),
      buses: buses ?? MockBusRepository(),
      faculty: faculty ?? MockFacultyRepository(),
      search: search ?? MockSearchRepository(defaultStore),
      demo: defaultDemo,
      clock: clock ?? defaultDemo,
      dispose: () {
        subscription.cancel();
        defaultStore.dispose();
        defaultDemo.close();
      },
    );
  }

  void dispose() => _dispose?.call();
}
