import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';

class EventsState extends Equatable {
  const EventsState({
    this.items = const [],
    this.updates = const [],
    this.phase = LoadPhase.loading,
    this.offline = false,
    this.stale = false,
    this.error,
    this.updatedAt,
  });
  final List<AcademicEvent> items;
  final List<UpdateFeedItem> updates;
  final LoadPhase phase;
  final bool offline, stale;
  final String? error;
  final DateTime? updatedAt;
  AcademicEvent? byId(String id) {
    for (final e in items) {
      if (e.id == id) return e;
    }
    return null;
  }

  EventsState copyWith({
    List<AcademicEvent>? items,
    List<UpdateFeedItem>? updates,
    LoadPhase? phase,
    bool? offline,
    bool? stale,
    String? error,
    DateTime? updatedAt,
  }) => EventsState(
    items: items ?? this.items,
    updates: updates ?? this.updates,
    phase: phase ?? this.phase,
    offline: offline ?? this.offline,
    stale: stale ?? this.stale,
    error: error,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  @override
  List<Object?> get props => [
    items,
    updates,
    phase,
    offline,
    stale,
    error,
    updatedAt,
  ];
}

sealed class EventsEvent {}

class EventsReceived extends EventsEvent {
  EventsReceived(this.feed);
  final Feed<AcademicEvent> feed;
}

class UpdatesReceived extends EventsEvent {
  UpdatesReceived(this.items);
  final List<UpdateFeedItem> items;
}

class EventsRefresh extends EventsEvent {}

class EventDeleteRequested extends EventsEvent {
  EventDeleteRequested(this.id);
  final String id;
}

class EventStatusRequested extends EventsEvent {
  EventStatusRequested(this.event, this.status, this.at);
  final AcademicEvent event;
  final EventStatus status;
  final DateTime at;
}

class EventsFailed extends EventsEvent {
  EventsFailed(this.message);
  final String message;
}

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  EventsBloc(this.repository, String section) : super(const EventsState()) {
    on<EventsReceived>(
      (e, emit) => emit(
        state.copyWith(
          items: e.feed.items,
          offline: e.feed.offline,
          stale: e.feed.stale,
          updatedAt: e.feed.updatedAt,
          phase: e.feed.items.isEmpty ? LoadPhase.empty : LoadPhase.loaded,
        ),
      ),
    );
    on<UpdatesReceived>((e, emit) => emit(state.copyWith(updates: e.items)));
    on<EventsFailed>(
      (e, emit) =>
          emit(state.copyWith(phase: LoadPhase.error, error: e.message)),
    );
    on<EventsRefresh>((e, emit) async {
      try {
        await repository.refresh();
      } on AppFailure catch (f) {
        emit(state.copyWith(phase: f.phase, error: f.message));
      }
    });
    on<EventDeleteRequested>((e, emit) async {
      try {
        await repository.delete(e.id);
      } on AppFailure catch (f) {
        emit(state.copyWith(phase: f.phase, error: f.message));
      }
    });
    on<EventStatusRequested>((e, emit) async {
      try {
        await repository.save(
          e.event.copyWith(
            status: e.status,
            updatedAt: e.at,
            changeHistory: [
              ...e.event.changeHistory,
              ScheduleChange(
                id: '${DateTime.now().microsecondsSinceEpoch}',
                label: 'Status changed',
                before: e.event.status.label,
                after: e.status.label,
                at: e.at,
                author: 'Class representative',
              ),
            ],
          ),
        );
      } on AppFailure catch (f) {
        emit(state.copyWith(phase: f.phase, error: f.message));
      }
    });
    _events = repository
        .watchEvents(section)
        .listen(
          (v) => add(EventsReceived(v)),
          onError: (_) => add(
            EventsFailed('Your events could not be loaded. Try refreshing.'),
          ),
        );
    _updates = repository
        .watchUpdates(section)
        .listen(
          (v) => add(UpdatesReceived(v)),
          onError: (_) => add(
            EventsFailed(
              'Recent updates could not be refreshed. Your saved schedule is still here.',
            ),
          ),
        );
  }
  final EventRepository repository;
  late final StreamSubscription<Feed<AcademicEvent>> _events;
  late final StreamSubscription<List<UpdateFeedItem>> _updates;
  @override
  Future<void> close() async {
    await _events.cancel();
    await _updates.cancel();
    return super.close();
  }
}
