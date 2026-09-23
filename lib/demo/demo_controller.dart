import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/clock.dart';

enum DemoScenario {
  inClass,
  morning,
  deadlinesOnly,
  examTomorrow,
  finished,
  weekend,
  semesterBreak,
  examOnly,
  crowded,
  unknownSchedule,
}

extension ScenarioLabel on DemoScenario {
  String get label => switch (this) {
    DemoScenario.inClass => 'In class',
    DemoScenario.morning => 'Before classes',
    DemoScenario.deadlinesOnly => 'Deadline-only day',
    DemoScenario.examTomorrow => 'Exam tomorrow',
    DemoScenario.finished => 'Day complete',
    DemoScenario.weekend => 'Quiet weekend',
    DemoScenario.semesterBreak => 'Semester break',
    DemoScenario.examOnly => 'Exam day',
    DemoScenario.crowded => 'Overlapping events',
    DemoScenario.unknownSchedule => 'Routine unavailable',
  };
}

class DemoState extends Equatable {
  const DemoState({
    this.scenario = DemoScenario.inClass,
    this.offline = false,
    this.stale = false,
    this.failNextSave = false,
    this.failNextLoad = false,
  });
  final DemoScenario scenario;
  final bool offline, stale, failNextSave, failNextLoad;
  DemoState copyWith({
    DemoScenario? scenario,
    bool? offline,
    bool? stale,
    bool? failNextSave,
    bool? failNextLoad,
  }) => DemoState(
    scenario: scenario ?? this.scenario,
    offline: offline ?? this.offline,
    stale: stale ?? this.stale,
    failNextSave: failNextSave ?? this.failNextSave,
    failNextLoad: failNextLoad ?? this.failNextLoad,
  );
  @override
  List<Object?> get props => [
    scenario,
    offline,
    stale,
    failNextSave,
    failNextLoad,
  ];
}

class DemoController extends Cubit<DemoState> implements AppClock {
  DemoController() : super(const DemoState());
  @override
  DateTime get now => switch (state.scenario) {
    DemoScenario.morning => DateTime(2026, 9, 21, 7, 40),
    DemoScenario.deadlinesOnly => DateTime(2026, 9, 25, 16),
    DemoScenario.examTomorrow => DateTime(2026, 9, 23, 18),
    DemoScenario.finished => DateTime(2026, 9, 22, 21),
    DemoScenario.weekend => DateTime(2026, 9, 26, 11),
    DemoScenario.semesterBreak => DateTime(2026, 10, 23, 10),
    DemoScenario.examOnly => DateTime(2026, 9, 24, 8),
    DemoScenario.crowded => DateTime(2026, 9, 22, 10),
    _ => DateTime(2026, 9, 21, 10, 48),
  };
  @override
  Stream<DateTime> get ticks => stream.map((_) => now);
  void scenario(DemoScenario v) => emit(state.copyWith(scenario: v));
  void offline(bool v) => emit(state.copyWith(offline: v));
  void stale(bool v) => emit(state.copyWith(stale: v));
  void failSave() => emit(state.copyWith(failNextSave: true));
  void failLoad() => emit(state.copyWith(failNextLoad: true));
  bool consumeSaveFailure() {
    final value = state.failNextSave;
    if (value) emit(state.copyWith(failNextSave: false));
    return value;
  }

  bool consumeLoadFailure() {
    final value = state.failNextLoad;
    if (value) emit(state.copyWith(failNextLoad: false));
    return value;
  }
}
