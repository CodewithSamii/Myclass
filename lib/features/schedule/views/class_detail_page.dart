import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/format.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../campus/bloc/campus_bloc.dart';
import '../../campus/views/faculty_page.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../bloc/schedule_bloc.dart';
import 'routine_editor.dart';

class ClassDetailPage extends StatelessWidget {
  const ClassDetailPage({
    super.key,
    required this.sessionId,
    required this.day,
  });
  final String sessionId;
  final DateTime day;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ScheduleBloc>().state;
    final session = s.sessions.where((v) => v.id == sessionId).firstOrNull;
    if (session == null) {
      return const DetailPage(
        title: 'Class',
        child: EmptyState('Class not found.', 'The routine may have changed.'),
      );
    }
    final course = s.course(session.courseId);
    final faculty = context
        .watch<CampusBloc>()
        .state
        .faculty
        .where((f) => f.id == course.facultyId)
        .firstOrNull;
    final canManage = context
        .watch<ProfileBloc>()
        .state
        .profile
        .membership
        .canManage;
    return DetailPage(
      title: session.isLab ? 'Lab session' : 'Class',
      actions: [
        if (canManage)
          IconButton(
            tooltip: 'Edit repeating class',
            onPressed: () =>
                openSheet(context, RoutineEditor(session: session)),
            icon: const Icon(CupertinoIcons.pencil, size: 20),
          ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Badge(course.code ?? 'Course'),
          const SizedBox(height: 20),
          Text(course.name, style: context.type.headlineLarge),
          const SizedBox(height: 24),
          Surface(
            child: Column(
              children: [
                SettingsRow(
                  Fmt.fullDate(day),
                  icon: CupertinoIcons.calendar,
                  trailing: const SizedBox(),
                ),
                SettingsRow(
                  '${Fmt.minute(session.startMinute)} – ${Fmt.minute(session.endMinute)}',
                  icon: CupertinoIcons.clock,
                  trailing: const SizedBox(),
                ),
                SettingsRow(
                  session.room == null
                      ? 'Room to be announced'
                      : 'Room ${session.room}',
                  icon: CupertinoIcons.location,
                  trailing: const SizedBox(),
                ),
              ],
            ),
          ),
          if (session.cancelled) ...[
            const SizedBox(height: 16),
            const ErrorNotice(
              'This class is cancelled in the current routine.',
            ),
          ],
          if (session.changed) ...[
            const SizedBox(height: 16),
            Badge(
              'Routine updated',
              color: context.colors.sage,
              background: context.colors.sageBg,
            ),
          ],
          if (faculty != null) ...[
            const SectionHeader('Course faculty'),
            SettingsRow(
              faculty.name,
              subtitle: faculty.designation,
              icon: CupertinoIcons.person,
              onTap: () =>
                  openPage(context, FacultyProfilePage(member: faculty)),
            ),
          ],
          const SectionHeader('Class reminder'),
          Text(
            '${Fmt.offsets(context.watch<ProfileBloc>().state.profile.reminders.classOffsets)} before class',
            style: context.type.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Change your class reminders in Profile → Notifications.',
            style: context.type.bodyMedium?.copyWith(
              color: context.colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
