import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../core/clock.dart';

enum CalendarView { day, week, month }

class ScheduleState extends Equatable {
  const ScheduleState({
    required this.selected,
    required this.now,
    this.view = CalendarView.week,
    this.sessions = const [],
    this.courses = const [],
    this.periods = const [],
    this.timeSlots = const [],
    this.phase = LoadPhase.loading,
    this.error,
    this.saving = false,
  });
  final DateTime selected, now;
  final CalendarView view;
  final List<ClassSession> sessions;
  final List<Course> courses;
  final List<AcademicPeriod> periods;
  final List<TimeSlot> timeSlots;
  final LoadPhase phase;
  final String? error;
  final bool saving;
  Course course(String id) => courses.firstWhere(
    (c) => c.id == id,
    orElse: () => Course(
      id: id,
      name: 'Course details pending',
      facultyId: '',
      departmentId: '',
    ),
  );
  List<ClassSession> classesOn(DateTime d, {bool holiday = false}) =>
      holiday ? [] : sessions.where((s) => s.weekday == d.weekday).toList()
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  ScheduleState copyWith({
    DateTime? selected,
    DateTime? now,
    CalendarView? view,
    List<ClassSession>? sessions,
    List<Course>? courses,
    List<AcademicPeriod>? periods,
    List<TimeSlot>? timeSlots,
    LoadPhase? phase,
    String? error,
    bool? saving,
  }) => ScheduleState(
    selected: selected ?? this.selected,
    now: now ?? this.now,
    view: view ?? this.view,
    sessions: sessions ?? this.sessions,
    courses: courses ?? this.courses,
    periods: periods ?? this.periods,
    timeSlots: timeSlots ?? this.timeSlots,
    phase: phase ?? this.phase,
    error: error,
    saving: saving ?? this.saving,
  );
  @override
  List<Object?> get props => [
    selected,
    now,
    view,
    sessions,
    courses,
    periods,
    timeSlots,
    phase,
    error,
    saving,
  ];
}

sealed class ScheduleEvent {}

class ScheduleStarted extends ScheduleEvent {}

class ScheduleFailed extends ScheduleEvent {}

class ScheduleReceived extends ScheduleEvent {
  ScheduleReceived(this.feed);
  final Feed<ClassSession> feed;
}

class ScheduleDateSelected extends ScheduleEvent {
  ScheduleDateSelected(this.date);
  final DateTime date;
}

class ScheduleViewSelected extends ScheduleEvent {
  ScheduleViewSelected(this.view);
  final CalendarView view;
}

class ScheduleClockChanged extends ScheduleEvent {
  ScheduleClockChanged(this.now);
  final DateTime now;
}

class RoutineSaveRequested extends ScheduleEvent {
  RoutineSaveRequested(this.session);
  final ClassSession session;
}

class RoutineBulkSaveRequested extends ScheduleEvent {
  RoutineBulkSaveRequested(this.sessions);
  final List<ClassSession> sessions;
}

class TimeSlotsSaveRequested extends ScheduleEvent {
  TimeSlotsSaveRequested(this.slots);
  final List<TimeSlot> slots;
}

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc(this.repository, this.clock, this.section)
    : super(ScheduleState(selected: dateOnly(clock.now), now: clock.now)) {
    on<ScheduleFailed>(
      (e, emit) => emit(
        state.copyWith(
          phase: LoadPhase.error,
          error:
              'Could not update the class routine. Your saved classes remain available.',
        ),
      ),
    );
    on<ScheduleStarted>((e, emit) async {
      try {
        final results = await Future.wait([
          repository.courses(section),
          repository.periods(section),
          repository.timeSlots(section),
        ]);
        final courses = results[0] as List<Course>;
        final periods = results[1] as List<AcademicPeriod>;
        final slots = results[2] as List<TimeSlot>;
        emit(
          state.copyWith(
            courses: courses,
            periods: periods,
            timeSlots: slots,
            phase: LoadPhase.loaded,
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            phase: LoadPhase.error,
            error: 'Could not load your courses. Try again.',
          ),
        );
      }
    });
    on<ScheduleReceived>(
      (e, emit) => emit(
        state.copyWith(
          sessions: e.feed.items,
          phase: e.feed.unavailable
              ? LoadPhase.notFound
              : state.courses.isEmpty
              ? LoadPhase.loading
              : LoadPhase.loaded,
        ),
      ),
    );
    on<ScheduleDateSelected>(
      (e, emit) => emit(state.copyWith(selected: dateOnly(e.date))),
    );
    on<ScheduleViewSelected>((e, emit) => emit(state.copyWith(view: e.view)));
    on<ScheduleClockChanged>((e, emit) => emit(state.copyWith(now: e.now)));
    on<RoutineSaveRequested>((e, emit) async {
      emit(state.copyWith(saving: true));
      try {
        if (e.session.endMinute <= e.session.startMinute) {
          throw const AppFailure('The class must end after it starts.');
        }
        await repository.saveSession(e.session);
        emit(state.copyWith(saving: false));
      } on AppFailure catch (f) {
        emit(state.copyWith(saving: false, error: f.message));
      }
    });
    on<RoutineBulkSaveRequested>((e, emit) async {
      emit(state.copyWith(saving: true));
      try {
        await repository.saveRoutine(section, e.sessions);
        emit(state.copyWith(saving: false));
      } on AppFailure catch (f) {
        emit(state.copyWith(saving: false, error: f.message));
      }
    });
    on<TimeSlotsSaveRequested>((e, emit) async {
      emit(state.copyWith(saving: true));
      try {
        await repository.saveTimeSlots(section, e.slots);
        emit(state.copyWith(timeSlots: e.slots, saving: false));
      } on AppFailure catch (f) {
        emit(state.copyWith(saving: false, error: f.message));
      }
    });

    _sessions = repository
        .watchRoutine(section)
        .listen(
          (f) => add(ScheduleReceived(f)),
          onError: (_) => add(ScheduleFailed()),
        );
    _clock = clock.ticks.listen((now) => add(ScheduleClockChanged(now)));
    add(ScheduleStarted());
  }
  final ScheduleRepository repository;
  final AppClock clock;
  final String section;
  late final StreamSubscription<Feed<ClassSession>> _sessions;
  late final StreamSubscription<DateTime> _clock;
  @override
  Future<void> close() async {
    await _sessions.cancel();
    await _clock.cancel();
    return super.close();
  }
}
