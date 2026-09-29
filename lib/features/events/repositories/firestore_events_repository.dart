import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models.dart';
import '../../events/repositories/events_repository.dart';
import '../../../demo/fixtures.dart';

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
        final defaultEvents = Fixtures.events(sectionId);
        _seedEventsIfNeeded(sectionId, defaultEvents);
        return Feed(defaultEvents, updatedAt: DateTime.now());
      }
      final items = snap.docs.map((d) => AcademicEvent.fromJson(d.data())).toList();
      return Feed(items, updatedAt: DateTime.now());
    });
  }

  Future<void> _seedEventsIfNeeded(String sectionId, List<AcademicEvent> eventsList) async {
    try {
      final snap = await _eventsCol(sectionId).limit(1).get();
      if (snap.docs.isEmpty && eventsList.isNotEmpty) {
        final batch = _firestore.batch();
        for (final e in eventsList) {
          batch.set(_eventsCol(sectionId).doc(e.id), e.toJson());
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  @override
  Stream<List<UpdateFeedItem>> watchUpdates(String sectionId) {
    return _updatesCol(sectionId)
        .orderBy('at', descending: true)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return [
          UpdateFeedItem(
            id: 'u1',
            eventId: '$sectionId-network-viva',
            title: 'Networking viva moved',
            detail: 'Room 401 → Room 602',
            at: DateTime(2026, 9, 21, 10, 40),
          ),
          UpdateFeedItem(
            id: 'u2',
            eventId: '$sectionId-postponed',
            title: 'Compiler viva postponed',
            detail: 'Sep 23 → Sep 28 · 11:00 AM',
            at: DateTime(2026, 9, 20, 16),
          ),
          UpdateFeedItem(
            id: 'u3',
            eventId: '$sectionId-late',
            title: 'Project logbook review added',
            detail: 'Today · 4:00 PM',
            at: DateTime(2026, 9, 21, 9),
          ),
        ];
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
