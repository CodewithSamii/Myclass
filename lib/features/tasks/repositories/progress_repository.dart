import '../../../core/models.dart';

abstract interface class ProgressRepository {
  Stream<List<PersonalProgress>> watch(String uid);
  Future<void> save(String uid, PersonalProgress progress);
}
