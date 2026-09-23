import 'package:flutter_test/flutter_test.dart';
import 'package:sami_p/core/models.dart';
import 'package:sami_p/core/clock.dart';
import 'package:sami_p/demo/demo_controller.dart';
import 'package:sami_p/demo/mock_store.dart';
import 'package:sami_p/demo/mock_academic_structure_repository.dart';
import 'package:sami_p/demo/mock_event_repository.dart';
import 'package:sami_p/demo/mock_personal_repositories.dart';
import 'package:sami_p/demo/mock_schedule_repository.dart';
import 'package:sami_p/demo/mock_search_repository.dart';
import 'package:sami_p/demo/fixtures.dart';
import 'package:sami_p/features/home/models/agenda_projection.dart';
import 'package:sami_p/features/section_admin/bloc/event_editor_bloc.dart';
import 'package:sami_p/features/search/bloc/search_bloc.dart';
import 'package:sami_p/features/tasks/models/task_projection.dart';
import 'package:sami_p/features/tasks/bloc/tasks_bloc.dart';
import 'package:sami_p/features/schedule/bloc/schedule_bloc.dart';
import 'support/harness.dart';

void main() {
  const section = 'bsc-cse-64-I';
  late DemoController demo;
  late MockStore store;
  setUp(() {
    demo = DemoController();
    store = MockStore(demo);
    store.profile = sampleProfile();
  });
  tearDown(() async {
    store.dispose();
    await demo.close();
  });
  test(
    'section code verification returns a grant and rejects a wrong code',
    () async {
      final repo = MockAcademicStructureRepository();
      await expectLater(
        repo.verifyAccess(section, 'wrong'),
        throwsA(isA<AppFailure>()),
      );
      final grant = await repo.verifyAccess(section, ' aula64 ');
      expect(grant.sectionId, section);
      expect(grant.token, 'mock-opaque-grant');
    },
  );
  test('structure supports postgraduate business and law sections', () async {
    final repo = MockAcademicStructureRepository();
    final programs = await repo.programs('bba', 'Postgraduate');
    expect(programs.single.id, 'mba');
    final batches = await repo.batches(programs.single.id);
    final sections = await repo.sections(batches.first.id);
    expect(sections.length, 9);
    expect(
      Fixtures.coursesFor(
        sections.first.id,
      ).every((c) => c.departmentId == 'bba'),
      isTrue,
    );
    expect((await repo.programs('law', 'Postgraduate')).single.id, 'llm');
  });
  test('students cannot mutate shared events or routines', () async {
    final events = MockEventRepository(store);
    final original = store.eventsFor(section).first;
    await expectLater(
      events.save(original.copyWith(title: 'Unauthorized change')),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.phase,
          'phase',
          LoadPhase.permissionDenied,
        ),
      ),
    );
    await expectLater(
      MockScheduleRepository(
        store,
      ).saveSession(store.routineFor(section).first.copyWith(room: '999')),
      throwsA(isA<AppFailure>()),
    );
    expect(store.eventsFor(section).first, original);
  });
  test('personal completion never mutates a shared event', () async {
    final original = store.eventsFor(section).first;
    final progress = MockProgressRepository(store);
    await progress.save(
      'demo-student',
      PersonalProgress(eventId: original.id, completed: true),
    );
    expect(store.eventsFor(section).first, original);
    expect(
      (await progress.watch('demo-student').first).single.completed,
      isTrue,
    );
    expect((await progress.watch('other-student').first), isEmpty);
  });
  test(
    'private note writes reject a different user and search scopes notes',
    () async {
      final notes = MockNotesRepository(store);
      await expectLater(
        notes.save(
          PersonalNote(
            id: 'n',
            uid: 'other',
            text: 'Secret',
            updatedAt: demo.now,
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
      await notes.save(
        PersonalNote(
          id: 'n',
          uid: 'demo-student',
          text: 'Subnetting practice',
          updatedAt: demo.now,
        ),
      );
      final search = MockSearchRepository(store);
      expect(
        (await search.search(
          'Subnetting practice',
          uid: 'other',
          sectionId: section,
        )),
        isEmpty,
      );
      expect(
        (await search.search(
          'Subnetting practice',
          uid: 'demo-student',
          sectionId: section,
        )).length,
        1,
      );
    },
  );
  test(
    'failed event save retains a draft and retry updates shared history',
    () async {
      store.profile = sampleProfile(role: UserRole.sectionAdmin);
      final repo = MockEventRepository(store);
      final original = store.eventsFor(section).first;
      final bloc = EventEditorBloc(
        repository: repo,
        draft: original,
        original: original,
        now: demo.now,
      );
      bloc.add(EditorChanged(EditorField.title, 'Revised AI viva'));
      await Future<void>.delayed(Duration.zero);
      demo.failSave();
      bloc.add(EditorSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 340));
      expect(bloc.state.error, isNotNull);
      expect(bloc.state.draft.title, 'Revised AI viva');
      expect(store.eventsFor(section).first.title, original.title);
      bloc.add(EditorSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 340));
      expect(bloc.state.saved, isTrue);
      expect(store.eventsFor(section).first.title, 'Revised AI viva');
      expect(
        store.eventsFor(section).first.changeHistory.last.label,
        'Title changed',
      );
      await bloc.close();
    },
  );
  test(
    'cancelled events stay in the schedule and are excluded from conflicts',
    () {
      final courses = Fixtures.coursesFor(section);
      final events = store.eventsFor(section);
      final day = DateTime(2026, 9, 23);
      final agenda = AgendaProjection.day(
        day: day,
        sessions: store.routineFor(section),
        events: events,
        courses: courses,
      );
      expect(
        agenda.any((e) => e.event?.status == EventStatus.cancelled),
        isTrue,
      );
      expect(
        AgendaProjection.conflicts(agenda).any((e) => e.cancelled),
        isFalse,
      );
    },
  );
  test('busy days preserve three deadlines and overlapping assessments', () {
    final agenda = AgendaProjection.day(
      day: DateTime(2026, 9, 22),
      sessions: store.routineFor(section),
      events: store.eventsFor(section),
      courses: Fixtures.coursesFor(section),
    );
    expect(agenda.where((e) => e.deadline).length, 3);
    expect(
      agenda.where((e) => e.event?.type == AcademicEventType.viva).length,
      2,
    );
    expect(AgendaProjection.conflicts(agenda).length, greaterThanOrEqualTo(3));
  });
  test('unknown exam time remains TBA and is not treated as midnight', () {
    final agenda = AgendaProjection.day(
      day: DateTime(2026, 9, 30),
      sessions: [],
      events: store.eventsFor(section),
      courses: Fixtures.coursesFor(section),
    );
    expect(agenda.single.timeUnknown, isTrue);
    expect(agenda.single.timeLabel, 'TBA');
  });
  test(
    'academic calendar suspends recurring classes without removing exam events',
    () async {
      final periods = await MockScheduleRepository(store).periods(section);
      final agenda = AgendaProjection.day(
        day: DateTime(2026, 9, 24),
        sessions: store.routineFor(section),
        events: store.eventsFor(section),
        courses: Fixtures.coursesFor(section),
        periods: periods,
      );
      expect(agenda.where((e) => e.session != null), isEmpty);
      expect(agenda.single.event!.type, AcademicEventType.exam);
    },
  );
  test(
    'home adapts to current class, deadline-only day, exam tomorrow and clear day',
    () async {
      final periods = await MockScheduleRepository(store).periods(section);
      for (final pair in [
        (DemoScenario.inClass, 'Happening now'),
        (DemoScenario.deadlinesOnly, 'One thing to finish'),
        (DemoScenario.examTomorrow, 'Prepare for tomorrow'),
        (DemoScenario.weekend, 'Room to breathe'),
      ]) {
        demo.scenario(pair.$1);
        final now = demo.now;
        List<AgendaEntry> day(DateTime d) => AgendaProjection.day(
          day: d,
          sessions: store.routineFor(section),
          events: store.eventsFor(section),
          courses: Fixtures.coursesFor(section),
          periods: periods,
        );
        final projection = HomeProjection(
          now: now,
          today: day(now),
          tomorrow: day(now.add(const Duration(days: 1))),
          events: store.eventsFor(section),
          progress: [],
        );
        expect(projection.headline, pair.$2);
      }
    },
  );
  test('reminder inheritance is distinct from opting out', () async {
    final repo = MockProgressRepository(store);
    const inherited = PersonalProgress(eventId: 'event');
    expect(inherited.reminderOffsets, isNull);
    await repo.save('demo-student', inherited.copyWith(reminderOffsets: []));
    expect(
      (await repo.watch('demo-student').first).single.reminderOffsets,
      isEmpty,
    );
    await repo.save(
      'demo-student',
      inherited.copyWith(reminderOffsets: [60]).copyWith(inherit: true),
    );
    expect(
      (await repo.watch('demo-student').first).single.reminderOffsets,
      isNull,
    );
  });
  test(
    'offline feed remains readable and shared writes fail explicitly',
    () async {
      store.profile = sampleProfile(role: UserRole.sectionAdmin);
      demo.offline(true);
      final repo = MockEventRepository(store);
      final feed = await repo.watchEvents(section).first;
      expect(feed.offline, isTrue);
      expect(feed.items, isNotEmpty);
      await expectLater(
        repo.save(feed.items.first.copyWith(title: 'Offline write')),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test('task groups separate personal completion from shared status', () {
    final event = store.eventsFor(section).first;
    final state = TasksState(
      progress: [PersonalProgress(eventId: event.id, completed: true)],
    );
    final pending = TaskProjection.groups(
      store.eventsFor(section),
      state,
      Fixtures.coursesFor(section),
      demo.now,
    );
    expect(
      pending.values.expand((v) => v).any((v) => v.id == event.id),
      isFalse,
    );
    final complete = TaskProjection.groups(
      store.eventsFor(section),
      state.copyWith(showCompleted: true),
      Fixtures.coursesFor(section),
      demo.now,
    );
    expect(
      complete.values.expand((v) => v).any((v) => v.id == event.id),
      isTrue,
    );
  });
  test('search discards old query results', () async {
    final bloc = SearchBloc(
      MockSearchRepository(store),
      'demo-student',
      section,
    );
    bloc.add(SearchQueryChanged('viva'));
    await Future<void>.delayed(const Duration(milliseconds: 280));
    bloc.add(SearchQueryChanged('Route 2'));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(bloc.state.query, 'Route 2');
    expect(bloc.state.hits.single.title, contains('Route 2'));
    await bloc.close();
  });
  test(
    'async course load preserves an already streamed class routine',
    () async {
      final bloc = ScheduleBloc(MockScheduleRepository(store), demo, section);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(bloc.state.sessions.length, 14);
      expect(bloc.state.courses, isNotEmpty);
      expect(bloc.state.periods, isNotEmpty);
      await bloc.close();
    },
  );
  test('rapid personal completion toggles are serialized', () async {
    final bloc = TasksBloc(MockProgressRepository(store), 'demo-student');
    await Future<void>.delayed(Duration.zero);
    bloc.add(TaskToggled('event'));
    bloc.add(TaskToggled('event'));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(bloc.state.forEvent('event').completed, isFalse);
    await bloc.close();
  });
  test('week starts on Sunday and preserves month boundaries', () {
    expect(weekStart(DateTime(2026, 10, 1)), DateTime(2026, 9, 27));
  });
}
