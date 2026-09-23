enum SearchKind { event, course, faculty, bus, note }

class SearchHit {
  const SearchHit(this.kind, this.id, this.title, this.subtitle);
  final SearchKind kind;
  final String id, title, subtitle;
}

abstract interface class SearchRepository {
  Future<List<SearchHit>> search(
    String query, {
    required String uid,
    required String sectionId,
  });
}
