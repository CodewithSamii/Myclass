import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../core/clock_cubit.dart';
import '../../../shared/widgets/primitives.dart';
import '../../events/bloc/events_bloc.dart';
import '../../events/views/event_detail_page.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../schedule/views/class_detail_page.dart';
import '../../tasks/bloc/tasks_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../search/views/search_page.dart';
import '../../notes/views/notes_page.dart';
import '../models/agenda_projection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onSchedule});
  final VoidCallback onSchedule;
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileBloc>().state.profile;
    final isGuest = profile.uid == 'guest';

    final child = isGuest
        ? _buildLoggedOutHome(context)
        : _buildLoggedInHome(context, profile);

    return Material(
      type: MaterialType.transparency,
      child: child,
    );
  }

  Widget _buildLoggedOutHome(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          'MyClass',
          eyebrow: 'Metropolitan University',
          subtitle: 'Welcome. Select or join your classroom to access routines, schedules, and notices.',
          actions: [
            IconButton(
              tooltip: 'Search everything',
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
                color: c.sageBg,
                border: false,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.person_2_fill, color: c.sage, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Join or Create Classroom',
                          style: context.type.titleMedium?.copyWith(
                            color: c.sage,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Select your department, batch, and section to access your personalized classroom schedule, or request a new section as an Admin.',
                      style: context.type.bodyMedium?.copyWith(
                        color: c.ink,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onSchedule,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.sage,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Enter Classroom / Join', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Explore MyClass',
                style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Surface(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.subtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(CupertinoIcons.calendar, color: c.ink, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Schedules & Routine',
                            style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Universal time periods and 7-day routine matrices customized for each university batch.',
                            style: context.type.bodySmall?.copyWith(color: c.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Surface(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.subtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(CupertinoIcons.checkmark_circle, color: c.ink, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assignments & Tasks',
                            style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Track academic deadlines, submissions, and reminders with personal completion status.',
                            style: context.type.bodySmall?.copyWith(color: c.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Surface(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.subtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(CupertinoIcons.bus, color: c.ink, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campus Services & Faculty',
                            style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Browse university bus routes, timetables, and find faculty contacts effortlessly.',
                            style: context.type.bodySmall?.copyWith(color: c.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInHome(BuildContext context, UserProfile profile) {
    final es = context.watch<EventsBloc>().state;
    final ss = context.watch<ScheduleBloc>().state;
    final ps = context.watch<TasksBloc>().state;
    final now = context.watch<ClockCubit>().state;
    final unknown = ss.phase == LoadPhase.notFound;
    final today = AgendaProjection.day(
      day: now,
      sessions: ss.sessions,
      events: es.items,
      courses: ss.courses,
      periods: ss.periods,
      omitRoutine: unknown,
    );
    final tomorrow = AgendaProjection.day(
      day: now.add(const Duration(days: 1)),
      sessions: ss.sessions,
      events: es.items,
      courses: ss.courses,
      periods: ss.periods,
    );
    final model = HomeProjection(
      now: now,
      today: today,
      tomorrow: tomorrow,
      events: es.items,
      progress: ps.progress,
    );
    final upcomingEvents = es.items
        .where((e) => e.status != EventStatus.cancelled)
        .toList()
      ..sort((a, b) => a.effectiveAt.compareTo(b.effectiveAt));
    final content = <Widget>[
      PageHeader(
        '${Fmt.weekday(now)}, ${now.day}',
        eyebrow:
            '${profile.membership.batchName} · ${profile.membership.sectionName}',
        subtitle: '${Fmt.month(now)} ${now.year} · Your day, in focus',
        actions: [
          IconButton(
            tooltip: 'Search everything',
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
            if (es.offline || es.stale) ...[

              Surface(
                color: context.colors.subtle,
                border: false,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      es.offline
                          ? CupertinoIcons.wifi_slash
                          : CupertinoIcons.clock,
                      size: 16,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        es.offline
                            ? 'Offline · Showing saved schedule'
                            : 'Showing saved schedule · Last updated ${es.updatedAt == null ? 'recently' : Fmt.time(es.updatedAt!)}',
                        style: context.type.bodySmall?.copyWith(
                          color: context.colors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (es.error != null) ...[
              ErrorNotice(
                es.error!,
                onRetry: () => context.read<EventsBloc>().add(EventsRefresh()),
              ),
              const SizedBox(height: 16),
            ],
            if (ss.phase == LoadPhase.loading)
              const Skeleton(rows: 3)
            else
              _FocusCard(model: model, onTap: () => _openFocus(context, model)),

            if (unknown) ...[
              const SizedBox(height: 14),
              const ErrorNotice(
                'The class routine is not available yet. Academic events are still shown.',
              ),
            ],

            const SizedBox(height: 24),
            SectionHeader(
              'Upcoming Events',
              trailing: Text(
                '${upcomingEvents.length} events',
                style: context.type.bodySmall?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _UpcomingEventsTable(
              events: upcomingEvents,
              now: now,
              onTapEvent: (e) => openPage(context, EventDetailPage(id: e.id)),
            ),

            const SizedBox(height: 24),
            SettingsRow(
              'A thought for later',
              subtitle: 'Add a private note or reminder',
              icon: CupertinoIcons.square_pencil,
              onTap: () => openPage(context, const NotesPage()),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ];
    return RefreshIndicator(
      onRefresh: () async {
        context.read<EventsBloc>().add(EventsRefresh());
      },
      color: context.colors.ink,
      child: ListView(
        key: const PageStorageKey('home'),
        padding: EdgeInsets.zero,
        children: content,
      ),
    );
  }

  void _openFocus(BuildContext context, HomeProjection p) {
    if (p.current != null) {
      openAgenda(context, p.current!);
    } else if (p.next != null) {
      openAgenda(context, p.next!);
    } else if (p.dueToday.isNotEmpty) {
      openPage(context, EventDetailPage(id: p.dueToday.first.id));
    } else if (p.prepareFor != null) {
      openPage(context, EventDetailPage(id: p.prepareFor!.id));
    }
  }
}

void openAgenda(BuildContext context, AgendaEntry entry) => openPage(
  context,
  entry.event != null
      ? EventDetailPage(id: entry.event!.id)
      : ClassDetailPage(sessionId: entry.session!.id, day: entry.day),
);

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.model, required this.onTap});
  final HomeProjection model;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = model.current ?? model.next;
    final task = model.dueToday.firstOrNull ?? model.prepareFor;
    final title = e?.title ?? task?.title ?? model.quietTitle;
    final current = model.current != null;
    return Surface(
      color: c.hero,
      border: false,
      radius: Shape.large,
      padding: const EdgeInsets.all(22),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: c.heroMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(child: Label(model.headline, color: c.heroMuted)),
              if (e != null)
                Text(
                  current
                      ? '${(e.end ?? model.now).difference(model.now).inMinutes} min left'
                      : Fmt.until(e.at, model.now),
                  style: context.type.bodySmall?.copyWith(color: c.heroMuted),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: context.type.headlineMedium?.copyWith(color: c.onHero),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (e != null)
            Wrap(
              spacing: 16,
              runSpacing: 7,
              children: [
                _meta(
                  context,
                  CupertinoIcons.clock,
                  '${Fmt.time(e.at, suffix: false)}–${Fmt.time(e.end ?? e.at)}',
                ),
                _meta(
                  context,
                  CupertinoIcons.location,
                  e.location.startsWith('Room')
                      ? e.location
                      : 'Room ${e.location}',
                ),
              ],
            )
          else
            Text(
              task != null
                  ? '${task.deadline != null ? 'Due' : 'Scheduled'} ${Fmt.relativeDay(task.date, model.now).toLowerCase()} · ${Fmt.time(task.effectiveAt)}'
                  : 'Your next classes and deadlines will appear here.',
              style: context.type.bodyMedium?.copyWith(color: c.heroMuted),
            ),
          if (current && model.next != null) ...[
            const SizedBox(height: 22),
            Divider(color: c.heroMuted.withValues(alpha: .25)),
            const SizedBox(height: 16),
            Row(
              children: [
                Label('Next', color: c.heroMuted),
                const Spacer(),
                Text(
                  Fmt.time(model.next!.at),
                  style: context.type.bodySmall?.copyWith(color: c.heroMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              model.next!.course.compactName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.type.titleSmall?.copyWith(color: c.onHero),
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: context.colors.heroMuted),
      const SizedBox(width: 6),
      Text(
        text,
        style: context.type.bodyMedium?.copyWith(
          color: context.colors.heroMuted,
        ),
      ),
    ],
  );
}

/// 2-Column Upcoming Events Table
/// Left column: Date & Time (Grouped under same date if multiple events on one day)
/// Right column: Event title & details
class _UpcomingEventsTable extends StatelessWidget {
  const _UpcomingEventsTable({
    required this.events,
    required this.now,
    required this.onTapEvent,
  });

  final List<AcademicEvent> events;
  final DateTime now;
  final ValueChanged<AcademicEvent> onTapEvent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: Column(
          children: [
            Icon(CupertinoIcons.calendar_badge_plus, size: 36, color: c.faint),
            const SizedBox(height: 10),
            Text(
              'No Upcoming Events',
              style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Academic exams, assignments, and quizzes will appear here.',
              textAlign: TextAlign.center,
              style: context.type.bodySmall?.copyWith(color: c.secondary),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.subtle,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 105,
                  child: Text(
                    'DATE & TIME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: c.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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

          // Event rows with same-day grouping
          for (var i = 0; i < events.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            _UpcomingEventRow(
              event: events[i],
              isFirstOfDay: i == 0 || !sameDay(events[i].effectiveAt, events[i - 1].effectiveAt),
              now: now,
              onTap: () => onTapEvent(events[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpcomingEventRow extends StatelessWidget {
  const _UpcomingEventRow({
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
    final timeStr = Fmt.time(event.effectiveAt);
    final dateStr = Fmt.date(event.effectiveAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column: Date & Time
            SizedBox(
              width: 105,
              child: isFirstOfDay
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: c.secondary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '—',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.faint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: c.secondary,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(width: 12),

            // Right Column: Event
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isMajorAssessment ? FontWeight.w700 : FontWeight.w600,
                      color: isMajorAssessment ? const Color(0xFFD32F2F) : c.ink,
                      decoration: isMajorAssessment ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: const Color(0xFFD32F2F),
                      decorationThickness: 1.5,
                    ),
                  ),
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      event.location!.startsWith('Room') ||
                              event.location!.startsWith('ACL') ||
                              event.location!.startsWith('RKB')
                          ? event.location!
                          : 'Room ${event.location}',
                      style: TextStyle(
                        fontSize: 12,
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
