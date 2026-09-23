import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
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
    final conflicts = AgendaProjection.conflicts(selectedEntries);

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

              if (conflicts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Surface(
                  color: c.amberBg,
                  border: false,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 16,
                        color: c.amber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${conflicts.length} items overlap. Check latest updates.',
                          style: context.type.bodySmall?.copyWith(color: c.amber),
                        ),
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

/// 2-Row "Chocolate Block" Date Bar
/// Top row: Date (e.g. "22 Nov")
/// Bottom row: Day (e.g. "Monday")
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
    // Generate a 14-day window centered around today
    final startDay = dateOnly(now).subtract(const Duration(days: 3));
    final days = List.generate(18, (i) => startDay.add(Duration(days: i)));

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final day = days[i];
          final isSelected = sameDay(day, selected);
          final isToday = sameDay(day, now);

          // Rich chocolate theme colors
          const chocolateDark = Color(0xFF3E2723); // Deep rich cocoa
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
                width: 78,
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
                    // Top row: Date (e.g. "22 Nov")
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
                    const SizedBox(height: 4),
                    // Bottom row: Day (e.g. "Monday")
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
                  if (isAcademicEvent && isMajorAssessment) ...[
                    // Red bold underlined title for important events
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
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCancelled ? c.faint : c.ink,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],

                  const SizedBox(height: 3),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
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
