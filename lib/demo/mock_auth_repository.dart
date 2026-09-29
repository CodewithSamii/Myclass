import 'package:shared_preferences/shared_preferences.dart';
import '../core/repositories.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this.preferences);
  final SharedPreferences preferences;

  @override
  Future<AuthIdentity?> restore() async =>
      (preferences.getBool('myclass.signedIn') ?? preferences.getBool('aula.signedIn')) == true
      ? const AuthIdentity('demo-student', 'student@example.edu', displayName: 'Student User')
      : null;

  @override
  Future<AuthIdentity> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await preferences.setBool('myclass.signedIn', true);
    return const AuthIdentity('demo-student', 'student@example.edu', displayName: 'Student User');
  }

  @override
  Future<AuthIdentity> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await preferences.setBool('myclass.signedIn', true);
    return AuthIdentity('demo-user', email, displayName: email.split('@').first);
  }

  @override
  Future<AuthIdentity> registerWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await preferences.setBool('myclass.signedIn', true);
    return AuthIdentity('demo-user', email, displayName: email.split('@').first);
  }

  @override
  Future<AuthIdentity> signInAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await preferences.setBool('myclass.signedIn', true);
    return const AuthIdentity('demo-guest', '', isAnonymous: true, displayName: 'Guest');
  }

  @override
  Future<void> signOut() async {
    await preferences.setBool('myclass.signedIn', false);
    await preferences.setBool('aula.signedIn', false);
  }

  @override
  Stream<AuthIdentity?> watchAuthState() => Stream.value(
    (preferences.getBool('myclass.signedIn') ?? false)
        ? const AuthIdentity('demo-student', 'student@example.edu', displayName: 'Student User')
        : null,
  );
}
