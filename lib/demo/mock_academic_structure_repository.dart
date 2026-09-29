import '../core/models.dart';
import '../core/repositories.dart';
import 'fixtures.dart';

class MockAcademicStructureRepository implements AcademicStructureRepository {
  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 180));

  // Dynamic in-memory store for classrooms
  final Map<String, Section> _sectionStore = {
    'bsc-cse-64-A': const Section(
      'bsc-cse-64-A',
      'bsc-cse-64',
      'Section A',
      adminPassword: 'admin',
      studentPassword: '123',
      creatorName: 'Tanvir Ahmed',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
    'bsc-cse-64-B': const Section(
      'bsc-cse-64-B',
      'bsc-cse-64',
      'Section B',
      adminPassword: 'admin',
      studentPassword: '123',
      creatorName: 'Samira Chowdhury',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
    'bsc-cse-64-C': const Section(
      'bsc-cse-64-C',
      'bsc-cse-64',
      'Section C',
      adminPassword: 'admin',
      studentPassword: '123',
      creatorName: 'Arif Hasan',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
    'bsc-cse-64-D': const Section(
      'bsc-cse-64-D',
      'bsc-cse-64',
      'Section D',
      adminPassword: 'admin',
      studentPassword: '123',
      creatorName: 'Nafis Rahman',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
    'bsc-cse-64-E': const Section(
      'bsc-cse-64-E',
      'bsc-cse-64',
      'Section E',
      adminPassword: 'admin',
      studentPassword: '123',
      creatorName: 'Tasnim Jahan',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
    'bsc-cse-64-F': const Section(
      'bsc-cse-64-F',
      'bsc-cse-64',
      'Section F',
      adminPassword: 'admin',
      studentPassword: '123',
      creatorName: 'Rashed Ali',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
    'bsc-cse-64-G': const Section(
      'bsc-cse-64-G',
      'bsc-cse-64',
      'Section G',
      adminPassword: 'admin',
      studentPassword: '123',
      creatorName: 'Farhana Kabir',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
    'bsc-cse-64-H': const Section(
      'bsc-cse-64-H',
      'bsc-cse-64',
      'Section H',
      adminPassword: 'admin',
      studentPassword: '123',
      creatorName: 'Mahmudul Karim',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
    'bsc-cse-64-I': const Section(
      'bsc-cse-64-I',
      'bsc-cse-64',
      'Section I',
      adminPassword: 'cr',
      studentPassword: 'isec1234',
      creatorName: 'Shuvo',
      status: SectionStatus.approved,
      departmentId: 'cse',
      departmentName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
    ),
  };

  @override
  Future<List<University>> universities() async {
    await _delay();
    final list = List<University>.from(Fixtures.universities)
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<List<Department>> departments(String programType, {String? universityId}) async {
    await _delay();
    final uId = (universityId == null || universityId.isEmpty) ? 'lu' : universityId;
    // Leading University data
    if (uId == 'lu' || uId == 'leading-university' || uId == 'mu') {
      return Fixtures.departments
          .where(
            (d) => Fixtures.programs.any(
              (p) => p.departmentId == d.id && p.type == programType,
            ),
          )
          .toList();
    }
    // Dynamic departments created for other universities
    final created = _sectionStore.values
        .where((s) => (s.universityId == uId) && s.departmentId != null)
        .map((s) => Department(s.departmentId!, s.departmentName ?? s.departmentId!, s.departmentName ?? s.departmentId!))
        .toSet()
        .toList();
    return created;
  }

  @override
  Future<List<AcademicProgram>> programs(
    String departmentId,
    String type, {
    String? universityId,
  }) async {
    await _delay();
    final uId = (universityId == null || universityId.isEmpty) ? 'lu' : universityId;
    if (uId == 'lu' || uId == 'leading-university' || uId == 'mu') {
      return Fixtures.programs
          .where((p) => p.departmentId == departmentId && p.type == type)
          .toList();
    }
    return [
      AcademicProgram(
        id: 'prog-$departmentId',
        name: departmentId,
        shortName: departmentId,
        departmentId: departmentId,
        type: type,
        universityId: uId,
      ),
    ];
  }

  @override
  Future<List<Batch>> batches(String programId) async {
    await _delay();
    return [
      for (final n in [69, 68, 67, 66, 65, 64, 63, 62, 61])
        Batch('$programId-$n', programId, 'Batch $n'),
    ];
  }

  @override
  Future<List<Section>> sections(String batchId) async {
    await _delay();
    final custom = _sectionStore.values.where((s) => s.batchId == batchId).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    if (custom.isNotEmpty) return custom;
    return [
      for (final s in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'])
        Section(
          '$batchId-$s',
          batchId,
          'Section $s',
          adminPassword: 'cr',
          studentPassword: 'isec1234',
          status: SectionStatus.approved,
        ),
    ];
  }

  @override
  Future<List<Section>> approvedSections(String batchId) async {
    await _delay();
    final all = await sections(batchId);
    return all.where((s) => s.status == SectionStatus.approved).toList();
  }

  @override
  Future<List<Section>> pendingSections() async {
    await _delay();
    return _sectionStore.values
        .where((s) => s.status == SectionStatus.pendingApproval)
        .toList();
  }

  @override
  Future<Section> createSection({
    String? universityId,
    String? universityName,
    required String departmentId,
    required String departmentName,
    required String batchId,
    required String batchName,
    required String sectionName,
    required String adminPassword,
    required String studentPassword,
    required String creatorName,
  }) async {
    await _delay();
    final cleanSection = sectionName.trim();
    final slug = cleanSection.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final id = '$batchId-$slug';

    final section = Section(
      id,
      batchId,
      cleanSection.startsWith('Section') ? cleanSection : 'Section $cleanSection',
      adminPassword: adminPassword.trim(),
      studentPassword: studentPassword.trim(),
      creatorName: creatorName.trim(),
      status: SectionStatus.pendingApproval,
      createdAt: DateTime.now(),
      departmentId: departmentId,
      departmentName: departmentName,
      batchName: batchName,
      universityId: universityId ?? 'lu',
      universityName: universityName ?? 'Leading University',
    );

    _sectionStore[id] = section;
    return section;
  }

  @override
  Future<void> approveSection(String sectionId) async {
    await _delay();
    final existing = _sectionStore[sectionId];
    if (existing != null) {
      _sectionStore[sectionId] = existing.copyWith(
        status: SectionStatus.approved,
      );
    }
  }

  @override
  Future<void> rejectSection(String sectionId) async {
    await _delay();
    final existing = _sectionStore[sectionId];
    if (existing != null) {
      _sectionStore[sectionId] = existing.copyWith(
        status: SectionStatus.rejected,
      );
    }
  }

  @override
  Future<SectionGrant> verifyAccess(String sectionId, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final cleanCode = code.trim();
    final section = _sectionStore[sectionId];

    if (section != null) {
      if (section.status == SectionStatus.pendingApproval) {
        throw const AppFailure(
          'This classroom is pending approval from the MyClass Owner.',
        );
      }
      if (cleanCode == 'cr' || cleanCode == section.adminPassword) {
        return SectionGrant(
          sectionId,
          'mock-admin-token',
          role: UserRole.sectionAdmin,
        );
      }
      if (cleanCode == 'isec1234' || cleanCode == section.studentPassword) {
        return SectionGrant(
          sectionId,
          'mock-student-token',
          role: UserRole.student,
        );
      }
    }

    // Default fallback for fixture classrooms
    if (cleanCode == 'cr' || cleanCode == 'admin' || cleanCode == 'admin123') {
      return SectionGrant(
        sectionId,
        'mock-admin-token',
        role: UserRole.sectionAdmin,
      );
    }
    if (cleanCode == 'isec1234' ||
        cleanCode == '123' ||
        cleanCode == '123456' ||
        cleanCode.toUpperCase() == 'MYCLASS64' ||
        cleanCode.toUpperCase() == 'AULA64') {
      return SectionGrant(
        sectionId,
        'mock-opaque-grant',
        role: UserRole.student,
      );
    }

    throw const AppFailure(
      'That password did not match. Please verify the credentials with your class representative.',
    );
  }

  @override
  Future<SectionGrant> verifyRoleAccess(
    String sectionId, {
    required bool isAdmin,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final cleanPassword = password.trim();
    final section = _sectionStore[sectionId];

    if (section != null && section.status == SectionStatus.pendingApproval) {
      throw const AppFailure(
        'This classroom is pending approval from the MyClass Owner.',
      );
    }

    final expectedAdminPass = section?.adminPassword ?? 'cr';
    final expectedStudentPass = section?.studentPassword ?? 'isec1234';

    // Universal Owner Credentials
    if (cleanPassword == 'sami' || cleanPassword == 'yyoyyo') {
      return SectionGrant(
        sectionId,
        'mock-owner-token-${DateTime.now().millisecondsSinceEpoch}',
        role: UserRole.myClassOwner,
      );
    }

    // Only the password determines the current role according to requirement:
    // cr -> Admin / CR
    // isec1234 -> Student
    if (cleanPassword == 'cr' || cleanPassword == expectedAdminPass || cleanPassword == 'admin' || cleanPassword == 'admin123') {
      return SectionGrant(
        sectionId,
        'mock-admin-token-${DateTime.now().millisecondsSinceEpoch}',
        role: UserRole.sectionAdmin,
      );
    }

    if (cleanPassword == 'isec1234' || cleanPassword == expectedStudentPass || cleanPassword == '123' || cleanPassword == '123456') {
      return SectionGrant(
        sectionId,
        'mock-student-token-${DateTime.now().millisecondsSinceEpoch}',
        role: UserRole.student,
      );
    }

    if (isAdmin) {
      throw const AppFailure(
        'Incorrect Admin Section Code for this classroom. Please check and try again.',
      );
    } else {
      throw const AppFailure(
        'Incorrect Student Section Code for this classroom. Please check with your CR.',
      );
    }
  }
}

