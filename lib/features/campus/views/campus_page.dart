import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/format.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../search/views/search_page.dart';
import '../bloc/campus_bloc.dart';
import 'bus_page.dart';
import 'faculty_page.dart';

class CampusPage extends StatelessWidget {
  const CampusPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<CampusBloc>().state;
    final periods = context.watch<ScheduleBloc>().state.periods;
    final department = context
        .watch<ProfileBloc>()
        .state
        .profile
        .membership
        .departmentId;
    return ListView(
      key: const PageStorageKey('campus'),
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          'Around campus',
          eyebrow: 'Metropolitan University',
          subtitle: 'The useful things, close at hand.',
          actions: [
            IconButton(
              tooltip: 'Search campus',
              onPressed: () => openPage(context, const SearchPage()),
              icon: const Icon(CupertinoIcons.search, size: 22),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Surface(
                padding: const EdgeInsets.all(22),
                onTap: () => openPage(context, const BusPage()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.bus,
                          size: 26,
                          color: context.colors.ink,
                        ),
                        const Spacer(),
                        const Badge('4 routes'),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'A simpler way there.',
                      style: context.type.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find your route, your stop and your ride home.',
                      style: context.type.bodyMedium?.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text('University bus', style: context.type.titleSmall),
                        const Spacer(),
                        const Icon(CupertinoIcons.arrow_up_right, size: 19),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Surface(
                onTap: () => openPage(context, const FacultyPage()),
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_2,
                      size: 25,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faculty directory',
                            style: context.type.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A name, a room, a way to reach out.',
                            style: context.type.bodyMedium?.copyWith(
                              color: context.colors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(CupertinoIcons.chevron_right, size: 14),
                  ],
                ),
              ),
              SectionHeader(
                'People in your department',
                action: 'View all',
                onAction: () => openPage(context, const FacultyPage()),
              ),
              if (s.phase == LoadPhase.loading)
                const Skeleton(rows: 3)
              else if (s.phase == LoadPhase.error)
                ErrorNotice(
                  'Campus information could not be loaded.',
                  onRetry: () =>
                      context.read<CampusBloc>().add(CampusStarted()),
                )
              else
                for (final member
                    in s.faculty
                        .where(
                          (f) =>
                              department.isEmpty ||
                              f.departmentId == department,
                        )
                        .take(3))
                  FacultyRow(member: member),
              const SectionHeader('Academic calendar'),
              for (final period in periods.where(
                (p) => p.end.difference(p.start).inDays > 0,
              ))
                SettingsRow(
                  period.title,
                  subtitle:
                      '${Fmt.date(period.start)} – ${Fmt.date(period.end)} · ${period.start.year}',
                  icon: CupertinoIcons.calendar,
                  onTap: () => openSheet(
                    context,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(period.title, style: context.type.headlineSmall),
                          const SizedBox(height: 16),
                          Text(
                            '${Fmt.fullDate(period.start)} to ${Fmt.fullDate(period.end)}',
                            style: context.type.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            period.classesSuspended
                                ? 'Regular classes are suspended during this period. Individually scheduled academic events remain visible.'
                                : 'Check your section schedule for individual assessments and any class changes.',
                            style: context.type.bodyMedium?.copyWith(
                              color: context.colors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Campus information in this preview is fictional.',
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
