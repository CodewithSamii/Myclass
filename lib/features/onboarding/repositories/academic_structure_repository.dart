import '../../../core/models.dart';

abstract interface class AcademicStructureRepository {
  Future<List<University>> universities();
  Future<List<Department>> departments(String programType, {String? universityId});
  Future<List<AcademicProgram>> programs(String departmentId, String type, {String? universityId});
  Future<List<Batch>> batches(String programId);
  Future<List<Section>> sections(String batchId);
  Future<List<Section>> approvedSections(String batchId);
  Future<List<Section>> pendingSections();
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
  });
  Future<void> approveSection(String sectionId);
  Future<void> rejectSection(String sectionId);
  Future<SectionGrant> verifyAccess(String sectionId, String code);
  Future<SectionGrant> verifyRoleAccess(
    String sectionId, {
    required bool isAdmin,
    required String password,
  });
}

