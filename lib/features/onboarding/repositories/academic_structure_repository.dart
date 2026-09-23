import '../../../core/models.dart';

abstract interface class AcademicStructureRepository {
  Future<List<Department>> departments(String programType);
  Future<List<AcademicProgram>> programs(String departmentId, String type);
  Future<List<Batch>> batches(String programId);
  Future<List<Section>> sections(String batchId);
  Future<SectionGrant> verifyAccess(String sectionId, String code);
}
