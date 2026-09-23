import '../core/models.dart';
import '../core/repositories.dart';
import 'fixtures.dart';

class MockAcademicStructureRepository implements AcademicStructureRepository {
  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 180));
  @override
  Future<List<Department>> departments(String programType) async {
    await _delay();
    return Fixtures.departments
        .where(
          (d) => Fixtures.programs.any(
            (p) => p.departmentId == d.id && p.type == programType,
          ),
        )
        .toList();
  }

  @override
  Future<List<AcademicProgram>> programs(
    String departmentId,
    String type,
  ) async {
    await _delay();
    return Fixtures.programs
        .where((p) => p.departmentId == departmentId && p.type == type)
        .toList();
  }

  @override
  Future<List<Batch>> batches(String programId) async {
    await _delay();
    return [
      for (final n in [64, 63, 62, 61, 60, 59, 58])
        Batch('$programId-$n', programId, 'Batch $n'),
    ];
  }

  @override
  Future<List<Section>> sections(String batchId) async {
    await _delay();
    return [
      for (final s in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'])
        Section('$batchId-$s', batchId, 'Section $s'),
    ];
  }

  @override
  Future<SectionGrant> verifyAccess(String sectionId, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    // Public fixture credential only, not a production password or client-side secret.
    // Replace this adapter with a trusted backend callable that returns an opaque grant.
    final normalized = code.trim().toUpperCase();
    if (normalized != 'MYCLASS64' && normalized != 'CLASS64' && normalized != 'AULA64') {
      throw const AppFailure(
        'That code did not match. Check it with your class representative and try again.',
      );
    }
    return SectionGrant(sectionId, 'mock-opaque-grant');
  }
}
