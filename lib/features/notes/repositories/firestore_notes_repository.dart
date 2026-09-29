import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models.dart';
import '../../notes/repositories/notes_repository.dart';

class FirestoreNotesRepository implements NotesRepository {
  FirestoreNotesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('notes');

  @override
  Stream<List<PersonalNote>> watchNotes(String uid) {
    return _notesCol(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => PersonalNote.fromJson(d.data())).toList();
    });
  }

  @override
  Future<void> save(PersonalNote note) async {
    await _notesCol(note.uid).doc(note.id).set(
      note.toJson(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> delete(String uid, String id) async {
    await _notesCol(uid).doc(id).delete();
  }
}
