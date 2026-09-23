import '../core/models.dart';
import '../core/repositories.dart';
import 'mock_store.dart';

class MockEventRepository implements EventRepository {
  MockEventRepository(this.store);
  final MockStore store;
  @override
  Stream<Feed<AcademicEvent>> watchEvents(String sectionId) => store.watch(
    () => Feed(
      List.unmodifiable(store.eventsFor(sectionId)),
      offline: store.demo.state.offline,
      stale: store.demo.state.stale,
      updatedAt: store.updatedAt,
    ),
  );
  @override
  Stream<List<UpdateFeedItem>> watchUpdates(String sectionId) => store.watch(
    () => List.unmodifiable(
      store.updates.putIfAbsent(
        sectionId,
        () => [
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
        ],
      ),
    ),
  );
  @override
  Future<void> save(AcademicEvent event) async {
    await store.checkWrite(shared: true, section: event.sectionId);
    final list = store.eventsFor(event.sectionId);
    final i = list.indexWhere((e) => e.id == event.id);
    if (i < 0) {
      list.add(event);
    } else {
      list[i] = event;
    }
    final updates = store.updates.putIfAbsent(event.sectionId, () => []);
    updates.insert(
      0,
      UpdateFeedItem(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        eventId: event.id,
        title: i < 0
            ? '${event.title} added'
            : '${event.title} ${event.status == EventStatus.cancelled ? 'cancelled' : 'updated'}',
        detail: event.changeHistory.isEmpty
            ? 'New academic update'
            : '${event.changeHistory.last.label}: ${event.changeHistory.last.before} → ${event.changeHistory.last.after}',
        at: store.demo.now,
      ),
    );
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }

  @override
  Future<void> delete(String id) async {
    final section = store.profile?.activeSectionId;
    await store.checkWrite(shared: true, section: section);
    store.eventsFor(section!).removeWhere((e) => e.id == id);
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }

  @override
  Future<void> refresh() async {
    await store.delay();
    if (store.demo.consumeLoadFailure()) {
      throw const AppFailure(
        'Could not refresh your schedule. Your saved events are still available.',
      );
    }
    if (!store.demo.state.offline) store.updatedAt = store.demo.now;
    store.notify();
  }
}
