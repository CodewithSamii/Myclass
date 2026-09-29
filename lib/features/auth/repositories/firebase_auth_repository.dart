import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/result.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    required this.preferences,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final SharedPreferences preferences;

  AuthIdentity _mapUser(User user) => AuthIdentity(
        user.uid,
        user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAnonymous: user.isAnonymous,
      );

  @override
  Future<AuthIdentity?> restore() async {
    final user = _auth.currentUser;
    if (user != null) {
      await preferences.setString('firebase_auth_uid', user.uid);
      return _mapUser(user);
    }
    return null;
  }

  @override
  Future<AuthIdentity> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user == null) {
          throw const AppFailure('Google sign-in did not complete.');
        }
        await preferences.setString('firebase_auth_uid', user.uid);
        return _mapUser(user);
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AppFailure('Google sign-in cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AppFailure('Failed to authenticate with Google credentials.');
      }
      await preferences.setString('firebase_auth_uid', user.uid);
      return _mapUser(user);
    } on FirebaseAuthException catch (e) {
      throw AppFailure(e.message ?? 'Authentication error occurred.');
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(e.toString());
    }
  }

  @override
  Future<AuthIdentity> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AppFailure('User not found.');
      }
      await preferences.setString('firebase_auth_uid', user.uid);
      return _mapUser(user);
    } on FirebaseAuthException catch (e) {
      throw AppFailure(switch (e.code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email' => 'Please enter a valid email address.',
        'user-disabled' => 'This account has been disabled.',
        _ => e.message ?? 'Failed to sign in.',
      });
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(e.toString());
    }
  }

  @override
  Future<AuthIdentity> registerWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AppFailure('Could not register account.');
      }
      await preferences.setString('firebase_auth_uid', user.uid);
      return _mapUser(user);
    } on FirebaseAuthException catch (e) {
      throw AppFailure(switch (e.code) {
        'email-already-in-use' => 'An account already exists for this email.',
        'weak-password' => 'Password is too weak. Please use at least 6 characters.',
        'invalid-email' => 'Please enter a valid email address.',
        _ => e.message ?? 'Registration failed.',
      });
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(e.toString());
    }
  }

  @override
  Future<AuthIdentity> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      final user = cred.user;
      if (user == null) {
        throw const AppFailure('Could not create anonymous session.');
      }
      await preferences.setString('firebase_auth_uid', user.uid);
      return _mapUser(user);
    } on FirebaseAuthException catch (e) {
      throw AppFailure(e.message ?? 'Anonymous sign-in failed.');
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    await preferences.remove('firebase_auth_uid');
  }

  @override
  Stream<AuthIdentity?> watchAuthState() {
    return _auth.authStateChanges().map((u) => u == null ? null : _mapUser(u));
  }
}
