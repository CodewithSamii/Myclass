import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../core/clock_cubit.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../bloc/events_bloc.dart';
import 'event_detail_page.dart';

class UpcomingEventsPage extends StatelessWidget {
  const UpcomingEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final es = context.watch<EventsBloc>().state;
    final profile = context.watch<ProfileBloc>().state.profile;
    final now = context.watch<ClockCubit>().state;

    final upcomingEvents = es.items
        .where((e) => e.status != EventStatus.cancelled)
        .toList()
      ..sort((a, b) => a.effectiveAt.compareTo(b.effectiveAt));

    return DetailPage(
      title: 'Upcoming Events',
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<EventsBloc>().add(EventsRefresh());
        },
        color: c.ink,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label('${profile.membership.batchName} · ${profile.membership.sectionName}'),
                  const SizedBox(height: 4),
                  Text(
                    'All upcoming exams, assignments, quizzes & academic notices',
                    style: context.type.bodyMedium?.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (upcomingEvents.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  children: [
                    Icon(CupertinoIcons.calendar_badge_plus, size: 40, color: c.faint),
                    const SizedBox(height: 12),
                    Text(
                      'No Upcoming Events',
                      style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Academic deadlines, presentations, and exams will be listed here.',
                      textAlign: TextAlign.center,
                      style: context.type.bodySmall?.copyWith(color: c.secondary),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  children: [
                    // 3-Column Table Header: DATE | TIME | EVENT
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.subtle,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 62,
                            child: Text(
                              'DATE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: c.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: Text(
                              'TIME',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: c.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'EVENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: c.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Event Rows with Same-Day Date Grouping
                    for (var i = 0; i < upcomingEvents.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.line),
                      _ThreeColumnEventRow(
                        event: upcomingEvents[i],
                        isFirstOfDay: i == 0 ||
                            !sameDay(
                              upcomingEvents[i].effectiveAt,
                              upcomingEvents[i - 1].effectiveAt,
                            ),
                        now: now,
                        onTap: () => openPage(
                          context,
                          EventDetailPage(id: upcomingEvents[i].id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ThreeColumnEventRow extends StatelessWidget {
  const _ThreeColumnEventRow({
    required this.event,
    required this.isFirstOfDay,
    required this.now,
    required this.onTap,
  });

  final AcademicEvent event;
  final bool isFirstOfDay;
  final DateTime now;
  final VoidCallback onTap;

  bool get isMajorAssessment {
    final t = event.type;
    return t == AcademicEventType.classTest ||
        t == AcademicEventType.presentation ||
        t == AcademicEventType.viva ||
        t == AcademicEventType.exam ||
        t == AcademicEventType.labExam ||
        t == AcademicEventType.quiz ||
        t == AcademicEventType.assignment;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isTba = event.startsAt == null && event.deadline == null;
    final timeStr = isTba ? 'TBA' : Fmt.time(event.effectiveAt);
    final dateStr = Fmt.date(event.effectiveAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Column 1: Date (Only Date)
            SizedBox(
              width: 62,
              child: Text(
                isFirstOfDay ? dateStr : '—',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isFirstOfDay ? c.ink : c.faint,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Column 2: Time (Only Time)
            SizedBox(
              width: 72,
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.secondary,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Column 3: Event
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isMajorAssessment ? FontWeight.w700 : FontWeight.w600,
                      color: isMajorAssessment ? const Color(0xFFD32F2F) : c.ink,
                      decoration: isMajorAssessment ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: const Color(0xFFD32F2F),
                      decorationThickness: 1.5,
                    ),
                  ),
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.location!.startsWith('Room') ||
                              event.location!.startsWith('ACL') ||
                              event.location!.startsWith('RKB')
                          ? event.location!
                          : 'Room ${event.location}',
                      style: TextStyle(
                        fontSize: 11,
                        color: c.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: c.faint,
            ),
          ],
        ),
      ),
    );
  }
}
