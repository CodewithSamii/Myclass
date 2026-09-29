import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myclass/core/repositories.dart';
import 'package:myclass/demo/mock_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository Contract Tests', () {
    late SharedPreferences prefs;
    late AuthRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'myclass.signedIn': false});
      prefs = await SharedPreferences.getInstance();
      repo = MockAuthRepository(prefs);
    });

    test('restore returns null when not signed in', () async {
      final user = await repo.restore();
      expect(user, isNull);
    });

    test('signInWithGoogle signs in and persists state', () async {
      final user = await repo.signInWithGoogle();
      expect(user.uid, 'demo-student');
      expect(user.email, 'student@example.edu');

      final restored = await repo.restore();
      expect(restored?.uid, 'demo-student');
    });

    test('signInWithEmail signs in with provided email', () async {
      final user = await repo.signInWithEmail('prof@university.edu', 'pass123');
      expect(user.email, 'prof@university.edu');
      expect(user.uid, 'demo-user');
    });

    test('signInAnonymously creates anonymous guest session', () async {
      final user = await repo.signInAnonymously();
      expect(user.isAnonymous, isTrue);
    });

    test('signOut clears persisted sign-in flag', () async {
      await repo.signInWithGoogle();
      expect(await repo.restore(), isNotNull);

      await repo.signOut();
      expect(await repo.restore(), isNull);
    });
  });
}
