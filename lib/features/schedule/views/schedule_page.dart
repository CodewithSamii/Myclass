import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../shared/widgets/chocolate_block_date_bar.dart';
import '../../events/bloc/events_bloc.dart';

import '../../events/views/event_detail_page.dart';
import '../../notes/bloc/notes_bloc.dart';
import '../../notes/views/note_editor.dart';
import '../../home/models/agenda_projection.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../section_admin/views/set_slots_page.dart';
import '../../section_admin/views/set_routine_page.dart';
import '../bloc/schedule_bloc.dart';
import 'class_detail_page.dart';
import 'temporary_class_sheet.dart';
import 'admin_options_sheet.dart';
import '../../section_admin/views/event_editor_page.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ScheduleBloc>().state;
    final events = context.watch<EventsBloc>().state.items;
    final bloc = context.read<ScheduleBloc>();
    final profile = context.watch<ProfileBloc>().state.profile;
    final c = context.colors;

    List<AgendaEntry> entries(DateTime d) => AgendaProjection.day(
      day: d,
      sessions: s.sessions,
      events: events,
      courses: s.courses,
      periods: s.periods,
    );

    final selectedEntries = entries(s.selected);

    final dueToday = events
        .where((e) =>
            e.actionable &&
            e.status != EventStatus.cancelled &&
            sameDay(e.effectiveAt, s.selected))
        .toList();

    final notes = context
        .watch<NotesBloc>()
        .state
        .items
        .where(
          (n) =>
              n.remindAt != null &&
              sameDay(n.remindAt!, s.selected) &&
              !n.completed,
        )
        .toList();

    return ListView(
      key: const PageStorageKey('schedule'),
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          'Class Schedule',
          eyebrow: '${profile.membership.batchName} · ${profile.membership.sectionName}',
          subtitle: profile.membership.canManage
              ? 'Administrator Controls Available'
              : 'Your daily routine & academic events',
          actions: [
            if (profile.membership.canManage) ...[
              IconButton(
                tooltip: 'Set Time Slots',
                onPressed: () => openPage(context, const SetSlotsPage()),
                icon: const Icon(CupertinoIcons.clock, size: 21),
              ),
              IconButton(
                tooltip: 'Set 7-Day Routine',
                onPressed: () => openPage(context, const SetRoutinePage()),
                icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 21),
              ),
            ],
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chocolate Block 2-Row Horizontal Date Bar
              _ChocolateBlockDateBar(
                selected: s.selected,
                now: s.now,
                onDateSelected: (d) => bloc.add(ScheduleDateSelected(d)),
              ),

              const SizedBox(height: 18),

              // Calendar View Mode Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sameDay(s.selected, s.now) ? 'Today' : Fmt.fullDate(s.selected),
                    style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => bloc.add(ScheduleDateSelected(dateOnly(s.now))),
                    child: const Text('Jump to Today'),
                  ),
                ],
              ),
              if (profile.membership.canManage || profile.membership.isOwner) ...[
                const SizedBox(height: 2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => openSheet(
                          context,
                          TemporaryClassSheet(initialDate: s.selected),
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
                          final daySessions = s.sessions.where((ss) => ss.weekday == s.selected.weekday).toList();
                          if (daySessions.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No routine classes scheduled for ${Fmt.weekday(s.selected)}. Events can only be assigned to existing routine classes.'),
                                backgroundColor: context.colors.amber,
                              ),
                            );
                          } else {
                            openPage(
                              context,
                              EventEditorPage(initialDate: s.selected),
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
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => openSheet(
                          context,
                          AdminOptionsSheet(selectedDate: s.selected),
                        ),
                        icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 14),
                        label: const Text('Admin Options'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (dueToday.isNotEmpty) ...[
                const SizedBox(height: 10),
                Surface(
                  onTap: () => openPage(
                    context,
                    EventDetailPage(id: dueToday.first.id),
                  ),
                  padding: const EdgeInsets.all(14),
                  color: c.amberBg,
                  border: false,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_text,
                        size: 20,
                        color: c.amber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dueToday.first.title,
                              style: context.type.titleSmall?.copyWith(
                                color: c.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due ${sameDay(dueToday.first.effectiveAt, s.now) ? "Today" : Fmt.date(dueToday.first.effectiveAt)}, ${Fmt.time(dueToday.first.effectiveAt)}${dueToday.length > 1 ? " · +${dueToday.length - 1} more event${dueToday.length > 2 ? 's' : ''}" : ""}',
                              style: context.type.bodySmall?.copyWith(
                                color: c.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: c.amber,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // 2-Column Schedule Table
              _TwoColumnScheduleTable(
                entries: selectedEntries,
                timeSlots: s.timeSlots,
                now: s.now,
                onTapEntry: (entry) {
                  if (entry.session != null) {
                    openPage(
                      context,
                      ClassDetailPage(sessionId: entry.session!.id, day: entry.day),
                    );
                  } else if (entry.event != null) {
                    openPage(context, EventDetailPage(id: entry.event!.id));
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
                  subtitle: 'Define standard periods (e.g. 10:00–11:00, 11:00–12:00)',
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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

typedef _ChocolateBlockDateBar = ChocolateBlockDateBar;

/// 2-Column Schedule Table Layout
/// Left column: Time slot (e.g. 10:00–11:00)
/// Right column: Subject / Event details
/// Event titles for Class Tests, Presentations, Vivas, Exams highlighted in bold red underline
class _TwoColumnScheduleTable extends StatelessWidget {
  const _TwoColumnScheduleTable({
    required this.entries,
    required this.timeSlots,
    required this.now,
    required this.onTapEntry,
  });

  final List<AgendaEntry> entries;
  final List<TimeSlot> timeSlots;
  final DateTime now;
  final ValueChanged<AgendaEntry> onTapEntry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (entries.isEmpty) {
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
              'Enjoy your free time or prepare ahead for upcoming exams.',
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

          // 2-Column Rows
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

  bool get isMajorAssessment {
    if (entry.event == null) return false;
    final t = entry.event!.type;
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
    final timeStr = entry.end != null
        ? '${Fmt.time(entry.at, suffix: false)}–${Fmt.time(entry.end!)}'
        : Fmt.time(entry.at);

    final isAcademicEvent = entry.event != null;
    final isCancelled = entry.cancelled;
    final isShifted = entry.isShifted;

    final attachedEvents = entry.session != null
        ? (entry.events.isNotEmpty ? entry.events : (entry.event != null ? [entry.event!] : <AcademicEvent>[]))
        : <AcademicEvent>[];

    final baseName = (entry.course.name.isNotEmpty && entry.course.name != 'Course details pending')
        ? entry.course.name
        : entry.title;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Time Slot
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
                  if (entry.location.isNotEmpty && !entry.deadline) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.location, size: 11, color: c.faint),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            entry.location.startsWith('Room') ? entry.location : 'Rm ${entry.location}',
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

            // Right Column: Subject / Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.session == null && isAcademicEvent && isMajorAssessment) ...[
                    // Red bold underlined title for important standalone events
                    Text(
                      '${entry.event!.type.label.toUpperCase()}: ${entry.title}',
                      style: const TextStyle(
                        color: Color(0xFFC62828), // Bold red
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFC62828),
                        decorationThickness: 1.5,
                      ),
                    ),
                  ] else ...[
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: baseName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isCancelled ? c.faint : c.ink,
                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (isShifted) ...[
                            const TextSpan(text: ' — '),
                            TextSpan(
                              text: 'Shifted',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: c.sage,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

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
                      if (isShifted)
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
                      if (!entry.isTemporary && entry.course.code != null && entry.course.code!.isNotEmpty)
                        Text(
                          entry.course.compactName,
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
                        child: InkWell(
                          onTap: () {
                            openPage(context, EventDetailPage(id: ev.id));
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
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
