import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models.dart';
import '../../tasks/repositories/progress_repository.dart';

class FirestoreProgressRepository implements ProgressRepository {
  FirestoreProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _progressCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('progress');

  @override
  Stream<List<PersonalProgress>> watch(String uid) {
    return _progressCol(uid).snapshots().map((snap) {
      return snap.docs.map((d) => PersonalProgress.fromJson(d.data())).toList();
    });
  }

  @override
  Future<void> save(String uid, PersonalProgress progress) async {
    await _progressCol(uid).doc(progress.eventId).set(
      progress.toJson(),
      SetOptions(merge: true),
    );
  }
}
