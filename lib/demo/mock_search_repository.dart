import '../core/repositories.dart';
import '../core/models.dart';
import 'fixtures.dart';
import 'mock_store.dart';

class MockSearchRepository implements SearchRepository {
  MockSearchRepository(this.store);
  final MockStore store;
  @override
  Future<List<SearchHit>> search(
    String query, {
    required String uid,
    required String sectionId,
  }) async {
    await store.delay();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final hits = <SearchHit>[
      for (final e in store.eventsFor(sectionId))
        SearchHit(
          SearchKind.event,
          e.id,
          e.title,
          '${e.type.label} · ${Fixtures.courses.where((c) => c.id == e.courseId).first.name}',
        ),
      for (final c in Fixtures.coursesFor(sectionId))
        SearchHit(SearchKind.course, c.id, c.name, c.code ?? 'Course'),
      for (final f in Fixtures.faculty)
        SearchHit(
          SearchKind.faculty,
          f.id,
          f.name,
          '${f.designation} · ${f.departmentId.toUpperCase()}',
        ),
      for (final r in Fixtures.routes)
        SearchHit(
          SearchKind.bus,
          r.id,
          'Route ${r.number} · ${r.name}',
          r.stops.map((s) => s.name).join(' · '),
        ),
      for (final n in store.notes[uid] ?? <PersonalNote>[])
        SearchHit(SearchKind.note, n.id, n.text, 'Private note'),
    ];
    return hits
        .where((h) => '${h.title} ${h.subtitle}'.toLowerCase().contains(q))
        .toList();
  }
}
