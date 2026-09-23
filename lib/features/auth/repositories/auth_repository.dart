class AuthIdentity {
  const AuthIdentity(this.uid, this.email);
  final String uid, email;
}

abstract interface class AuthRepository {
  Future<AuthIdentity?> restore();
  Future<AuthIdentity> signInWithGoogle();
  Future<void> signOut();
}
