import '../../../core/models.dart';
import '../../../core/clock.dart';
import '../bloc/tasks_bloc.dart';

abstract final class TaskProjection {
  static Map<String, List<AcademicEvent>> groups(
    List<AcademicEvent> events,
    TasksState state,
    List<Course> courses,
    DateTime now,
  ) {
    final visible =
        events
            .where(
              (e) =>
                  e.status != EventStatus.cancelled &&
                  (state.filter == null ||
                      e.type == state.filter ||
                      (state.filter == AcademicEventType.general &&
                          ![
                            AcademicEventType.assignment,
                            AcademicEventType.viva,
                            AcademicEventType.presentation,
                            AcademicEventType.quiz,
                            AcademicEventType.exam,
                          ].contains(e.type))) &&
                  (state.showCompleted
                      ? state.forEvent(e.id).completed ||
                            e.status == EventStatus.completed
                      : !state.forEvent(e.id).completed &&
                            e.status != EventStatus.completed),
            )
            .toList()
          ..sort((a, b) => a.effectiveAt.compareTo(b.effectiveAt));
    final result = <String, List<AcademicEvent>>{};
    for (final e in visible) {
      final String label;
      switch (state.grouping) {
        case TaskGrouping.course:
          label =
              courses
                  .where((c) => c.id == e.courseId)
                  .firstOrNull
                  ?.compactName ??
              'Other courses';
        case TaskGrouping.type:
          label = e.type.label;
        case TaskGrouping.date:
          final delta = dateOnly(e.date).difference(dateOnly(now)).inDays;
          label = e.passed(now)
              ? 'Needs attention'
              : delta <= 1
              ? 'Due soon'
              : delta <= 7
              ? 'Upcoming'
              : 'Later';
      }
      result.putIfAbsent(label, () => []).add(e);
    }
    return result;
  }
}
