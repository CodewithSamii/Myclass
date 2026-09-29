import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/format.dart';
import '../../../core/clock_cubit.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../events/bloc/events_bloc.dart';
import '../../home/models/agenda_projection.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../bloc/campus_bloc.dart';
import 'custom_bus_days_sheet.dart';

class BusPage extends StatefulWidget {
  const BusPage({super.key});
  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  bool toCampus = true;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<CampusBloc>().state;
    final now = context.watch<ClockCubit>().state;
    final profile = context.watch<ProfileBloc>().state.profile;
    final scheduleState = context.watch<ScheduleBloc>().state;
    final eventsState = context.watch<EventsBloc>().state;

    final todayEntries = AgendaProjection.day(
      day: now,
      sessions: scheduleState.sessions,
      events: eventsState.items,
      courses: scheduleState.courses,
      periods: scheduleState.periods,
    ).where((e) => !e.cancelled && !e.deadline && !e.timeUnknown).toList();

    final hasClassesToday = todayEntries.isNotEmpty;
    final firstClassStart = hasClassesToday
        ? todayEntries.first.session?.startMinute ??
            (todayEntries.first.at.hour * 60 + todayEntries.first.at.minute)
        : null;
    final lastClassEnd = hasClassesToday
        ? todayEntries.last.session?.endMinute ??
            (todayEntries.last.end != null
                ? todayEntries.last.end!.hour * 60 + todayEntries.last.end!.minute
                : null)
        : null;

    final busReminderMin = profile.reminders.busReminderMinutes;
    final busMode = profile.reminders.busReminderMode;
    final busDays = profile.reminders.busReminderDays;
    final isTodayActive = profile.reminders.isBusReminderActiveForDay(
      date: now,
      hasClasses: hasClassesToday,
    );

    String reminderStatusText;
    if (busReminderMin == 0) {
      reminderStatusText = 'Bus reminders are currently turned off.';
    } else if (busMode == 'classDaysOnly') {
      reminderStatusText = hasClassesToday
          ? 'Active for today’s classes (${Fmt.minute(firstClassStart!)} – ${Fmt.minute(lastClassEnd!)}).'
          : 'No classes scheduled today · Bus reminders are quieted.';
    } else if (busMode == 'everyDay') {
      reminderStatusText = 'Active every day according to your bus reminder time.';
    } else {
      reminderStatusText = isTodayActive
          ? 'Active for today according to custom day selection.'
          : 'Quieted today based on your custom day selection.';
    }

