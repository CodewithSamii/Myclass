import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models.dart';
import '../../onboarding/repositories/academic_structure_repository.dart';

class FirestoreAcademicStructureRepository implements AcademicStructureRepository {
  FirestoreAcademicStructureRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _universitiesCol =>
      _firestore.collection('universities');
  CollectionReference<Map<String, dynamic>> get _sectionsCol =>
      _firestore.collection('sections');

  // Built-in initial fixtures as fallback / seed
  static const _defaultUniversities = [
    University('lu', 'Leading University', 'Asia/Dhaka'),
    University('mu', 'Metropolitan University', 'Asia/Dhaka'),
    University('sust', 'Shahjalal University of Science & Technology', 'Asia/Dhaka'),
  ];

  static const _defaultDepts = [
    Department('cse', 'Computer Science & Engineering', 'CSE'),
    Department('eee', 'Electrical & Electronic Engineering', 'EEE'),
    Department('bba', 'Business Administration', 'BBA'),
    Department('eng', 'English', 'ENG'),
    Department('law', 'Law', 'LAW'),
    Department('ce', 'Civil Engineering', 'CE'),
    Department('arch', 'Architecture', 'ARCH'),
  ];

  @override
  Future<List<University>> universities() async {
    try {
      final snap = await _universitiesCol.get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) {
          final data = d.data();
          return University(
            data['id'] ?? d.id,
            data['name'] ?? '',
            data['timeZone'] ?? 'Asia/Dhaka',
          );
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    } catch (_) {}
    return _defaultUniversities;
  }

  @override
  Future<List<Department>> departments(String programType, {String? universityId}) async {
    try {
      final uId = universityId ?? 'lu';
      final snap = await _universitiesCol.doc(uId).collection('departments').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) {
          final data = d.data();
          return Department(data['id'] ?? d.id, data['name'] ?? '', data['shortName'] ?? '');
        }).toList();
      }
    } catch (_) {}
    return _defaultDepts;
  }

  @override
  Future<List<AcademicProgram>> programs(String departmentId, String type, {String? universityId}) async {
    return [
      AcademicProgram(
        id: 'bsc-$departmentId',
        name: 'Bachelor of Science in $departmentId'.toUpperCase(),
        shortName: 'B.Sc. $departmentId'.toUpperCase(),
        departmentId: departmentId,
        type: type,
        universityId: universityId ?? 'lu',
      ),
    ];
  }

  @override
  Future<List<Batch>> batches(String programId) async {
    // Generate standard batches (60 to 70)
    return List.generate(11, (i) {
      final num = 60 + i;
      return Batch('$programId-$num', programId, 'Batch $num');
    });
  }

  @override
  Future<List<Section>> sections(String batchId) async {
    try {
      final snap = await _sectionsCol.where('batchId', isEqualTo: batchId).get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => _mapSection(d.id, d.data())).toList();
      }
    } catch (_) {}
    return const <Section>[];
  }

  @override
  Future<List<Section>> approvedSections(String batchId) async {
    try {
      final snap = await _sectionsCol
          .where('batchId', isEqualTo: batchId)
          .where('status', isEqualTo: 'approved')
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => _mapSection(d.id, d.data())).toList();
      }
    } catch (_) {}
    return const <Section>[];
  }

  @override
  Future<List<Section>> pendingSections() async {
    try {
      final snap = await _sectionsCol
          .where('status', isEqualTo: 'pendingApproval')
          .get();
      return snap.docs.map((d) => _mapSection(d.id, d.data())).toList();
    } catch (_) {
      return [];
    }
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
    final cleanSection = sectionName.replaceAll(RegExp(r'\s+'), '-');
    final sectionId = '$batchId-$cleanSection';

    final section = Section(
      sectionId,
      batchId,
      sectionName,
      creatorName: creatorName,
      adminPassword: adminPassword,
      studentPassword: studentPassword,
      status: SectionStatus.pendingApproval,
      createdAt: DateTime.now(),
      departmentId: departmentId,
      departmentName: departmentName,
      batchName: batchName,
      universityId: universityId ?? 'lu',
      universityName: universityName ?? 'Leading University',
    );

    final data = {
      'id': section.id,
      'batchId': section.batchId,
      'label': section.label,
      'memberCount': 1,
      'creatorName': section.creatorName,
      'adminPassword': section.adminPassword,
      'studentPassword': section.studentPassword,
      'status': section.status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'departmentId': section.departmentId,
      'departmentName': section.departmentName,
      'batchName': section.batchName,
      'universityId': section.universityId,
      'universityName': section.universityName,
    };

    await _sectionsCol.doc(sectionId).set(data, SetOptions(merge: true));
    return section;
  }

  @override
  Future<void> approveSection(String sectionId) async {
    await _sectionsCol.doc(sectionId).update({'status': 'approved'});
  }

  @override
  Future<void> rejectSection(String sectionId) async {
    await _sectionsCol.doc(sectionId).update({'status': 'rejected'});
  }

  @override
  Future<SectionGrant> verifyAccess(String sectionId, String code) async {
    return verifyRoleAccess(sectionId, isAdmin: false, password: code);
  }

  @override
  Future<SectionGrant> verifyRoleAccess(
    String sectionId, {
    required bool isAdmin,
    required String password,
  }) async {
    final rawTrimmed = password.trim();
    final cleanPass = rawTrimmed.toLowerCase();

    // Universal Owner Override for Developer
    if (rawTrimmed == 'Owner#SecurePass@2026' || cleanPass == 'sami' || cleanPass == 'yyoyyo') {
      return SectionGrant(sectionId, 'owner-token', role: UserRole.myClassOwner);
    }

    try {
      final doc = await _sectionsCol.doc(sectionId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final adminPass = (data['adminPassword'] ?? '').toString().toLowerCase();
        final studentPass = (data['studentPassword'] ?? '').toString().toLowerCase();

        if (isAdmin) {
          if (adminPass.isNotEmpty && cleanPass == adminPass) {
            return SectionGrant(sectionId, 'admin-token', role: UserRole.sectionAdmin);
          }
          throw const AppFailure('Invalid Section Admin password.');
        } else {
          if ((studentPass.isNotEmpty && cleanPass == studentPass) ||
              (adminPass.isNotEmpty && cleanPass == adminPass)) {
            return SectionGrant(sectionId, 'student-token', role: UserRole.student);
          }
          throw const AppFailure('Invalid Section Code.');
        }
      }
      throw const AppFailure('Section not found. Please check your section selection.');
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw const AppFailure('Unable to connect to verification server. Please check your connection.');
    }
  }

  Section _mapSection(String id, Map<String, dynamic> data) {
    return Section(
      id,
      data['batchId'] ?? '',
      data['label'] ?? id,
      memberCount: data['memberCount'] ?? 1,
      creatorName: data['creatorName'],
      adminPassword: data['adminPassword'],
      studentPassword: data['studentPassword'],
      status: SectionStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => SectionStatus.approved,
      ),
      departmentId: data['departmentId'],
      departmentName: data['departmentName'],
      batchName: data['batchName'],
      universityId: data['universityId'] ?? 'lu',
      universityName: data['universityName'] ?? 'Leading University',
    );
  }
}
