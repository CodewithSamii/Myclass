import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/format.dart';
import '../../../core/clock_cubit.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/campus_bloc.dart';

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
          const SizedBox(height: 24),
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
}

class BusRouteCard extends StatelessWidget {
  const BusRouteCard({
    super.key,
    required this.route,
    required this.toCampus,
    required this.nowMinute,
  });
  final BusRoute route;
  final bool toCampus;
  final int nowMinute;
  @override
  Widget build(BuildContext context) {
    final departures = route.departures
        .where((d) => d.toCampus == toCampus)
        .toList();
    final next = departures.where((d) => d.minute >= nowMinute).firstOrNull;
    return Surface(
      onTap: () => openPage(
        context,
        BusRouteDetailPage(route: route, initialToCampus: toCampus),
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
                  color: d == next
                      ? context.colors.sage
                      : context.colors.secondary,
                  background: d == next
                      ? context.colors.sageBg
                      : context.colors.subtle,
                ),
            ],
          ),
          const SizedBox(height: 12),
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
  });
  final BusRoute route;
  final bool initialToCampus;
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
