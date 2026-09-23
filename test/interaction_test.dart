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
    'section entry modal verifies password, logs into section, and switch section logs out',
    (tester) async {
      final d = await boot(tester, signedIn: false);
      expect(find.text('Enter Classroom / Join'), findsWidgets);
      await tester.tap(find.text('Enter Classroom / Join').first);
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      await capture(tester, '22-section-entry-sheet');

      // Enter wrong password
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Enter Classroom').last);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Enter Classroom').last);
      await settle(tester);
      expect(find.textContaining('Incorrect Student Password'), findsOneWidget);

      // Enter valid student password ('123')
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Enter Classroom').last);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Enter Classroom').last);
      await settle(tester);
      await capture(tester, '23-logged-in-schedule');

      // Check Schedule tab is now visible and active
      expect(find.text('Schedule'), findsWidgets);
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

      // Open drawer to Switch Section / Logout
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await settle(tester);
      await tester.tap(find.text('Switch Section / Logout'));
      await settle(tester);

      // Now back to guest mode
      expect(find.text('Join or Create Classroom'), findsWidgets);
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
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await settle(tester);
      await tester.tap(find.text('Home').last);
      await settle(tester);

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
