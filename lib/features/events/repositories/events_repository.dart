import '../../../core/models.dart';

abstract interface class EventRepository {
  Stream<Feed<AcademicEvent>> watchEvents(String sectionId);
  Stream<List<UpdateFeedItem>> watchUpdates(String sectionId);
  Future<void> save(AcademicEvent event);
  Future<void> delete(String id);
  Future<void> refresh();
}
