import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sami_p/core/models.dart';
import 'package:sami_p/features/events/views/event_detail_page.dart';
import 'package:sami_p/features/campus/views/bus_page.dart';
import 'package:sami_p/features/campus/views/faculty_page.dart';
import 'package:sami_p/features/schedule/views/routine_page.dart';
import 'package:sami_p/features/profile/views/notification_page.dart';
import 'package:sami_p/features/notes/views/notes_page.dart';
import 'package:sami_p/features/section_admin/views/event_editor_page.dart';
import 'package:sami_p/features/search/views/search_page.dart';
import 'package:sami_p/demo/fixtures.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  testWidgets('student phone journey renders all major destinations', (
    tester,
  ) async {
    final d = await boot(tester);
    expect(find.text('Monday, 21'), findsOneWidget);
    expect(find.text('HAPPENING NOW'), findsOneWidget);
    expect(find.text('Artificial Intelligence'), findsWidgets);
    await capture(tester, '01-home-light');
    for (final pair in [
      ('Schedule', '02-schedule-week'),
      ('Tasks', '03-tasks'),
      ('Campus', '04-campus'),
      ('Profile', '05-profile'),
    ]) {
      await tester.tap(find.text(pair.$1).last);
      await settle(tester);
      await capture(tester, pair.$2);
    }
    await tester.tap(find.text('Home').last);
    await settle(tester);
    await push(tester, const EventDetailPage(id: 'bsc-cse-64-I-network-viva'));
    await capture(tester, '06-event-detail');
    await back(tester);
    await push(tester, const RoutinePage());
    await capture(tester, '07-routine');
    await back(tester);
    await push(tester, const BusPage());
    await capture(tester, '08-buses');
    await back(tester);
    await push(tester, BusRouteDetailPage(route: Fixtures.routes.first));
    await capture(tester, '09-bus-route');
    await back(tester);
    await push(tester, const FacultyPage());
    await capture(tester, '10-faculty');
    await back(tester);
    await push(tester, FacultyProfilePage(member: Fixtures.faculty.first));
    await capture(tester, '11-faculty-profile');
    await back(tester);
    await push(tester, const NotesPage());
    await capture(tester, '12-notes');
    await back(tester);
    await push(tester, const NotificationPage());
    await capture(tester, '13-reminders');
    await back(tester);
    await push(tester, const SearchPage());
    await tester.enterText(find.byType(TextField).first, 'viva');
    await settle(tester);
    await capture(tester, '14-search');
    await back(tester);
    await finish(tester, d);
  });
  testWidgets('dark mode and CR editor render', (tester) async {
    final d = await boot(
      tester,
      role: UserRole.sectionAdmin,
      appearance: Appearance.dark,
    );
    await capture(tester, '15-home-dark');
    await tester.tap(find.text('Schedule').last);
    await settle(tester);
    await capture(tester, '16-schedule-dark');
    await tester.tap(find.text('Month'));
    await settle(tester);
    await capture(tester, '17-month-dark');
    await push(tester, const EventEditorPage());
    await capture(tester, '18-event-editor-dark');
    await back(tester);
    await finish(tester, d);
  });
  testWidgets('first launch and tablet render', (tester) async {
    final d = await boot(tester, signedIn: false);
    await capture(tester, '19-introduction');
    await tester.tap(find.text('Get started'));
    await settle(tester);
    await capture(tester, '20-onboarding');
    await finish(tester, d);
    final tablet = await boot(tester, size: const Size(1100, 900));
    await capture(tester, '21-tablet');
    await finish(tester, tablet);
  });
}
