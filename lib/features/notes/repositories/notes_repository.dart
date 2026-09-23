import '../../../core/models.dart';

abstract interface class NotesRepository {
  Stream<List<PersonalNote>> watchNotes(String uid);
  Future<void> save(PersonalNote note);
  Future<void> delete(String uid, String id);
}
