import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models.dart';
import '../../events/repositories/events_repository.dart';

class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _sectionDoc(String sectionId) =>
      _firestore.collection('sections').doc(sectionId);

  CollectionReference<Map<String, dynamic>> _eventsCol(String sectionId) =>
      _sectionDoc(sectionId).collection('events');

  CollectionReference<Map<String, dynamic>> _updatesCol(String sectionId) =>
      _sectionDoc(sectionId).collection('updates');

  @override
  Stream<Feed<AcademicEvent>> watchEvents(String sectionId) {
    return _eventsCol(sectionId).snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return Feed(const <AcademicEvent>[], updatedAt: DateTime.now());
      }
      final items = snap.docs.map((d) => AcademicEvent.fromJson(d.data())).toList();
      return Feed(items, updatedAt: DateTime.now());
    });
  }

  @override
  Stream<List<UpdateFeedItem>> watchUpdates(String sectionId) {
    return _updatesCol(sectionId)
        .orderBy('at', descending: true)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return const <UpdateFeedItem>[];
      }
      return snap.docs.map((d) => UpdateFeedItem.fromJson(d.data())).toList();
    });
  }

  @override
  Future<void> save(AcademicEvent event) async {
    await _eventsCol(event.sectionId).doc(event.id).set(event.toJson());

    // Also add to timeline updates feed
    final updateItem = UpdateFeedItem(
      id: 'upd_${DateTime.now().millisecondsSinceEpoch}',
      eventId: event.id,
      title: event.title,
      detail: '${event.type.label} on ${event.date.day}/${event.date.month}',
      at: DateTime.now(),
    );
    await _updatesCol(event.sectionId).doc(updateItem.id).set(updateItem.toJson());
  }

  @override
  Future<void> delete(String id) async {
    // Search across sections collection groups or target section
    final snap = await _firestore.collectionGroup('events').where('id', isEqualTo: id).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> refresh() async {}
}
