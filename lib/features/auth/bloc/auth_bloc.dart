import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';

enum AuthPhase { loading, introduction, returning, setup, ready, failure }

class AuthState extends Equatable {
  const AuthState(
    this.phase, {
    this.identity,
    this.profile,
    this.error,
    this.busy = false,
  });
  final AuthPhase phase;
  final AuthIdentity? identity;
  final UserProfile? profile;
  final String? error;
  final bool busy;
  @override
  List<Object?> get props => [phase, identity, profile, error, busy];
}

sealed class AuthEvent {}

class AuthStarted extends AuthEvent {}

class AuthBeginSetup extends AuthEvent {}

class AuthReturningRequested extends AuthEvent {}

class AuthGoogleRequested extends AuthEvent {}

class AuthSetupSaved extends AuthEvent {
  AuthSetupSaved(this.name, this.membership, this.grant);
  final String name;
  final SectionMembership membership;
  final SectionGrant grant;
}

class AuthLoggedOut extends AuthEvent {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.auth, this.profiles)
    : super(const AuthState(AuthPhase.loading)) {
    on<AuthStarted>((e, emit) async {
      try {
        final id = await auth.restore();
        if (id == null) {
          emit(const AuthState(AuthPhase.introduction));
          return;
        }
        final p = await profiles.load(id.uid);
        emit(
          AuthState(
            p == null ? AuthPhase.setup : AuthPhase.ready,
            identity: id,
            profile: p,
          ),
        );
      } catch (_) {
        emit(
          const AuthState(
            AuthPhase.returning,
            error: 'Could not restore your session. Try signing in again.',
          ),
        );
      }
    });
    on<AuthBeginSetup>(
      (e, emit) => emit(AuthState(AuthPhase.setup, identity: state.identity)),
    );
    on<AuthReturningRequested>(
      (e, emit) => emit(const AuthState(AuthPhase.returning)),
    );
    on<AuthGoogleRequested>((e, emit) async {
      if (state.busy) return;
      emit(AuthState(state.phase, identity: state.identity, busy: true));
      try {
        final id = await auth.signInWithGoogle();
        final p = await profiles.load(id.uid);
        emit(
          AuthState(
            p == null ? AuthPhase.setup : AuthPhase.ready,
            identity: id,
            profile: p,
          ),
        );
      } catch (_) {
        emit(
          const AuthState(
            AuthPhase.returning,
            error: 'Sign-in did not finish. Please try again.',
          ),
        );
      }
    });
    on<AuthSetupSaved>((e, emit) async {
      if (state.busy) return;
      emit(AuthState(AuthPhase.setup, identity: state.identity, busy: true));
      try {
        final id = state.identity ?? await auth.signInWithGoogle();
        final p = UserProfile(
          uid: id.uid,
          name: e.name.trim(),
          email: id.email,
          memberships: [e.membership],
          activeSectionId: e.membership.sectionId,
        );
        await profiles.save(p, grant: e.grant);
        emit(AuthState(AuthPhase.ready, identity: id, profile: p));
      } on AppFailure catch (f) {
        emit(
          AuthState(
            AuthPhase.setup,
            identity: state.identity,
            error: f.message,
          ),
        );
      } catch (_) {
        emit(
          AuthState(
            AuthPhase.setup,
            identity: state.identity,
            error: 'Could not save your setup. Your selections are still here.',
          ),
        );
      }
    });
    on<AuthLoggedOut>((e, emit) async {
      await auth.signOut();
      emit(const AuthState(AuthPhase.returning));
    });
  }
  final AuthRepository auth;
  final ProfileRepository profiles;
}
