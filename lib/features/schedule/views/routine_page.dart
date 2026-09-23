import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/format.dart';
import '../../../core/clock.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../bloc/schedule_bloc.dart';
import 'class_detail_page.dart';
import 'routine_editor.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});
  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ScheduleBloc>().state;
    final day = selected ?? s.now.weekday;
    final classes = s.sessions.where((v) => v.weekday == day).toList()
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    final canManage = context
        .watch<ProfileBloc>()
        .state
        .profile
        .membership
        .canManage;
    return DetailPage(
      title: 'Class routine',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('The shape of your week.', style: context.type.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Your repeating classes. Assessments and one-off updates live in Schedule.',
            style: context.type.bodyMedium?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final i in [7, 1, 2, 3, 4, 5, 6])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(Fmt.days[i - 1].substring(0, 3)),
                      selected: day == i,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => selected = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (classes.isEmpty)
            const EmptyState(
              'No regular classes.',
              'A little room in the week.',
            )
          else
            for (var i = 0; i < classes.length; i++) ...[
              if (i > 0 &&
                  classes[i].startMinute - classes[i - 1].endMinute > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      '${classes[i].startMinute - classes[i - 1].endMinute} min break',
                      style: context.type.bodySmall?.copyWith(
                        color: context.colors.faint,
                      ),
                    ),
                  ),
                ),
              Surface(
                onTap: () => openPage(
                  context,
                  ClassDetailPage(
                    sessionId: classes[i].id,
                    day: weekStart(s.now).add(Duration(days: day % 7)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Label(
                            '${Fmt.minute(classes[i].startMinute)} – ${Fmt.minute(classes[i].endMinute)}',
                          ),
                        ),
                        if (canManage)
                          IconButton(
                            tooltip: 'Edit routine',
                            onPressed: () => openSheet(
                              context,
                              RoutineEditor(session: classes[i]),
                            ),
                            icon: const Icon(CupertinoIcons.pencil, size: 17),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.course(classes[i].courseId).name,
                      style: context.type.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          classes[i].room == null
                              ? 'Room TBA'
                              : 'Room ${classes[i].room}',
                          style: context.type.bodyMedium?.copyWith(
                            color: context.colors.secondary,
                          ),
                        ),
                        if (classes[i].isLab) const Badge('Lab'),
                        if (classes[i].cancelled)
                          Badge(
                            'Cancelled',
                            color: context.colors.red,
                            background: context.colors.redBg,
                          ),
                        if (classes[i].changed) const Badge('Updated'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
