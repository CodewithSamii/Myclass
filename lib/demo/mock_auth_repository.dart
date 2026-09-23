import 'package:shared_preferences/shared_preferences.dart';
import '../core/repositories.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this.preferences);
  final SharedPreferences preferences;
  @override
  Future<AuthIdentity?> restore() async =>
      preferences.getBool('aula.signedIn') == true
      ? const AuthIdentity('demo-student', 'student@example.edu')
      : null;
  @override
  Future<AuthIdentity> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await preferences.setBool('aula.signedIn', true);
    return const AuthIdentity('demo-student', 'student@example.edu');
  }

  @override
  Future<void> signOut() async {
    await preferences.setBool('aula.signedIn', false);
  }
}
