import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/clock_cubit.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../shared/widgets/academic_tiles.dart';
import '../../events/bloc/events_bloc.dart';
import '../../events/views/event_detail_page.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../notes/views/notes_page.dart';
import '../bloc/tasks_bloc.dart';
import '../models/task_projection.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<TasksBloc>().state;
    final events = context.watch<EventsBloc>().state.items;
    final schedule = context.watch<ScheduleBloc>().state;
    final now = context.watch<ClockCubit>().state;
    final groups = TaskProjection.groups(events, s, schedule.courses, now);
    final bloc = context.read<TasksBloc>();
    return ListView(
      key: const PageStorageKey('tasks'),
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          'Your workload',
          eyebrow: 'One thing at a time',
          subtitle:
              '${groups.values.fold<int>(0, (n, l) => n + l.length)} ${s.showCompleted ? 'completed' : 'academic items'} · Prepared, not overwhelmed',
          actions: [
            IconButton(
              tooltip: 'Personal notes',
              onPressed: () => openPage(context, const NotesPage()),
              icon: const Icon(CupertinoIcons.square_pencil, size: 22),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              for (final type in <AcademicEventType?>[
                null,
                AcademicEventType.assignment,
                AcademicEventType.viva,
                AcademicEventType.presentation,
                AcademicEventType.quiz,
                AcademicEventType.exam,
                AcademicEventType.general,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(
                      type == null
                          ? 'All'
                          : type == AcademicEventType.general
                          ? 'Other'
                          : type.label,
                    ),
                    selected: s.filter == type,
                    showCheckmark: false,
                    backgroundColor: context.colors.canvas,
                    selectedColor: context.colors.ink,
                    labelStyle: context.type.bodyMedium?.copyWith(
                      color: s.filter == type
                          ? context.colors.canvas
                          : context.colors.secondary,
                    ),
                    side: BorderSide(
                      color: s.filter == type
                          ? context.colors.ink
                          : context.colors.line,
                    ),
                    onSelected: (_) => bloc.add(TaskFilterChanged(type)),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  PopupMenuButton<TaskGrouping>(
                    tooltip: 'Group academic work',
                    initialValue: s.grouping,
                    onSelected: (v) => bloc.add(TaskGroupingChanged(v)),
                    itemBuilder: (_) => TaskGrouping.values
                        .map(
                          (g) => PopupMenuItem(
                            value: g,
                            child: Text('Group by ${g.name}'),
                          ),
                        )
                        .toList(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.line_horizontal_3_decrease,
                            size: 16,
                            color: context.colors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'By ${s.grouping.name}',
                            style: context.type.bodySmall?.copyWith(
                              color: context.colors.secondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            CupertinoIcons.chevron_down,
                            size: 10,
                            color: context.colors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        bloc.add(CompletedVisibilityChanged(!s.showCompleted)),
                    child: Text(
                      s.showCompleted ? 'Show remaining' : 'Completed',
                    ),
                  ),
                ],
              ),
              if (s.error != null) ...[
                ErrorNotice(s.error!),
                const SizedBox(height: 12),
              ],
              if (groups.isEmpty)
                EmptyState(
                  s.showCompleted
                      ? 'Nothing marked done yet.'
                      : 'Nothing here to prepare.',
                  'Try another filter, or enjoy the breathing room.',
                  icon: CupertinoIcons.checkmark_circle,
                )
              else
                for (final group in groups.entries) ...[
                  SectionHeader(
                    group.key,
                    trailing: Text(
                      '${group.value.length}',
                      style: context.type.bodySmall?.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
                  ),
                  for (final e in group.value) ...[
                    AcademicEventTile(
                      event: e,
                      course: schedule.course(e.courseId),
                      now: now,
                      completed:
                          s.forEvent(e.id).completed ||
                          e.status == EventStatus.completed,
                      onComplete: e.status == EventStatus.completed
                          ? null
                          : () => bloc.add(TaskToggled(e.id)),
                      onTap: () => openPage(context, EventDetailPage(id: e.id)),
                    ),
                    const Divider(),
                  ],
                ],
              const SizedBox(height: 24),
              Text(
                'Checking an item only updates your personal progress.',
                style: context.type.bodySmall?.copyWith(
                  color: context.colors.faint,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
