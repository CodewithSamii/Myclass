import '../../../core/models.dart';

abstract interface class ScheduleRepository {
  Stream<Feed<ClassSession>> watchRoutine(String sectionId);
  Future<List<Course>> courses(String sectionId);
  Future<List<AcademicPeriod>> periods(String sectionId);
  Future<List<TimeSlot>> timeSlots(String sectionId);
  Future<void> saveTimeSlots(String sectionId, List<TimeSlot> slots);
  Future<void> saveRoutine(String sectionId, List<ClassSession> sessions);
  Future<void> saveSession(ClassSession session);
  Future<void> refresh();
}

