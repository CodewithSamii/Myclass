import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myclass/core/models.dart';
import 'package:myclass/demo/mock_academic_structure_repository.dart';
import 'package:myclass/features/schedule/views/admin_options_sheet.dart';
import 'package:myclass/features/schedule/views/class_detail_page.dart';
import 'package:myclass/features/teacher/services/teacher_section_service.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Requirement 5: Login Credentials', () {
    test('MockAcademicStructureRepository verifies user with cr as admin and isec1234 as student', () async {
      final repo = MockAcademicStructureRepository();

      // Student verification with isec1234
      final studentGrant = await repo.verifyRoleAccess(
        'bsc-cse-64-I',
        isAdmin: false,
        password: 'isec1234',
      );
      expect(studentGrant.role, equals(UserRole.student));

      // Admin verification with cr
      final adminGrant = await repo.verifyRoleAccess(
        'bsc-cse-64-I',
        isAdmin: true,
        password: 'cr',
      );
      expect(adminGrant.role, equals(UserRole.sectionAdmin));

      // Direct password role verification regardless of isAdmin toggle
      final autoAdminGrant = await repo.verifyRoleAccess(
        'bsc-cse-64-I',
        isAdmin: false,
        password: 'cr',
      );
      expect(autoAdminGrant.role, equals(UserRole.sectionAdmin));

      final autoStudentGrant = await repo.verifyRoleAccess(
        'bsc-cse-64-I',
        isAdmin: true,
        password: 'isec1234',
      );
      expect(autoStudentGrant.role, equals(UserRole.student));
    });
  });

  group('Requirement 9: Smart Bus Reminder Frequency & Day Selection', () {
    test('ReminderPreference correctly checks active status for Class Days Only, Every Day, and Custom', () {
      final mondayWithClasses = DateTime(2026, 9, 21); // Monday
      final sundayNoClasses = DateTime(2026, 9, 27); // Sunday

      // Class Days Only
      const classDaysPref = ReminderPreference(
        busReminderMinutes: 15,
        busReminderMode: 'classDaysOnly',
      );
      expect(
        classDaysPref.isBusReminderActiveForDay(date: mondayWithClasses, hasClasses: true),
        isTrue,
      );
      expect(
        classDaysPref.isBusReminderActiveForDay(date: sundayNoClasses, hasClasses: false),
        isFalse,
      );

      // Every Day
      const everyDayPref = ReminderPreference(
        busReminderMinutes: 15,
        busReminderMode: 'everyDay',
      );
      expect(
        everyDayPref.isBusReminderActiveForDay(date: mondayWithClasses, hasClasses: true),
        isTrue,
      );
      expect(
        everyDayPref.isBusReminderActiveForDay(date: sundayNoClasses, hasClasses: false),
        isTrue,
      );

      // Custom
      const customPref = ReminderPreference(
        busReminderMinutes: 15,
        busReminderMode: 'custom',
        busReminderDays: [1, 2, 3], // Mon, Tue, Wed
      );
      expect(
        customPref.isBusReminderActiveForDay(date: mondayWithClasses, hasClasses: false),
        isTrue,
      );
      expect(
        customPref.isBusReminderActiveForDay(date: sundayNoClasses, hasClasses: true),
        isFalse,
      );

      // Turned Off
      const offPref = ReminderPreference(
        busReminderMinutes: 0,
        busReminderMode: 'everyDay',
      );
      expect(
        offPref.isBusReminderActiveForDay(date: mondayWithClasses, hasClasses: true),
        isFalse,
      );
    });
  });

  group('Requirement 2: Admin Options Placement & ClassDetailPage', () {
    testWidgets('ClassDetailPage does NOT contain Admin options', (tester) async {
      final d = await boot(tester, role: UserRole.sectionAdmin);

      await push(
        tester,
        ClassDetailPage(
          sessionId: 'bsc-cse-64-I-mon-4',
          day: DateTime(2026, 9, 21),
        ),
      );

      expect(find.text('Admin options'), findsNothing);
      expect(find.text('Cancel class for this date'), findsNothing);
      expect(find.text('Shift class to another date / slot'), findsNothing);
      expect(find.text('Edit repeating weekly routine'), findsNothing);
      await tester.ensureVisible(find.text('Class reminder'));
      await settle(tester);
      expect(find.text('Class reminder'), findsOneWidget);

      await finish(tester, d);
    });

    testWidgets('Admin Options button appears beside Temp Class and Add Event, opens AdminOptionsSheet', (tester) async {
      final d = await boot(tester, role: UserRole.sectionAdmin);

      expect(find.text('+ Temp Class'), findsOneWidget);
      expect(find.text('Add Event'), findsOneWidget);
      expect(find.text('Admin Options'), findsOneWidget);

      await tester.ensureVisible(find.text('Admin Options'));
      await settle(tester);
      await tester.tap(find.text('Admin Options'));
      await settle(tester);

      expect(find.text('Cancel Class'), findsOneWidget);
      expect(find.text('Shift Class'), findsOneWidget);
      expect(find.text('Manage Routine'), findsOneWidget);

      await finish(tester, d);
    });
  });

  group('Requirement 6 & 7: Profile Page Logout and Credits', () {
    testWidgets('Logged-out profile does not show Sign out button, shows 3-line credits in About', (tester) async {
      final d = await boot(tester, signedIn: false);

      // Switch to Profile tab
      await tester.tap(find.text('Profile'));
      await settle(tester);

      // Sign out button must be hidden for guest/logged-out
      expect(find.text('Sign out'), findsNothing);

      // Tap About MyClass
      await tester.ensureVisible(find.text('About MyClass'));
      await settle(tester);
      await tester.tap(find.text('About MyClass'));
      await settle(tester);

      expect(find.text('MyClass v1.0.0'), findsOneWidget);
      expect(find.text('@2026 Saminul Islam Sami'), findsOneWidget);
      expect(find.text('All Rights Reserved'), findsOneWidget);

      await finish(tester, d);
    });
  });

  group('Requirement: Bus Reminder 3-Box Horizontal Selector & Custom Sheet', () {
    testWidgets('BusPage renders 3-box horizontal selector and opens CustomBusDaysSheet', (tester) async {
      final d = await boot(tester, role: UserRole.student);

      // Navigate to Campus -> University bus
      await tester.tap(find.text('Campus'));
      await settle(tester);

      await tester.ensureVisible(find.text('University bus'));
      await settle(tester);
      await tester.tap(find.text('University bus'));
      await settle(tester);

      // Verify the 3-box horizontal selector exists
      expect(find.text('Class Days'), findsOneWidget);
      expect(find.text('Every Day'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Tap Custom box
      await tester.tap(find.text('Custom'));
      await settle(tester);

      // Verify CustomBusDaysSheet opens with the 7 days of the week
      expect(find.text('Custom Bus Reminder Days'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);

      // Save custom schedule
      await tester.tap(find.text('Save Custom Schedule'));
      await settle(tester);

      // Back on Bus Page
      expect(find.text('Custom Bus Reminder Days'), findsNothing);
      expect(find.text('Custom'), findsOneWidget);

      await finish(tester, d);
    });
  });

  group('Requirement: Admin Options Cancel and Shift Full Functional Flows', () {
    testWidgets('Cancel Class flow shows confirmation dialog with notification toggle and cancels class', (tester) async {
      final d = await boot(tester, role: UserRole.sectionAdmin);

      await tester.ensureVisible(find.text('Admin Options'));
      await settle(tester);
      await tester.tap(find.text('Admin Options'));
      await settle(tester);

      // Tap Cancel Class
      expect(find.text('Cancel Class'), findsOneWidget);
      await tester.tap(find.text('Cancel Class'));
      await settle(tester);

      // Course selection appears
      expect(find.text('Cancel Class · Select Course'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AdminOptionsSheet),
          matching: find.text('Software Engineering Sessional'),
        ),
      );
      await settle(tester);

      // Confirmation dialog appears with "Are you sure you want to cancel this class?"
      expect(find.textContaining('Are you sure you want to cancel this class?'), findsOneWidget);
      expect(find.text('Notify students?'), findsOneWidget);
      expect(find.text('Yes'), findsWidgets);
      expect(find.text('Cancel / No'), findsOneWidget);
      expect(find.text('Confirm / Yes'), findsOneWidget);

      // Confirm cancellation
      await tester.tap(find.text('Confirm / Yes'));
      await settle(tester);

      // Dialog and sheet closed cleanly, app is on home page
      expect(find.text('Cancel / No'), findsNothing);
      expect(find.text('Jump to Today'), findsOneWidget);

      await finish(tester, d);
    });

    testWidgets('Shift Class flow opens routine day & slot selector, confirms with notification toggle and shifts', (tester) async {
      final d = await boot(tester, role: UserRole.sectionAdmin);

      await tester.ensureVisible(find.text('Admin Options'));
      await settle(tester);
      await tester.tap(find.text('Admin Options'));
      await settle(tester);

      // Tap Shift Class
      expect(find.text('Shift Class'), findsOneWidget);
      await tester.tap(find.text('Shift Class'));
      await settle(tester);

      // Course selection appears
      expect(find.text('Shift Class · Select Course'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AdminOptionsSheet),
          matching: find.text('Software Engineering Sessional'),
        ),
      );
      await settle(tester);

      // Routine selection UI appears: Preferred Day & Preferred Slot
      expect(find.text('PREFERRED DAY'), findsOneWidget);
      expect(find.text('PREFERRED SLOT'), findsOneWidget);
      expect(find.text('Continue to Confirmation'), findsOneWidget);

      // Tap Continue to Confirmation
      await tester.tap(find.text('Continue to Confirmation'));
      await settle(tester);

      // Confirmation dialog appears
      expect(find.textContaining('Are you sure you want to shift this class to the selected day and slot?'), findsOneWidget);
      expect(find.text('Notify students?'), findsOneWidget);
      expect(find.text('Cancel / No'), findsOneWidget);
      expect(find.text('Confirm / Yes'), findsOneWidget);

      // Confirm shift
      await tester.tap(find.text('Confirm / Yes'));
      await settle(tester);

      // Sheet closed cleanly and back on home page
      expect(find.text('Continue to Confirmation'), findsNothing);
      expect(find.text('Jump to Today'), findsOneWidget);

      await finish(tester, d);
    });
  });

  group('FIX VERSION: Create Classroom & Teacher Mode Flow', () {
    testWidgets('Create Classroom tab has default user and Set/Confirm Section Code fields', (tester) async {
      await boot(tester, signedIn: false);

      // Open SectionEntrySheet with Create Classroom tab (tab 2)
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await settle(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Join or Create Classroom'));
      await settle(tester);

      // Switch to Create Classroom tab
      await tester.tap(find.text('Create Classroom'));
      await settle(tester);

      // Verify default user in creator name field
      expect(find.widgetWithText(TextField, 'user'), findsOneWidget);

      // Verify Set Section Code and Confirm Section Code labels and hints
      expect(find.text('Set Section Code'), findsOneWidget);
      expect(find.text('Confirm Section Code'), findsOneWidget);
      expect(find.text('Admin Section Code (for classroom controls)'), findsNothing);
      expect(find.text('Student Section Code (for your classmates)'), findsNothing);
    });

    testWidgets('Teacher Mode tab starts logged out, hiding My Sections until signed in', (tester) async {
      TeacherSectionService.instance.signOutTeacher();
      await boot(tester, signedIn: false);

      // Open SectionEntrySheet
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await settle(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Join or Create Classroom'));
      await settle(tester);

      // Switch to Teacher Mode tab
      await tester.tap(find.text('Teacher Mode'));
      await settle(tester);

      // In logged-out state: My Sections must NOT be shown!
      expect(find.text('My Sections'), findsNothing);
      expect(find.text('Teacher Sign In'), findsOneWidget);
      expect(find.text('Sign In to Teacher Mode'), findsOneWidget);
      expect(find.text('Demo: Sign In as Dr. Tariqul Islam'), findsOneWidget);

      // Tap demo sign in for Dr. Tariqul Islam
      await tester.tap(find.text('Demo: Sign In as Dr. Tariqul Islam'));
      await settle(tester);

      // Now signed in: My Sections appears!
      expect(find.text('My Sections'), findsOneWidget);
      expect(find.text('Dr. Tariqul Islam'), findsOneWidget);
      expect(find.text('+ Add Section'), findsOneWidget);
    });
  });
}
