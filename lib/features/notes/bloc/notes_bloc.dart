import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';

class NotesState extends Equatable {
  const NotesState({
    this.items = const [],
    this.saving = false,
    this.error,
    this.saved = 0,
  });
  final List<PersonalNote> items;
  final bool saving;
  final String? error;
  final int saved;
  NotesState copyWith({
    List<PersonalNote>? items,
    bool? saving,
    String? error,
    int? saved,
  }) => NotesState(
    items: items ?? this.items,
    saving: saving ?? this.saving,
    error: error,
    saved: saved ?? this.saved,
  );
  @override
  List<Object?> get props => [items, saving, error, saved];
}

sealed class NotesEvent {}

class NotesFailed extends NotesEvent {}

class NotesReceived extends NotesEvent {
  NotesReceived(this.items);
  final List<PersonalNote> items;
}

class NoteSaved extends NotesEvent {
  NoteSaved({this.id, required this.text, this.eventId, this.remindAt});
  final String? id, eventId;
  final String text;
  final DateTime? remindAt;
}

class NoteDeleted extends NotesEvent {
  NoteDeleted(this.id);
  final String id;
}

class NoteToggled extends NotesEvent {
  NoteToggled(this.note);
  final PersonalNote note;
}

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc(this.repository, this.uid) : super(const NotesState()) {
    on<NotesFailed>(
      (e, emit) => emit(
        state.copyWith(
          error:
              'Could not refresh your private notes. Your saved notes remain available.',
        ),
      ),
    );
    on<NotesReceived>((e, emit) => emit(state.copyWith(items: e.items)));
    on<NoteSaved>((e, emit) async {
      if (e.text.trim().isEmpty) {
        emit(state.copyWith(error: 'Write a note before saving.'));
        return;
      }
      emit(state.copyWith(saving: true));
      try {
        await repository.save(
          PersonalNote(
            id: e.id ?? 'note-${DateTime.now().microsecondsSinceEpoch}',
            uid: uid,
            text: e.text.trim(),
            updatedAt: DateTime.now(),
            eventId: e.eventId,
            remindAt: e.remindAt,
          ),
        );
        emit(state.copyWith(saving: false, saved: state.saved + 1));
      } on AppFailure catch (f) {
        emit(state.copyWith(saving: false, error: f.message));
      }
    });
    on<NoteDeleted>((e, emit) async {
      try {
        await repository.delete(uid, e.id);
      } on AppFailure catch (f) {
        emit(state.copyWith(error: f.message));
      }
    });
    on<NoteToggled>((e, emit) async {
      try {
        await repository.save(e.note.copyWith(completed: !e.note.completed));
      } on AppFailure catch (f) {
        emit(state.copyWith(error: f.message));
      }
    });
    _sub = repository
        .watchNotes(uid)
        .listen(
          (v) => add(NotesReceived(v)),
          onError: (_) => add(NotesFailed()),
        );
  }
  final NotesRepository repository;
  final String uid;
  late final StreamSubscription<List<PersonalNote>> _sub;
  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
