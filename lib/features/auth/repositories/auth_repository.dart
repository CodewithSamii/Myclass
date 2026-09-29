class AuthIdentity {
  const AuthIdentity(
    this.uid,
    this.email, {
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });

  final String uid, email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
}

abstract interface class AuthRepository {
  Future<AuthIdentity?> restore();
  Future<AuthIdentity> signInWithGoogle();
  Future<AuthIdentity> signInWithEmail(String email, String password);
  Future<AuthIdentity> registerWithEmail(String email, String password);
  Future<AuthIdentity> signInAnonymously();
  Future<void> signOut();
  Stream<AuthIdentity?> watchAuthState();
}