    return DetailPage(
      title: 'University bus',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Find your way.', style: context.type.headlineLarge),
          const SizedBox(height: 10),
          Text(
            'Four routes. One less thing to work out.',
            style: context.type.bodyLarge?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 18),

          // Smart Bus Reminder Setting Card
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.bell, size: 16, color: context.colors.ink),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Smart Bus Reminder',
                        style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (busReminderMin > 0) ...[
                      const SizedBox(width: 8),
                      Badge(
                        '${busReminderMin}m before',
                        color: context.colors.sage,
                        background: context.colors.sageBg,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reminderStatusText,
                  style: context.type.bodySmall?.copyWith(
                    color: (busReminderMin > 0 && isTodayActive)
                        ? context.colors.secondary
                        : context.colors.amber,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'How early to notify me',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.colors.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final min in [0, 5, 10, 15, 60])
                      ChoiceChip(
                        label: Text(min == 0 ? 'Off' : '$min min before'),
                        selected: busReminderMin == min,
                        showCheckmark: false,
                        onSelected: (_) {
                          context.read<ProfileBloc>().add(
                            ProfileSaved(
                              profile.copyWith(
                                reminders: profile.reminders.copyWith(busReminderMinutes: min),
                              ),
                            ),
                          );
                          feedback(
                            context,
                            min == 0
                                ? 'Bus reminders turned off.'
                                : 'Reminder set for $min minutes before bus departures.',
                          );
                        },
                      ),
                  ],
                ),
                if (busReminderMin > 0) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Which days to notify me',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 3 horizontal selection boxes: | Class Days | Every Day | Custom |
                  Row(
                    children: [
                      Expanded(
                        child: _buildDayBox(
                          context,
                          label: 'Class Days',
                          isSelected: busMode == 'classDaysOnly',
                          onTap: () {
                            context.read<ProfileBloc>().add(
                              ProfileSaved(
                                profile.copyWith(
                                  reminders: profile.reminders.copyWith(busReminderMode: 'classDaysOnly'),
                                ),
                              ),
                            );
                            feedback(context, 'Notify me only on days when I have classes.');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDayBox(
                          context,
                          label: 'Every Day',
                          isSelected: busMode == 'everyDay',
                          onTap: () {
                            context.read<ProfileBloc>().add(
                              ProfileSaved(
                                profile.copyWith(
                                  reminders: profile.reminders.copyWith(busReminderMode: 'everyDay'),
                                ),
                              ),
                            );
                            feedback(context, 'Notify me every day.');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDayBox(
                          context,
                          label: 'Custom',
                          isSelected: busMode == 'custom',
                          onTap: () => _openCustomDaysSheet(context, profile),
                        ),
                      ),
                    ],
                  ),
                  if (busMode == 'custom') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(CupertinoIcons.calendar, size: 14, color: context.colors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            busDays.isEmpty
                                ? 'No custom days selected yet. Tap to configure.'
                                : 'Active on: ${_formatCustomDays(busDays)}',
                            style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openCustomDaysSheet(context, profile),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: const Text('Change days'),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          ChoiceBar<bool>(
            values: const [true, false],
            selected: toCampus,
            label: (v) => v ? 'To campus' : 'From campus',
            onChanged: (v) => setState(() => toCampus = v),
          ),
          const SizedBox(height: 24),
          if (s.phase == LoadPhase.loading)
            const Skeleton()
          else
            for (final route in s.routes)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: BusRouteCard(
                  route: route,
                  toCampus: toCampus,
                  nowMinute: now.hour * 60 + now.minute,
                  firstClassStart: firstClassStart,
                  lastClassEnd: lastClassEnd,
                  hasClassesToday: isTodayActive,
                ),
              ),
          const SizedBox(height: 12),
          Text(
            'Illustrative weekday timetable. No live tracking. Confirm real services with university transport.',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBox(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return Material(
      color: isSelected ? c.subtle : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? c.ink : c.line,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? c.ink : c.secondary,
            ),
          ),
        ),
      ),
    );
  }

  void _openCustomDaysSheet(BuildContext context, UserProfile profile) {
    openSheet(
      context,
      CustomBusDaysSheet(
        initialDays: profile.reminders.busReminderDays,
        onSaved: (selectedDays) {
          context.read<ProfileBloc>().add(
            ProfileSaved(
              profile.copyWith(
                reminders: profile.reminders.copyWith(
                  busReminderMode: 'custom',
                  busReminderDays: selectedDays,
                ),
              ),
            ),
          );
          feedback(context, 'Custom reminder schedule saved.');
        },
      ),
    );
  }

  String _formatCustomDays(List<int> days) {
    const map = {
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
    };
    final ordered = [
      DateTime.saturday,
      DateTime.sunday,
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ];
    final active = ordered.where((d) => days.contains(d)).map((d) => map[d]!).toList();
    if (active.length == 7) return 'Every day (all 7 days)';
    return active.join(', ');
  }
}

class BusRouteCard extends StatelessWidget {
  const BusRouteCard({
    super.key,
    required this.route,
    required this.toCampus,
    required this.nowMinute,
    this.firstClassStart,
    this.lastClassEnd,
    this.hasClassesToday = false,
  });

  final BusRoute route;
  final bool toCampus;
  final int nowMinute;
  final int? firstClassStart;
  final int? lastClassEnd;
  final bool hasClassesToday;

