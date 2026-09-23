import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';

class CampusState extends Equatable {
  const CampusState({
    this.routes = const [],
    this.faculty = const [],
    this.phase = LoadPhase.loading,
    this.department,
    this.query = '',
  });
  final List<BusRoute> routes;
  final List<FacultyMember> faculty;
  final LoadPhase phase;
  final String? department;
  final String query;
  List<FacultyMember> get visibleFaculty => faculty
      .where(
        (f) =>
            (department == null || f.departmentId == department) &&
            '${f.name} ${f.designation}'.toLowerCase().contains(
              query.toLowerCase(),
            ),
      )
      .toList();
  CampusState copyWith({
    List<BusRoute>? routes,
    List<FacultyMember>? faculty,
    LoadPhase? phase,
    String? department,
    bool clearDepartment = false,
    String? query,
  }) => CampusState(
    routes: routes ?? this.routes,
    faculty: faculty ?? this.faculty,
    phase: phase ?? this.phase,
    department: clearDepartment ? null : department ?? this.department,
    query: query ?? this.query,
  );
  @override
  List<Object?> get props => [routes, faculty, phase, department, query];
}

sealed class CampusEvent {}

class CampusStarted extends CampusEvent {}

class FacultyFilterChanged extends CampusEvent {
  FacultyFilterChanged(this.department);
  final String? department;
}

class FacultyQueryChanged extends CampusEvent {
  FacultyQueryChanged(this.query);
  final String query;
}

class CampusBloc extends Bloc<CampusEvent, CampusState> {
  CampusBloc(this.buses, this.faculty, {String? department})
    : super(CampusState(department: department)) {
    on<CampusStarted>((e, emit) async {
      try {
        final data = await Future.wait<Object>([
          buses.routes(),
          faculty.faculty(),
        ]);
        emit(
          state.copyWith(
            routes: data[0] as List<BusRoute>,
            faculty: data[1] as List<FacultyMember>,
            phase: LoadPhase.loaded,
          ),
        );
      } catch (_) {
        emit(state.copyWith(phase: LoadPhase.error));
      }
    });
    on<FacultyFilterChanged>(
      (e, emit) => emit(
        state.copyWith(
          department: e.department,
          clearDepartment: e.department == null,
        ),
      ),
    );
    on<FacultyQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    add(CampusStarted());
  }
  final BusRepository buses;
  final FacultyRepository faculty;
}
