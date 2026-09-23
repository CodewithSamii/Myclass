import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = 0,
    this.name = '',
    this.type,
    this.department,
    this.program,
    this.batch,
    this.section,
    this.grant,
    this.busy = false,
    this.error,
  });
  final int step;
  final String name;
  final String? type;
  final Department? department;
  final AcademicProgram? program;
  final Batch? batch;
  final Section? section;
  final SectionGrant? grant;
  final bool busy;
  final String? error;
  bool get valid => name.trim().isNotEmpty && section != null;
  SectionMembership get membership => SectionMembership(
    sectionId: section!.id,
    departmentId: department!.id,
    programId: program!.id,
    batchId: batch!.id,
    programName: program!.name,
    batchName: batch!.label,
    sectionName: section!.label,
  );
  OnboardingState copyWith({
    int? step,
    String? name,
    String? type,
    Department? department,
    AcademicProgram? program,
    Batch? batch,
    Section? section,
    SectionGrant? grant,
    bool? busy,
    String? error,
  }) => OnboardingState(
    step: step ?? this.step,
    name: name ?? this.name,
    type: type ?? this.type,
    department: department ?? this.department,
    program: program ?? this.program,
    batch: batch ?? this.batch,
    section: section ?? this.section,
    grant: grant ?? this.grant,
    busy: busy ?? this.busy,
    error: error,
  );
  @override
  List<Object?> get props => [
    step,
    name,
    type,
    department,
    program,
    batch,
    section,
    grant,
    busy,
    error,
  ];
}

sealed class OnboardingEvent {}

class SetupNameChanged extends OnboardingEvent {
  SetupNameChanged(this.value);
  final String value;
}

class SetupChoiceChanged extends OnboardingEvent {
  SetupChoiceChanged(this.value);
  final Object value;
}

class SetupAdvanced extends OnboardingEvent {}

class SetupBack extends OnboardingEvent {}

class SetupCodeSubmitted extends OnboardingEvent {
  SetupCodeSubmitted(this.code);
  final String code;
}

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this.repository) : super(const OnboardingState()) {
    on<SetupNameChanged>((e, emit) => emit(state.copyWith(name: e.value)));
    on<SetupChoiceChanged>((e, emit) {
      final v = e.value;
      if (v is String) emit(OnboardingState(name: state.name, type: v));
      if (v is Department) {
        emit(
          OnboardingState(name: state.name, type: state.type, department: v),
        );
      }
      if (v is AcademicProgram) {
        emit(
          OnboardingState(
            name: state.name,
            type: state.type,
            department: state.department,
            program: v,
          ),
        );
      }
      if (v is Batch) {
        emit(
          OnboardingState(
            name: state.name,
            type: state.type,
            department: state.department,
            program: state.program,
            batch: v,
          ),
        );
      }
      if (v is Section) {
        emit(
          OnboardingState(
            name: state.name,
            type: state.type,
            department: state.department,
            program: state.program,
            batch: state.batch,
            section: v,
          ),
        );
      }
    });
    on<SetupAdvanced>((e, emit) {
      if (state.valid) emit(state.copyWith(step: 1));
    });
    on<SetupBack>((e, emit) {
      if (state.step > 0) emit(state.copyWith(step: state.step - 1));
    });
    on<SetupCodeSubmitted>((e, emit) async {
      if (state.busy || state.section == null) return;
      emit(state.copyWith(busy: true));
      try {
        final g = await repository.verifyAccess(state.section!.id, e.code);
        emit(state.copyWith(step: 2, grant: g, busy: false));
      } on AppFailure catch (f) {
        emit(state.copyWith(busy: false, error: f.message));
      } catch (_) {
        emit(
          state.copyWith(
            busy: false,
            error: 'Could not check this code. Please try again.',
          ),
        );
      }
    });
  }
  final AcademicStructureRepository repository;
}
