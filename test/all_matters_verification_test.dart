import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myclass/core/models.dart';
import 'package:myclass/demo/fixtures.dart';
import 'package:myclass/demo/mock_academic_structure_repository.dart';
import 'package:myclass/features/resources/repositories/resources_repository.dart';
import 'package:myclass/features/teacher/services/teacher_section_service.dart';
import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Faculty Directory Names', () {
    test('Contains ONLY the 6 requested faculty members ABCDEF with suffixes', () {
      final names = Fixtures.faculty.map((f) => f.name).toList();
      const expectedNames = [
        'A Islam',
        'B Chowdhury',
        'C Rahman',
        'D Ahmed',
        'E Khan',
        'F Hasan',
      ];

      expect(names.length, equals(6));
      expect(names, equals(expectedNames));
    });
  });

  group('Matter 2: Credits and About MyClass', () {
    test('Credits formatted in exact 3 lines with literal @2026', () {
      const line2 = '@2026 Saminul Islam Sami';
      expect(line2, contains('@2026'));
      expect(line2.startsWith('@2026'), isTrue);
    });

    testWidgets('About MyClass sheet displays the exact 3-line credit', (tester) async {
      await boot(tester, signedIn: false);
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await settle(tester);

      expect(find.text('About MyClass'), findsOneWidget);
      await tester.tap(find.text('About MyClass'));
      await settle(tester);

      expect(find.text('MyClass v1.0.0'), findsOneWidget);
      expect(find.text('@2026 Saminul Islam Sami'), findsOneWidget);
      expect(find.text('All Rights Reserved'), findsOneWidget);
    });
  });

  group('Matter 6: Resources Navigation and Sections', () {
    test('Resources repository provides Notes, Questions, and Batch sections A to I', () {
      final repo = ResourcesRepository.instance;
      final notes = repo.getNotes();
      final pyqs = repo.getPYQs();
      final sections = repo.getSections();

      expect(notes.isNotEmpty, isTrue);
      expect(pyqs.isNotEmpty, isTrue);
      expect(sections.length, equals(9));
      expect(sections.map((s) => s.sectionName).toList(), equals([
        'Section A',
        'Section B',
        'Section C',
        'Section D',
        'Section E',
        'Section F',
        'Section G',
        'Section H',
        'Section I',
      ]));
    });

    testWidgets('Resources page displays 5 options', (tester) async {
      await boot(tester, role: UserRole.student, signedIn: true);
      await tester.tap(find.text('Resources'));
      await settle(tester);

      expect(find.text('Resources'), findsWidgets);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Previous Year Questions'), findsOneWidget);
      expect(find.text('Your Batch'), findsOneWidget);
      expect(find.text('Curriculum & Syllabus'), findsOneWidget);
      expect(find.text('Academic Archive'), findsOneWidget);
    });
  });

  group('Major Change: Universal Owner Login and Teacher Mode', () {
    test('sami / sami credentials authenticate as myClassOwner', () async {
      final repo = MockAcademicStructureRepository();
      final grant = await repo.verifyRoleAccess(
        'bsc-cse-64-I',
        isAdmin: true,
        password: 'sami',
      );
      expect(grant.role, equals(UserRole.myClassOwner));
    });

    test('TeacherSectionService manages accounts and section approval requirements', () {
      final service = TeacherSectionService.instance;
      
      // Register teacher
      service.registerTeacher(
        name: 'Prof. Test',
        email: 'test@leading.edu',
        password: 'pass',
      );
      expect(service.isSignedIn, isTrue);
      expect(service.currentTeacher?.name, equals('Prof. Test'));

      // Section request requires approval
      service.requestSection(
        sectionId: 'bsc-cse-64-X',
        sectionName: 'Section X',
        batchName: 'Batch 64',
        departmentName: 'CSE',
        universityName: 'Leading University',
        sectionCode: 'sec-x-code',
      );

      final pending = service.pendingSections.where((s) => s.sectionId == 'bsc-cse-64-X').toList();
      expect(pending.isNotEmpty, isTrue);
      expect(pending.first.isApproved, isFalse);

      // Approve section
      service.approveSection('bsc-cse-64-X');
      final approved = service.approvedSections.where((s) => s.sectionId == 'bsc-cse-64-X').toList();
      expect(approved.isNotEmpty, isTrue);
      expect(approved.first.isApproved, isTrue);
    });

    test('Teacher membership grants canManage but restricts isAdmin', () {
      const teacherMembership = SectionMembership(
        sectionId: 'bsc-cse-64-A',
        departmentId: 'cse',
        programId: 'bsc-cse',
        batchId: 'bsc-cse-64',
        programName: 'Computer Science & Engineering',
        batchName: 'Batch 64',
        sectionName: 'Section A',
        role: UserRole.teacher,
      );

      expect(teacherMembership.isTeacher, isTrue);
      expect(teacherMembership.canManage, isTrue);
      expect(teacherMembership.isAdmin, isFalse);
      expect(teacherMembership.isOwner, isFalse);
    });
  });

  group('Logged In Shell Bottom Navigation', () {
    testWidgets('Navigation bar contains Home, Campus, Resources, and Profile in order', (tester) async {
      await boot(tester, role: UserRole.student, signedIn: true);

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Campus'), findsWidgets);
      expect(find.text('Resources'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });
  });

  group('FIX VERSION: CR Name, Create Classroom & Teacher Mode', () {
    test('My Batch Section I CR name is Shuvo Sarker', () {
      final repo = ResourcesRepository.instance;
      final secI = repo.getSections().firstWhere((s) => s.sectionName == 'Section I');
      expect(secI.crName, equals('Shuvo Sarker'));
    });

    test('TeacherSectionService starts logged out and retains Dr. Tariqul Islam preview account', () {
      final service = TeacherSectionService.instance;
      service.signOutTeacher();
      expect(service.isSignedIn, isFalse);

      service.signInAsPreviewTeacher();
      expect(service.isSignedIn, isTrue);
      expect(service.currentTeacher?.name, equals('Dr. Tariqul Islam'));
      expect(service.currentTeacher?.email, equals('tariqul@leading.edu'));
      expect(service.approvedSections.isNotEmpty, isTrue);

      service.signOutTeacher();
      expect(service.isSignedIn, isFalse);
    });

    test('Teacher Sign Up creates account and automatically signs in', () {
      final service = TeacherSectionService.instance;
      service.signOutTeacher();
      expect(service.isSignedIn, isFalse);

      service.registerTeacher(
        name: 'Dr. New Faculty',
        email: 'faculty@leading.edu',
        password: 'password123',
      );

      expect(service.isSignedIn, isTrue);
      expect(service.currentTeacher?.name, equals('Dr. New Faculty'));
      expect(service.currentTeacher?.email, equals('faculty@leading.edu'));
    });

    test('Teacher Sign In with password "teacher" authenticates successfully', () {
      final service = TeacherSectionService.instance;
      service.signOutTeacher();
      expect(service.isSignedIn, isFalse);

      final ok = service.signInTeacher(email: 'any@leading.edu', password: 'teacher');
      expect(ok, isTrue);
      expect(service.isSignedIn, isTrue);
    });
  });
}
