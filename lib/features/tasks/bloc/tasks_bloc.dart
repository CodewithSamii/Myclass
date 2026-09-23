import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/sequential.dart';
import '../../../core/repositories.dart';

enum TaskGrouping { date, course, type }

class TasksState extends Equatable {
  const TasksState({
    this.progress = const [],
    this.filter,
    this.grouping = TaskGrouping.date,
    this.showCompleted = false,
    this.error,
  });
  final List<PersonalProgress> progress;
  final AcademicEventType? filter;
  final TaskGrouping grouping;
  final bool showCompleted;
  final String? error;
  PersonalProgress forEvent(String id) => progress.firstWhere(
    (p) => p.eventId == id,
    orElse: () => PersonalProgress(eventId: id),
  );
  TasksState copyWith({
    List<PersonalProgress>? progress,
    AcademicEventType? filter,
    bool clearFilter = false,
    TaskGrouping? grouping,
    bool? showCompleted,
    String? error,
  }) => TasksState(
    progress: progress ?? this.progress,
    filter: clearFilter ? null : filter ?? this.filter,
    grouping: grouping ?? this.grouping,
    showCompleted: showCompleted ?? this.showCompleted,
    error: error,
  );
  @override
  List<Object?> get props => [progress, filter, grouping, showCompleted, error];
}

sealed class TasksEvent {}

class ProgressFailed extends TasksEvent {}

class ProgressReceived extends TasksEvent {
  ProgressReceived(this.items);
  final List<PersonalProgress> items;
}

class TaskToggled extends TasksEvent {
  TaskToggled(this.id);
  final String id;
}

class TaskFilterChanged extends TasksEvent {
  TaskFilterChanged(this.type);
  final AcademicEventType? type;
}

class TaskGroupingChanged extends TasksEvent {
  TaskGroupingChanged(this.grouping);
  final TaskGrouping grouping;
}

class CompletedVisibilityChanged extends TasksEvent {
  CompletedVisibilityChanged(this.show);
  final bool show;
}

class EventRemindersChanged extends TasksEvent {
  EventRemindersChanged(this.id, this.offsets);
  final String id;
  final List<int>? offsets;
}

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc(this.repository, this.uid) : super(const TasksState()) {
    on<ProgressFailed>(
      (e, emit) => emit(
        state.copyWith(
          error: 'Could not refresh your progress. Try again shortly.',
        ),
      ),
    );
    on<ProgressReceived>((e, emit) => emit(state.copyWith(progress: e.items)));
    on<TaskFilterChanged>(
      (e, emit) =>
          emit(state.copyWith(filter: e.type, clearFilter: e.type == null)),
    );
    on<TaskGroupingChanged>(
      (e, emit) => emit(state.copyWith(grouping: e.grouping)),
    );
    on<CompletedVisibilityChanged>(
      (e, emit) => emit(state.copyWith(showCompleted: e.show)),
    );
    on<TaskToggled>((e, emit) async {
      final old = state.forEvent(e.id);
      final next = old.copyWith(completed: !old.completed);
      try {
        await repository.save(uid, next);
        emit(
          state.copyWith(
            progress: [...state.progress.where((p) => p.eventId != e.id), next],
          ),
        );
      } on AppFailure catch (f) {
        emit(state.copyWith(error: f.message));
      }
    }, transformer: sequential());
    on<EventRemindersChanged>((e, emit) async {
      try {
        await repository.save(
          uid,
          state
              .forEvent(e.id)
              .copyWith(reminderOffsets: e.offsets, inherit: e.offsets == null),
        );
      } on AppFailure catch (f) {
        emit(state.copyWith(error: f.message));
      }
    }, transformer: sequential());
    _sub = repository
        .watch(uid)
        .listen(
          (p) => add(ProgressReceived(p)),
          onError: (_) => add(ProgressFailed()),
        );
  }
  final ProgressRepository repository;
  final String uid;
  late final StreamSubscription<List<PersonalProgress>> _sub;
  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
