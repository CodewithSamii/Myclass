import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../shared/widgets/academic_tiles.dart';
import '../../events/bloc/events_bloc.dart';
import '../../notes/bloc/notes_bloc.dart';
import '../../notes/views/note_editor.dart';
import '../../home/models/agenda_projection.dart';
import '../../home/views/home_page.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../section_admin/views/event_editor_page.dart';
import '../bloc/schedule_bloc.dart';
import 'routine_page.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ScheduleBloc>().state;
    final events = context.watch<EventsBloc>().state.items;
    final bloc = context.read<ScheduleBloc>();
    final week = weekStart(s.selected);
    final profile = context.watch<ProfileBloc>().state.profile;
    List<AgendaEntry> entries(DateTime d) => AgendaProjection.day(
      day: d,
      sessions: s.sessions,
      events: events,
      courses: s.courses,
      periods: s.periods,
    );
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
    final selected = entries(s.selected);
    final conflicts = AgendaProjection.conflicts(selected);
    return ListView(
      key: const PageStorageKey('schedule'),
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          'Schedule',
          eyebrow: 'A little perspective',
          actions: [
            IconButton(
              tooltip: 'View weekly routine',
              onPressed: () => openPage(context, const RoutinePage()),
              icon: const Icon(CupertinoIcons.rectangle_grid_2x2, size: 22),
            ),
            if (profile.membership.canManage)
              IconButton(
                tooltip: 'Add academic event',
                onPressed: () => openPage(context, const EventEditorPage()),
                icon: const Icon(CupertinoIcons.add, size: 23),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChoiceBar<CalendarView>(
                values: CalendarView.values,
                selected: s.view,
                label: (v) => switch (v) {
                  CalendarView.day => 'Day',
                  CalendarView.week => 'Week',
                  CalendarView.month => 'Month',
                },
                onChanged: (v) => bloc.add(ScheduleViewSelected(v)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.view == CalendarView.month
                          ? '${Fmt.month(s.selected)} ${s.selected.year}'
                          : s.view == CalendarView.week
                          ? '${Fmt.date(week)} – ${Fmt.date(week.add(const Duration(days: 6)))}'
                          : Fmt.fullDate(s.selected),
                      style: context.type.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        bloc.add(ScheduleDateSelected(dateOnly(s.now))),
                    child: const Text('Today'),
                  ),
                  IconButton(
                    tooltip: 'Previous ${s.view.name}',
                    onPressed: () => _shift(bloc, s, -1),
                    icon: const Icon(CupertinoIcons.chevron_left, size: 16),
                  ),
                  IconButton(
                    tooltip: 'Next ${s.view.name}',
                    onPressed: () => _shift(bloc, s, 1),
                    icon: const Icon(CupertinoIcons.chevron_right, size: 16),
                  ),
                ],
              ),
              if (s.view == CalendarView.month)
                _MonthGrid(
                  selected: s.selected,
                  now: s.now,
                  entries: entries,
                  onSelected: (d) => bloc.add(ScheduleDateSelected(d)),
                )
              else if (s.view == CalendarView.week) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _DayPill(
                          date: week.add(Duration(days: i)),
                          selected: s.selected,
                          now: s.now,
                          count: entries(
                            week.add(Duration(days: i)),
                          ).where((e) => !e.cancelled).length,
                          onTap: () => bloc.add(
                            ScheduleDateSelected(week.add(Duration(days: i))),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              SectionHeader(
                sameDay(s.selected, s.now) ? 'Today' : Fmt.fullDate(s.selected),
                trailing: Text(
                  '${selected.where((e) => !e.cancelled).length} planned',
                  style: context.type.bodySmall?.copyWith(
                    color: context.colors.secondary,
                  ),
                ),
              ),
              if (conflicts.isNotEmpty) ...[
                Surface(
                  color: context.colors.amberBg,
                  border: false,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 16,
                        color: context.colors.amber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${conflicts.length} items overlap. Check the latest instructions.',
                          style: context.type.bodySmall?.copyWith(
                            color: context.colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AnimatedSwitcher(
                duration: Motion.normal,
                child: Column(
                  key: ValueKey('${s.view}-${s.selected}'),
                  children: [
                    if (selected.isEmpty)
                      const EmptyState(
                        'A clear day.',
                        'No classes or deadlines scheduled.',
                      ),
                    for (var i = 0; i < selected.length; i++) ...[
                      if (i > 0 &&
                          selected[i - 1].end != null &&
                          selected[i].at
                                  .difference(selected[i - 1].end!)
                                  .inMinutes >=
                              20 &&
                          !selected[i].deadline &&
                          !selected[i].timeUnknown)
                        Padding(
                          padding: const EdgeInsets.only(left: 86, bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.pause,
                                size: 11,
                                color: context.colors.faint,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${selected[i].at.difference(selected[i - 1].end!).inMinutes} min break',
                                style: context.type.bodySmall?.copyWith(
                                  color: context.colors.faint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      TimelineRow(
                        entry: selected[i],
                        now: s.now,
                        last: i == selected.length - 1,
                        conflict: conflicts.contains(selected[i]),
                        onTap: () => openAgenda(context, selected[i]),
                      ),
                    ],
                  ],
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SectionHeader('Your reminders'),
                for (final note in notes)
                  SettingsRow(
                    note.text,
                    subtitle: 'Private · ${Fmt.time(note.remindAt!)}',
                    icon: CupertinoIcons.bell,
                    onTap: () => openSheet(context, NoteEditor(note: note)),
                  ),
              ],
              if (s.view == CalendarView.week) ...[
                const SectionHeader('The week at a glance'),
                for (var i = 0; i < 7; i++)
                  _WeekSummary(
                    date: week.add(Duration(days: i)),
                    entries: entries(week.add(Duration(days: i))),
                    selected: s.selected,
                    onTap: () => bloc.add(
                      ScheduleDateSelected(week.add(Duration(days: i))),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              SettingsRow(
                'Repeating class routine',
                subtitle: 'Your regular week, separate from academic events',
                icon: CupertinoIcons.arrow_2_squarepath,
                onTap: () => openPage(context, const RoutinePage()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  void _shift(ScheduleBloc b, ScheduleState s, int d) {
    HapticFeedback.selectionClick();
    b.add(
      ScheduleDateSelected(
        s.view == CalendarView.month
            ? DateTime(s.selected.year, s.selected.month + d, 1)
            : s.selected.add(
                Duration(days: d * (s.view == CalendarView.week ? 7 : 1)),
              ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.date,
    required this.selected,
    required this.now,
    required this.count,
    required this.onTap,
  });
  final DateTime date, selected, now;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final active = sameDay(date, selected);
    final c = context.colors;
    return Semantics(
      button: true,
      selected: active,
      label: '${Fmt.fullDate(date)}, $count scheduled',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: Motion.fast,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? c.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: !active && sameDay(date, now)
                  ? c.line
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Text(
                Fmt.weekday(date, short: true).substring(0, 1),
                style: context.type.bodySmall?.copyWith(
                  color: active ? c.canvas : c.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${date.day}',
                style: context.type.titleMedium?.copyWith(
                  color: active ? c.canvas : c.ink,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < (count > 3 ? 3 : count); i++)
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: active
                            ? c.canvas.withValues(alpha: .7)
                            : c.faint,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (count == 0) const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekSummary extends StatelessWidget {
  const _WeekSummary({
    required this.date,
    required this.entries,
    required this.selected,
    required this.onTap,
  });
  final DateTime date, selected;
  final List<AgendaEntry> entries;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final active = entries.where((e) => !e.cancelled).toList();
    final events = active.where((e) => e.event != null).toList();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                Fmt.weekday(date, short: true),
                style: context.type.titleSmall,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active.isEmpty
                        ? 'No scheduled events'
                        : '${active.where((e) => e.session != null).length} classes${events.isNotEmpty ? ' · ${events.length} academic events' : ''}',
                    style: context.type.bodyMedium?.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                  if (events.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      events.map((e) => e.title).take(2).join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.bodySmall?.copyWith(
                        color: context.colors.amber,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Text('${date.day}', style: context.type.titleSmall),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (active.length / 8).clamp(0, 1),
                    minHeight: 3,
                    backgroundColor: context.colors.line,
                    color: context.colors.faint,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.selected,
    required this.now,
    required this.entries,
    required this.onSelected,
  });
  final DateTime selected, now;
  final List<AgendaEntry> Function(DateTime) entries;
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) {
    final first = DateTime(selected.year, selected.month, 1);
    final start = weekStart(first);
    final days = DateTime(selected.year, selected.month + 1, 0).day;
    final cells = ((days + first.weekday % 7) / 7).ceil() * 7;
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              Expanded(child: Center(child: Label(d))),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: .9,
          ),
          itemBuilder: (c, i) {
            final day = start.add(Duration(days: i));
            final selectedDay = sameDay(day, selected);
            final events = entries(
              day,
            ).where((e) => e.event != null && !e.cancelled).length;
            return Semantics(
              button: true,
              selected: selectedDay,
              label: '${Fmt.fullDate(day)}, $events academic events',
              child: InkWell(
                onTap: () => onSelected(day),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selectedDay
                        ? context.colors.ink
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !selectedDay && sameDay(day, now)
                          ? context.colors.line
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: context.type.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: selectedDay
                              ? context.colors.canvas
                              : day.month == selected.month
                              ? context.colors.ink
                              : context.colors.faint.withValues(alpha: .5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (events > 0)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedDay
                                ? context.colors.canvas
                                : context.colors.amber,
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
