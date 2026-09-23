import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sami_p/core/models.dart';
import 'package:sami_p/shared/workspace_shell.dart';
import 'package:sami_p/features/events/bloc/events_bloc.dart';
import 'package:sami_p/features/events/views/event_detail_page.dart';
import 'package:sami_p/features/notes/bloc/notes_bloc.dart';
import 'package:sami_p/features/profile/bloc/profile_bloc.dart';
import 'package:sami_p/features/tasks/bloc/tasks_bloc.dart';
import 'package:sami_p/features/schedule/bloc/schedule_bloc.dart';
import 'package:sami_p/features/section_admin/views/event_editor_page.dart';
import 'package:sami_p/features/campus/views/faculty_page.dart';
import 'package:sami_p/features/campus/views/bus_page.dart';
import 'package:sami_p/demo/demo_controller.dart';
import 'package:sami_p/demo/fixtures.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  testWidgets(
    'onboarding verifies section, mock Google saves profile, and sign out returns to login',
    (tester) async {
      final d = await boot(tester, signedIn: false);
      await tester.tap(find.text('Get started'));
      await settle(tester);
      await tester.enterText(find.byType(TextFormField), 'Navid');
      await tester.tap(find.text('Choose program type'));
      await settle(tester);
      await tester.tap(find.text('Undergraduate'));
      await settle(tester);
      await tester.tap(find.text('Choose department'));
      await settle(tester);
      await tester.tap(find.text('Computer Science & Engineering'));
      await settle(tester);
      await tester.tap(find.text('Choose program'));
      await settle(tester);
      await tester.tap(find.text('B.Sc. in Computer Science & Engineering'));
      await settle(tester);
      await tester.ensureVisible(find.text('Choose batch'));
      await tester.tap(find.text('Choose batch'));
      await settle(tester);
      await tester.tap(find.text('Batch 64'));
      await settle(tester);
      await tester.ensureVisible(find.text('Choose section'));
      await tester.tap(find.text('Choose section'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).last, 'Section I');
      await settle(tester);
      await tester.tap(find.text('Section I').last);
      await settle(tester);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await capture(tester, '22-section-verification');
      await tester.enterText(find.byType(TextField), 'WRONG');
      await tester.ensureVisible(find.text('Join this section'));
      await tester.tap(find.text('Join this section'));
      await settle(tester);
      expect(find.textContaining('That code did not match'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'AULA64');
      await tester.tap(find.text('Join this section'));
      await settle(tester);
      await capture(tester, '23-save-setup');
      await tester.ensureVisible(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await settle(tester);
      expect(find.text('HAPPENING NOW'), findsOneWidget);
      expect(find.text('Monday, 21'), findsOneWidget);
      expect(
        tester
            .element(find.byType(WorkspaceShell))
            .read<ProfileBloc>()
            .state
            .profile
            .membership
            .departmentId,
        'cse',
      );
      await tester.tap(find.text('Profile').last);
      await settle(tester);
      await tester.drag(
        find.byKey(const PageStorageKey('profile')),
        const Offset(0, -650),
      );
      await settle(tester);
      await tester.ensureVisible(find.text('Sign out'));
      await settle(tester);
      await tester.tap(find.text('Sign out'));
      await settle(tester);
      await tester.tap(find.text('Sign out').last);
      await settle(tester);
      expect(find.text('Back to your space.'), findsOneWidget);
      await tester.tap(find.text('Continue with Google'));
      await settle(tester);
      expect(find.text('HAPPENING NOW'), findsOneWidget);
      await finish(tester, d);
    },
  );
  testWidgets(
    'CR creates an event, handles failed save, reschedules and cancels',
    (tester) async {
      final d = await boot(tester, role: UserRole.sectionAdmin);
      await push(tester, const EventEditorPage());
      await tester.enterText(
        find.byType(TextFormField).first,
        'Database assignment 04',
      );
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Joins\nNormalization\nIndex design',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Submit one PDF with your student ID.',
      );
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await capture(tester, '24-event-review');
      d.demo.failSave();
      await tester.ensureVisible(find.text('Add to section'));
      await tester.tap(find.text('Add to section'));
      await settle(tester);
      expect(find.textContaining('draft is still here'), findsOneWidget);
      await tester.ensureVisible(find.text('Add to section'));
      await tester.tap(find.text('Add to section'));
      await settle(tester);
      final context = tester.element(find.byType(WorkspaceShell));
      final events = context.read<EventsBloc>();
      final added = events.state.items.singleWhere(
        (e) => e.title == 'Database assignment 04',
      );
      expect(added.syllabus.length, 3);
      await push(tester, EventEditorPage(event: added, postpone: true));
      await tester.ensureVisible(find.text('Tuesday · Sep 22'));
      await tester.tap(find.text('Tuesday · Sep 22'));
      await settle(tester);
      await tester.tap(find.text('25').last);
      await tester.tap(find.text('OK'));
      await settle(tester);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await settle(tester);
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await settle(tester);
      expect(events.state.byId(added.id)!.date, DateTime(2026, 9, 25));
      expect(events.state.byId(added.id)!.status, EventStatus.postponed);
      events.add(
        EventStatusRequested(
          events.state.byId(added.id)!,
          EventStatus.cancelled,
          d.demo.now,
        ),
      );
      await settle(tester);
      expect(events.state.byId(added.id)!.status, EventStatus.cancelled);
      await push(tester, EventDetailPage(id: added.id));
      expect(
        find.textContaining('This event has been cancelled'),
        findsOneWidget,
      );
      await capture(tester, '25-cancelled-event');
      await back(tester);
      await finish(tester, d);
    },
  );
  testWidgets(
    'private notes, reminders, completion and schedule selection work',
    (tester) async {
      final d = await boot(tester);
      final ctx = tester.element(find.byType(WorkspaceShell));
      final schedule = ctx.read<ScheduleBloc>();
      await tester.tap(find.text('Schedule').last);
      await settle(tester);
      schedule.add(ScheduleDateSelected(DateTime(2026, 9, 23)));
      await settle(tester);
      await tester.tap(find.text('Tasks').last);
      await settle(tester);
      await tester.tap(find.text('Schedule').last);
      await settle(tester);
      expect(schedule.state.selected, DateTime(2026, 9, 23));
      await push(
        tester,
        const EventDetailPage(id: 'bsc-cse-64-I-network-viva'),
      );
      await tester.scrollUntilVisible(
        find.text('Mark my preparation done'),
        350,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Mark my preparation done'));
      await settle(tester);
      expect(
        ctx
            .read<TasksBloc>()
            .state
            .forEvent('bsc-cse-64-I-network-viva')
            .completed,
        isTrue,
      );
      await tester.tap(find.text('Remind me'));
      await settle(tester);
      await capture(tester, '26-reminder-selector');
      await tester.tap(find.text('1 hour'));
      await tester.ensureVisible(find.text('Save reminders'));
      await tester.tap(find.text('Save reminders'));
      await settle(tester);
      expect(
        ctx
            .read<TasksBloc>()
            .state
            .forEvent('bsc-cse-64-I-network-viva')
            .reminderOffsets,
        contains(60),
      );
      await tester.scrollUntilVisible(
        find.text('Edit').last,
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Edit').last);
      await settle(tester);
      await tester.enterText(
        find.byType(TextField),
        'Review IPv4 subnetting and bring the report.',
      );
      await tester.ensureVisible(find.text('Save note'));
      await tester.tap(find.text('Save note'));
      await settle(tester);
      expect(
        ctx.read<NotesBloc>().state.items.any(
          (n) => n.text.contains('Review IPv4'),
        ),
        isTrue,
      );
      await back(tester);
      await finish(tester, d);
    },
  );
  testWidgets('compact phone and enlarged text remain usable', (tester) async {
    final d = await boot(tester, size: const Size(320, 720));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    await settle(tester);
    await capture(tester, '27-large-text-home');
    for (final tab in ['Schedule', 'Tasks', 'Campus', 'Profile']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: '$tab at 320px, 150% text',
      );
    }
    await push(tester, FacultyProfilePage(member: Fixtures.faculty[5]));
    await capture(tester, '28-long-faculty-name');
    await back(tester);
    await push(tester, BusRouteDetailPage(route: Fixtures.routes.last));
    await capture(tester, '29-large-text-bus');
    await back(tester);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await finish(tester, d);
  });
  testWidgets(
    'all home scenarios preserve readable data with offline and missing routine states',
    (tester) async {
      final d = await boot(tester);
      for (final scenario in DemoScenario.values) {
        d.demo.scenario(scenario);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: scenario.name);
      }
      d.demo.scenario(DemoScenario.inClass);
      d.demo.offline(true);
      await settle(tester);
      expect(find.text('Offline · Showing saved schedule'), findsOneWidget);
      await capture(tester, '30-offline-home');
      await finish(tester, d);
    },
  );
}
