import 'package:flutter/foundation.dart';
import '../../onboarding/models/academic_structure.dart';

class TeacherAccount {
  const TeacherAccount({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

class TeacherSectionItem {
  const TeacherSectionItem({
    required this.sectionId,
    required this.sectionName,
    required this.batchName,
    required this.departmentName,
    required this.universityName,
    required this.sectionCode,
    this.isApproved = false,
  });

  final String sectionId;
  final String sectionName;
  final String batchName;
  final String departmentName;
  final String universityName;
  final String sectionCode;
  final bool isApproved;

  TeacherSectionItem copyWith({bool? isApproved}) => TeacherSectionItem(
        sectionId: sectionId,
        sectionName: sectionName,
        batchName: batchName,
        departmentName: departmentName,
        universityName: universityName,
        sectionCode: sectionCode,
        isApproved: isApproved ?? this.isApproved,
      );
}

class TeacherSectionService extends ChangeNotifier {
  static final TeacherSectionService instance = TeacherSectionService._();

  TeacherSectionService._() {
    // Default preview teacher account
    const preview = TeacherAccount(
      name: 'Dr. Tariqul Islam',
      email: 'tariqul@leading.edu',
      password: 'teacher',
    );
    _registeredTeachers[preview.email.toLowerCase()] = preview;
    _currentTeacher = preview;
    _isSignedIn = false;

    // Initial approved and requested sections
    _sections.addAll([
      const TeacherSectionItem(
        sectionId: 'bsc-cse-64-A',
        sectionName: 'Section A',
        batchName: 'Batch 64',
        departmentName: 'Computer Science & Engineering',
        universityName: 'Leading University',
        sectionCode: 'sec-a-code',
        isApproved: true,
      ),
      const TeacherSectionItem(
        sectionId: 'bsc-cse-64-C',
        sectionName: 'Section C',
        batchName: 'Batch 64',
        departmentName: 'Computer Science & Engineering',
        universityName: 'Leading University',
        sectionCode: 'sec-c-code',
        isApproved: true,
      ),
      const TeacherSectionItem(
        sectionId: 'bsc-cse-64-I',
        sectionName: 'Section I',
        batchName: 'Batch 64',
        departmentName: 'Computer Science & Engineering',
        universityName: 'Leading University',
        sectionCode: 'sec-i-code',
        isApproved: true,
      ),
    ]);
  }

  final Map<String, TeacherAccount> _registeredTeachers = {};
  TeacherAccount? _currentTeacher;
  bool _isSignedIn = false;
  final List<TeacherSectionItem> _sections = [];

  TeacherAccount? get currentTeacher => _currentTeacher;
  bool get isSignedIn => _isSignedIn;
  List<TeacherSectionItem> get approvedSections =>
      _sections.where((s) => s.isApproved).toList();
  List<TeacherSectionItem> get pendingSections =>
      _sections.where((s) => !s.isApproved).toList();

  void registerTeacher({
    required String name,
    required String email,
    required String password,
  }) {
    final account = TeacherAccount(
      name: name,
      email: email,
      password: password,
    );
    _registeredTeachers[email.toLowerCase().trim()] = account;
    _currentTeacher = account;
    _isSignedIn = true;
    notifyListeners();
  }

  bool signInTeacher({
    required String email,
    required String password,
  }) {
    final key = email.toLowerCase().trim();
    final pass = password.trim().toLowerCase();

    // Universal teacher access with password: teacher or username/email: teacher
    if (pass == 'teacher' || key == 'teacher') {
      _currentTeacher = _registeredTeachers['tariqul@leading.edu'] ??
          const TeacherAccount(
            name: 'Dr. Tariqul Islam',
            email: 'tariqul@leading.edu',
            password: 'teacher',
          );
      _isSignedIn = true;
      notifyListeners();
      return true;
    }

    if (_registeredTeachers.containsKey(key)) {
      final acc = _registeredTeachers[key]!;
      if (acc.password == password || acc.password == 'teacher') {
        _currentTeacher = acc;
        _isSignedIn = true;
        notifyListeners();
        return true;
      }
    }
    // Check preview account
    if (key == 'tariqul@leading.edu' && (password == 'teacher' || password == 'password123')) {
      _currentTeacher = _registeredTeachers['tariqul@leading.edu'];
      _isSignedIn = true;
      notifyListeners();
      return true;
    }
    // Allow standard sign-in if matching or demo
    if (password.isNotEmpty && email.contains('@')) {
      final name = email.split('@').first.replaceAll('.', ' ').toUpperCase();
      final account = TeacherAccount(name: name, email: email, password: password);
      _registeredTeachers[key] = account;
      _currentTeacher = account;
      _isSignedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void signInAsPreviewTeacher() {
    _currentTeacher = _registeredTeachers['tariqul@leading.edu'] ??
        const TeacherAccount(
          name: 'Dr. Tariqul Islam',
          email: 'tariqul@leading.edu',
          password: 'teacher',
        );
    _isSignedIn = true;
    notifyListeners();
  }

  void signOutTeacher() {
    _isSignedIn = false;
    notifyListeners();
  }

  void requestSection({
    required String sectionId,
    required String sectionName,
    required String batchName,
    required String departmentName,
    required String universityName,
    required String sectionCode,
  }) {
    final existingIndex = _sections.indexWhere((s) => s.sectionId == sectionId);
    if (existingIndex == -1) {
      _sections.add(
        TeacherSectionItem(
          sectionId: sectionId,
          sectionName: sectionName,
          batchName: batchName,
          departmentName: departmentName,
          universityName: universityName,
          sectionCode: sectionCode,
          isApproved: false, // Requires Admin or Owner approval
        ),
      );
      notifyListeners();
    }
  }

  void approveSection(String sectionId) {
    final index = _sections.indexWhere((s) => s.sectionId == sectionId);
    if (index != -1) {
      _sections[index] = _sections[index].copyWith(isApproved: true);
      notifyListeners();
    }
  }

  SectionMembership createMembershipForSection(TeacherSectionItem item) {
    return SectionMembership(
      sectionId: item.sectionId,
      departmentId: 'cse',
      programId: 'bsc-cse',
      batchId: 'bsc-cse-64',
      programName: item.departmentName,
      batchName: item.batchName,
      sectionName: item.sectionName,
      universityId: 'lu',
      universityName: item.universityName,
      role: UserRole.teacher,
    );
  }
}
