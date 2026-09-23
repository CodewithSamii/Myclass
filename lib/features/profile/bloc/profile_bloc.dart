import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';

class ProfileState extends Equatable {
  const ProfileState(this.profile, {this.error, this.saving = false});
  final UserProfile profile;
  final String? error;
  final bool saving;
  @override
  List<Object?> get props => [profile, error, saving];
}

sealed class ProfileEvent {}

class ProfileReceived extends ProfileEvent {
  ProfileReceived(this.profile);
  final UserProfile profile;
}

class ProfileSaved extends ProfileEvent {
  ProfileSaved(this.profile);
  final UserProfile profile;
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this.repository, UserProfile profile)
    : super(ProfileState(profile)) {
    on<ProfileReceived>((e, emit) => emit(ProfileState(e.profile)));
    on<ProfileSaved>((e, emit) async {
      emit(ProfileState(state.profile, saving: true));
      try {
        await repository.save(e.profile);
        emit(ProfileState(e.profile));
      } on AppFailure catch (f) {
        emit(ProfileState(state.profile, error: f.message));
      }
    });
    _sub = repository.watch(profile.uid).listen((p) {
      if (p != null) add(ProfileReceived(p));
    });
  }
  final ProfileRepository repository;
  late final StreamSubscription<UserProfile?> _sub;
  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
