import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/format.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../campus/bloc/campus_bloc.dart';
import '../../campus/views/faculty_page.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../bloc/schedule_bloc.dart';

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
    final exactSession = s.sessions.where((v) => v.id == sessionId).firstOrNull;
    final overrideId = '${sessionId.split('-override-').first}-override-${day.year}-${day.month}-${day.day}';
    final overrideSession = s.sessions.where((v) => v.id == overrideId).firstOrNull;
    final session = overrideSession ??
        exactSession ??
        s.sessions.where((v) => v.id == sessionId.split('-override-').first).firstOrNull;

    if (session == null) {
      return const DetailPage(
        title: 'Class',
        child: EmptyState('Class not found.', 'The routine may have changed.'),
      );
    }

    final course = s.course(session.courseId);
    final courseName = session.customCourseName?.isNotEmpty == true
        ? session.customCourseName!
        : course.name;

    final faculty = context
        .watch<CampusBloc>()
        .state
        .faculty
        .where((f) => f.id == course.facultyId)
        .firstOrNull;


    return DetailPage(
      title: session.isTemporary
          ? 'Temporary Class'
          : (session.isLab ? 'Lab session' : 'Class'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (session.isTemporary)
                Badge(
                  'TEMPORARY CLASS',
                  color: context.colors.amber,
                  background: context.colors.amberBg,
                )
              else if (session.isShifted)
                Badge(
                  'SHIFTED CLASS',
                  color: context.colors.sage,
                  background: context.colors.sageBg,
                )
              else
                Badge(course.code ?? 'Course'),
              if (session.isOnline)
                Badge(
                  'ONLINE',
                  color: context.colors.ink,
                  background: context.colors.subtle,
                ),
              if (session.cancelled)
                Badge(
                  'CANCELLED',
                  color: context.colors.red,
                  background: context.colors.redBg,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            courseName,
            style: context.type.headlineLarge?.copyWith(
              decoration: session.cancelled ? TextDecoration.lineThrough : null,
              color: session.cancelled ? context.colors.faint : null,
            ),
          ),
          const SizedBox(height: 20),

          if (session.cancelled) ...[
            Surface(
              color: context.colors.redBg,
              border: false,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(CupertinoIcons.clear_circled_solid, color: context.colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This class is cancelled on ${Fmt.fullDate(day)}.',
                      style: TextStyle(
                        color: context.colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (session.isShifted) ...[
            Surface(
              color: context.colors.sageBg,
              border: false,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(CupertinoIcons.arrow_right_arrow_left, color: context.colors.sage, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      session.notes?.isNotEmpty == true
                          ? session.notes!
                          : 'Shifted from ${session.originalTimeLabel ?? (session.originalDate != null ? Fmt.fullDate(session.originalDate!) : "original routine")}',
                      style: TextStyle(
                        color: context.colors.sage,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                if (session.isOnline)
                  SettingsRow(
                    session.meetingLink != null && session.meetingLink!.isNotEmpty
                        ? session.meetingLink!
                        : 'Online meeting',
                    subtitle: 'Online Class Link',
                    icon: CupertinoIcons.videocam,
                    trailing: const SizedBox(),
                  )
                else
                  SettingsRow(
                    session.room == null || session.room!.isEmpty
                        ? 'Room to be announced'
                        : 'Room ${session.room}',
                    icon: CupertinoIcons.location,
                    trailing: const SizedBox(),
                  ),
              ],
            ),
          ),

          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SectionHeader('Instructions & Notes'),
            Surface(
              padding: const EdgeInsets.all(16),
              child: Text(
                session.notes!,
                style: context.type.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ],

          if (session.facultyName != null && session.facultyName!.isNotEmpty) ...[
            const SectionHeader('Course faculty'),
            SettingsRow(
              session.facultyName!,
              icon: CupertinoIcons.person,
              trailing: const SizedBox(),
            ),
          ] else if (faculty != null) ...[
            const SectionHeader('Course faculty'),
            SettingsRow(
              faculty.name,
              subtitle: faculty.designation,
              icon: CupertinoIcons.person,
              onTap: () => openPage(context, FacultyProfilePage(member: faculty)),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
