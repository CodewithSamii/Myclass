import '../../../core/models.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> load(String uid);
  Stream<UserProfile?> watch(String uid);
  Future<void> save(UserProfile profile, {SectionGrant? grant});
}
