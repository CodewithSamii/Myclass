import '../../../core/models.dart';

abstract interface class ScheduleRepository {
  Stream<Feed<ClassSession>> watchRoutine(String sectionId);
  Future<List<Course>> courses(String sectionId);
  Future<List<AcademicPeriod>> periods(String sectionId);
  Future<void> saveSession(ClassSession session);
  Future<void> refresh();
}
