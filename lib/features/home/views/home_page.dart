import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../core/clock_cubit.dart';
import '../../../shared/widgets/primitives.dart';
import '../../events/bloc/events_bloc.dart';
import '../../events/views/event_detail_page.dart';
import '../../events/views/upcoming_events_page.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../schedule/views/class_detail_page.dart';
import '../../tasks/bloc/tasks_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../search/views/search_page.dart';
import '../../notes/bloc/notes_bloc.dart';
import '../../notes/views/notes_page.dart';
import '../../notes/views/note_editor.dart';
import '../../section_admin/views/event_editor_page.dart';
import '../../section_admin/views/set_slots_page.dart';
import '../../section_admin/views/set_routine_page.dart';
import '../../schedule/views/temporary_class_sheet.dart';
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
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'MyClass v1.0.0 · © 2026 Saminul Islam Sami · All Rights Reserved',
                  textAlign: TextAlign.center,
                  style: context.type.bodySmall?.copyWith(
                    color: c.faint,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 24),
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

    final selectedEntries = AgendaProjection.day(
      day: ss.selected,
      sessions: ss.sessions,
      events: es.items,
      courses: ss.courses,
      periods: ss.periods,
      omitRoutine: unknown,
    );
    final conflicts = AgendaProjection.conflicts(selectedEntries);

    final notes = context
        .watch<NotesBloc>()
        .state
        .items
        .where(
          (n) =>
              n.remindAt != null &&
              sameDay(n.remindAt!, ss.selected) &&
              !n.completed,
        )
        .toList();

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
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              const SizedBox(height: 12),
            ],
            if (es.error != null) ...[
              ErrorNotice(
                es.error!,
                onRetry: () => context.read<EventsBloc>().add(EventsRefresh()),
              ),
              const SizedBox(height: 12),
            ],

            // 1. Happening Now (Compact Focus Card)
            if (ss.phase == LoadPhase.loading)
              const Skeleton(rows: 2)
            else
              _FocusCard(model: model, onTap: () => _openFocus(context, model)),

            const SizedBox(height: 10),

            // 2. Upcoming Events (Compact 1-Row Preview)
            _UpcomingEventsPreview(
              events: upcomingEvents,
              now: now,
              onTap: () => openPage(context, const UpcomingEventsPage()),
            ),

            const SizedBox(height: 20),

            // 3. Existing Schedule / Routine Section
            _ChocolateBlockDateBar(
              selected: ss.selected,
              now: ss.now,
              onDateSelected: (d) =>
                  context.read<ScheduleBloc>().add(ScheduleDateSelected(d)),
            ),

            const SizedBox(height: 14),

            // Calendar Selected Date Header & Jump to Today
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sameDay(ss.selected, ss.now) ? 'Today' : Fmt.fullDate(ss.selected),
                  style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context
                      .read<ScheduleBloc>()
                      .add(ScheduleDateSelected(dateOnly(ss.now))),
                  child: const Text('Jump to Today'),
                ),
              ],
            ),
            if (profile.membership.canManage || profile.membership.isOwner) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => openSheet(
                      context,
                      TemporaryClassSheet(initialDate: ss.selected),
                    ),
                    icon: const Icon(CupertinoIcons.calendar_badge_plus, size: 14),
                    label: const Text('+ Temp Class'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () {
                      final daySessions = ss.sessions.where((s) => s.weekday == ss.selected.weekday).toList();
                      if (daySessions.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No routine classes scheduled for ${Fmt.weekday(ss.selected)}. Events can only be assigned to existing routine classes.'),
                            backgroundColor: context.colors.amber,
                          ),
                        );
                      } else {
                        openPage(
                          context,
                          EventEditorPage(initialDate: ss.selected),
                        );
                      }
                    },
                    icon: const Icon(CupertinoIcons.plus_circle, size: 14),
                    label: const Text('Add Event'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ],
              ),
            ],

            if (conflicts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Surface(
                color: context.colors.amberBg,
                border: false,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 16,
                      color: context.colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${conflicts.length} items overlap. Check latest updates.',
                        style: context.type.bodySmall?.copyWith(color: context.colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (unknown) ...[
              const SizedBox(height: 10),
              const ErrorNotice(
                'The class routine is not available yet. Academic events are still shown.',
              ),
            ],

            const SizedBox(height: 10),

            // 2-Column Schedule Table
            _TwoColumnScheduleTable(
              entries: selectedEntries,
              timeSlots: ss.timeSlots,
              now: ss.now,
              canManage: profile.membership.canManage || profile.membership.isOwner,
              onTapEntry: (entry) {
                if (entry.event != null) {
                  openPage(context, EventDetailPage(id: entry.event!.id));
                } else if (entry.session != null) {
                  openPage(
                    context,
                    ClassDetailPage(sessionId: entry.session!.id, day: entry.day),
                  );
                }
              },
            ),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionHeader('Your reminders'),
              for (final note in notes)
                SettingsRow(
                  note.text,
                  subtitle: 'Private · ${Fmt.time(note.remindAt!)}',
                  icon: CupertinoIcons.bell,
                  onTap: () => openSheet(context, NoteEditor(note: note)),
                ),
            ],

            const SizedBox(height: 24),

            if (profile.membership.canManage) ...[
              const SectionHeader('Admin Shortcuts'),
              SettingsRow(
                'Set Universal Time Slots',
                subtitle: 'Define standard periods (e.g. 9:00–10:05, 10:05–11:10)',
                icon: CupertinoIcons.clock,
                onTap: () => openPage(context, const SetSlotsPage()),
              ),
              SettingsRow(
                'Set Weekly Routine',
                subtitle: 'Assign subjects across Saturday–Friday for this section',
                icon: CupertinoIcons.calendar,
                onTap: () => openPage(context, const SetRoutinePage()),
              ),
            ],

            const SizedBox(height: 20),
            SettingsRow(
              'A thought for later',
              subtitle: 'Add a private note or reminder',
              icon: CupertinoIcons.square_pencil,
              onTap: () => openPage(context, const NotesPage()),
            ),
            const SizedBox(height: 32),
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
  entry.events.isNotEmpty
      ? EventDetailPage(id: entry.events.first.id)
      : (entry.event != null
          ? EventDetailPage(id: entry.event!.id)
          : ClassDetailPage(sessionId: entry.session!.id, day: entry.day)),
);

/// Compact Focus Card ("Happening Now")
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Happening Now',
                  style: context.type.labelSmall?.copyWith(
                    color: c.heroMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (e != null)
                Text(
                  current
                      ? '${(e.end ?? model.now).difference(model.now).inMinutes} min left'
                      : Fmt.until(e.at, model.now),
                  style: context.type.bodySmall?.copyWith(color: c.heroMuted),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: context.type.titleMedium?.copyWith(
              color: c.onHero,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          if (e != null)
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _meta(
                  context,
                  CupertinoIcons.clock,
                  '${Fmt.time(e.at, suffix: false)}–${Fmt.time(e.end ?? e.at)}',
                ),
                _meta(
                  context,
                  CupertinoIcons.location,
                  e.location.startsWith('Room') ||
                          e.location.startsWith('ACL') ||
                          e.location.startsWith('RKB')
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
              style: context.type.bodySmall?.copyWith(color: c.heroMuted),
            ),
          if (current && model.next != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Label('Next', color: c.heroMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${model.next!.course.compactName} · ${Fmt.time(model.next!.at)}',
                    style: context.type.bodySmall?.copyWith(color: c.heroMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: context.colors.heroMuted),
      const SizedBox(width: 5),
      Text(
        text,
        style: context.type.bodySmall?.copyWith(
          color: context.colors.heroMuted,
        ),
      ),
    ],
  );
}

/// Compact 1-Row Preview of Upcoming Events
class _UpcomingEventsPreview extends StatelessWidget {
  const _UpcomingEventsPreview({
    required this.events,
    required this.now,
    required this.onTap,
  });

  final List<AcademicEvent> events;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final nextEvent = events.isNotEmpty ? events.first : null;

    return Surface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.subtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(CupertinoIcons.calendar, size: 16, color: c.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Upcoming Events',
                        style: context.type.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: c.subtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${events.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: c.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  nextEvent != null
                      ? '${Fmt.date(nextEvent.effectiveAt)}, ${(nextEvent.startsAt == null && nextEvent.deadline == null) ? "TBA" : Fmt.time(nextEvent.effectiveAt)} · ${nextEvent.title}'
                      : 'No upcoming events scheduled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.bodySmall?.copyWith(
                    color: c.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'View all',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          const SizedBox(width: 2),
          Icon(CupertinoIcons.chevron_right, size: 12, color: c.faint),
        ],
      ),
    );
  }
}

/// 2-Row "Chocolate Block" Date Bar
class _ChocolateBlockDateBar extends StatelessWidget {
  const _ChocolateBlockDateBar({
    required this.selected,
    required this.now,
    required this.onDateSelected,
  });

  final DateTime selected;
  final DateTime now;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    // 60-day horizontal date timeline covering ~2 full months
    final startDay = dateOnly(now).subtract(const Duration(days: 14));
    final days = List.generate(60, (i) => startDay.add(Duration(days: i)));

    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final day = days[i];
          final isSelected = sameDay(day, selected);
          final isToday = sameDay(day, now);

          const chocolateDark = Color(0xFF3E2723);
          const chocolateMedium = Color(0xFF4E342E);
          const chocolateCream = Color(0xFFFFF8E7);
          const chocolateSubtle = Color(0xFFEFEBE9);

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onDateSelected(day);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: Motion.fast,
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [chocolateMedium, chocolateDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF231D1B) : chocolateSubtle),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8D6E63)
                        : (isToday ? const Color(0xFF5D4037) : Colors.transparent),
                    width: isSelected ? 1.5 : (isToday ? 1.2 : 0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day} ${Fmt.month(day).substring(0, 3)}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? chocolateCream
                            : (isDark ? Colors.white : const Color(0xFF2E1C14)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Fmt.weekday(day),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? chocolateCream.withOpacity(0.85)
                            : (isDark ? Colors.grey[400] : const Color(0xFF6D4C41)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 2-Column Schedule Table Layout
class _TwoColumnScheduleTable extends StatelessWidget {
  const _TwoColumnScheduleTable({
    required this.entries,
    required this.timeSlots,
    required this.now,
    required this.onTapEntry,
    this.canManage = false,
  });

  final List<AgendaEntry> entries;
  final List<TimeSlot> timeSlots;
  final DateTime now;
  final ValueChanged<AgendaEntry> onTapEntry;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (entries.isEmpty) {
      if (canManage) {
        return Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              Icon(CupertinoIcons.square_stack_3d_up, size: 36, color: c.sage),
              const SizedBox(height: 10),
              Text(
                'Classroom Setup Needed',
                style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'This classroom is empty. Use the management shortcuts below to build time periods, weekly routine, or add events.',
                textAlign: TextAlign.center,
                style: context.type.bodySmall?.copyWith(color: c.secondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => openPage(context, const SetSlotsPage()),
                    icon: const Icon(CupertinoIcons.clock, size: 16),
                    label: const Text('Set Slots', style: TextStyle(fontSize: 12)),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => openPage(context, const SetRoutinePage()),
                    icon: const Icon(CupertinoIcons.calendar, size: 16),
                    label: const Text('Set Routine', style: TextStyle(fontSize: 12)),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => openPage(context, const EventEditorPage()),
                    icon: const Icon(CupertinoIcons.plus, size: 16),
                    label: const Text('Add Event', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(36),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: Column(
          children: [
            Icon(CupertinoIcons.moon_stars, size: 40, color: c.faint),
            const SizedBox(height: 12),
            Text(
              'No Classes or Events Scheduled',
              style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Your class routine will appear here once configured by your section admin.',
              textAlign: TextAlign.center,
              style: context.type.bodySmall?.copyWith(color: c.secondary),
            ),
          ],
        ),
      );
    }

    final allCancelled = entries.isNotEmpty && AgendaProjection.isAllCancelled(entries);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          if (allCancelled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              decoration: BoxDecoration(
                color: c.redBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.red.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.clear_circled_solid, color: c.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No classes today',
                          style: TextStyle(
                            color: c.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All classes scheduled for today have been cancelled by class admin.',
                          style: TextStyle(
                            color: c.ink,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                    'TIME SLOT',
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
                    'SUBJECT / EVENT',
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
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            _ScheduleTableRow(
              entry: entries[i],
              now: now,
              onTap: () => onTapEntry(entries[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleTableRow extends StatelessWidget {
  const _ScheduleTableRow({
    required this.entry,
    required this.now,
    required this.onTap,
  });

  final AgendaEntry entry;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final timeStr = entry.end != null
        ? '${Fmt.time(entry.at, suffix: false)}–${Fmt.time(entry.end!)}'
        : Fmt.time(entry.at);

    final isCancelled = entry.cancelled;
    final attachedEvents = entry.events.isNotEmpty
        ? entry.events
        : (entry.event != null ? [entry.event!] : <AcademicEvent>[]);

    final displayName = (entry.course.name.isNotEmpty && entry.course.name != 'Course details pending')
        ? entry.course.name
        : (entry.event?.title ?? entry.course.name);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 105,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCancelled ? c.faint : c.ink,
                    ),
                  ),
                  if (entry.location.isNotEmpty && entry.location != 'Room to be announced') ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.location, size: 11, color: c.faint),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            entry.location.startsWith('Room') || entry.location.startsWith('ACL') || entry.location.startsWith('RKB')
                                ? entry.location
                                : 'Rm ${entry.location}',
                            style: TextStyle(fontSize: 10, color: c.secondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCancelled ? c.faint : c.ink,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      if (entry.isTemporary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: c.amberBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TEMPORARY CLASS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: c.amber,
                            ),
                          ),
                        ),
                      if (entry.isShifted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: c.sageBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SHIFTED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: c.sage,
                            ),
                          ),
                        ),
                      if (entry.session?.isOnline == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: c.subtle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: c.ink,
                            ),
                          ),
                        ),
                      if (entry.course.code != null && entry.course.code!.isNotEmpty && !entry.isTemporary)
                        Text(
                          entry.course.code!,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.secondary,
                          ),
                        ),
                      if (entry.session?.isLab == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: c.sageBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LAB',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: c.sage,
                            ),
                          ),
                        ),
                      if (isCancelled)
                        Text(
                          'Cancelled',
                          style: TextStyle(fontSize: 11, color: c.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  if (attachedEvents.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    for (final ev in attachedEvents) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC62828),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${ev.type.label}: ${ev.title}',
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFC62828),
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 14, color: c.faint),
          ],
        ),
      ),
    );
  }
}