  @override
  Widget build(BuildContext context) {
    final departures = route.departures
        .where((d) => d.toCampus == toCampus)
        .toList();
    final next = departures.where((d) => d.minute >= nowMinute).firstOrNull;

    // Class schedule matched departure
    BusDeparture? recommendedDeparture;
    if (hasClassesToday) {
      if (toCampus && firstClassStart != null) {
        // Find departure arriving on time (arrival before firstClassStart and not more than 75m early)
        final arrivingBefore = departures.where((d) {
          final arrival = d.minute + route.durationMinutes;
          return arrival <= firstClassStart! && arrival >= (firstClassStart! - 75);
        }).toList();
        recommendedDeparture = arrivingBefore.isNotEmpty ? arrivingBefore.last : null;
      } else if (!toCampus && lastClassEnd != null) {
        // Find departure leaving within 60m after lastClassEnd
        final leavingAfter = departures.where((d) => d.minute >= lastClassEnd! && d.minute <= (lastClassEnd! + 60)).toList();
        recommendedDeparture = leavingAfter.isNotEmpty ? leavingAfter.first : null;
      }
    }

    return Surface(
      onTap: () => openPage(
        context,
        BusRouteDetailPage(
          route: route,
          initialToCampus: toCampus,
          firstClassStart: firstClassStart,
          lastClassEnd: lastClassEnd,
          hasClassesToday: hasClassesToday,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.subtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  route.number.toString().padLeft(2, '0'),
                  style: context.type.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  toCampus
                      ? '${route.name} → Campus'
                      : 'Campus → ${route.name}',
                  style: context.type.titleMedium,
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 13),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            route.stops
                .skip(1)
                .take(route.stops.length - 2)
                .map((s) => s.name)
                .join(' · '),
            style: context.type.bodySmall?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in departures)
                Badge(
                  Fmt.minute(d.minute),
                  color: d == recommendedDeparture
                      ? context.colors.sage
                      : (d == next
                          ? context.colors.ink
                          : context.colors.secondary),
                  background: d == recommendedDeparture
                      ? context.colors.sageBg
                      : (d == next
                          ? context.colors.subtle
                          : context.colors.subtle.withOpacity(0.5)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recommendedDeparture != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(CupertinoIcons.sparkles, size: 13, color: context.colors.sage),
                  const SizedBox(width: 6),
                  Text(
                    toCampus
                        ? 'Recommended: ${Fmt.minute(recommendedDeparture.minute)} (Arrives for ${Fmt.minute(firstClassStart!)} class)'
                        : 'Recommended: ${Fmt.minute(recommendedDeparture.minute)} (After ${Fmt.minute(lastClassEnd!)} class)',
                    style: context.type.bodySmall?.copyWith(
                      color: context.colors.sage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            next == null
                ? 'No more departures in this direction today'
                : 'Next departure · ${Fmt.minute(next.minute)} · Approx. ${route.durationMinutes} min',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class BusRouteDetailPage extends StatefulWidget {
  const BusRouteDetailPage({
    super.key,
    required this.route,
    this.initialToCampus = true,
    this.firstClassStart,
    this.lastClassEnd,
    this.hasClassesToday = false,
  });

  final BusRoute route;
  final bool initialToCampus;
  final int? firstClassStart;
  final int? lastClassEnd;
  final bool hasClassesToday;

  @override
  State<BusRouteDetailPage> createState() => _BusRouteDetailPageState();
}

class _BusRouteDetailPageState extends State<BusRouteDetailPage> {
  late bool toCampus = widget.initialToCampus;
  int? departure;

  @override
  Widget build(BuildContext context) {
    final r = widget.route;
    final times = r.departures.where((d) => d.toCampus == toCampus).toList();
    final current = times.any((d) => d.minute == departure)
        ? departure!
        : times.first.minute;
    final stops = toCampus ? r.stops : r.stops.reversed.toList();

    return DetailPage(
      title: 'Route ${r.number.toString().padLeft(2, '0')}',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(r.name, style: context.type.headlineLarge),
          const SizedBox(height: 10),
          Text(
            '${r.stops.length} stops · Approx. ${r.durationMinutes} minutes',
            style: context.type.bodyMedium?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          ChoiceBar<bool>(
            values: const [true, false],
            selected: toCampus,
            label: (v) => v ? 'To campus' : 'Return',
            onChanged: (v) => setState(() {
              toCampus = v;
              departure = null;
            }),
          ),
          const SectionHeader('Choose a departure'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in times)
                ChoiceChip(
                  label: Text(Fmt.minute(d.minute)),
                  selected: current == d.minute,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => departure = d.minute),
                ),
            ],
          ),
          const SectionHeader('Along the way'),
          for (var i = 0; i < stops.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: i == 0 || i == stops.length - 1
                                ? context.colors.ink
                                : context.colors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.secondary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        if (i < stops.length - 1)
                          Expanded(
                            child: Container(
                              width: 1,
                              color: context.colors.line,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14, bottom: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stops[i].name, style: context.type.titleMedium),
                          const SizedBox(height: 5),
                          Text(
                            i == 0
                                ? 'Departure'
                                : i == stops.length - 1
                                ? 'Arrival · Approximate'
                                : 'Approximate stop time',
                            style: context.type.bodySmall?.copyWith(
                              color: context.colors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    Fmt.minute(
                      current +
                          (toCampus
                              ? stops[i].minuteOffset
                              : r.durationMinutes - stops[i].minuteOffset),
                    ),
                    style: context.type.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (r.notice != null)
            Surface(
              color: context.colors.amberBg,
              border: false,
              child: Text(
                r.notice!,
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.amber,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Sample schedule. Stop times are estimates, not live vehicle positions.',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
