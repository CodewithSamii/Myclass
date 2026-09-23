import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../design_system/tokens.dart';
import '../features/auth/views/auth_page.dart';
import '../features/home/views/home_page.dart';
import '../features/schedule/views/schedule_page.dart';
import '../features/tasks/views/tasks_page.dart';
import '../features/campus/views/campus_page.dart';
import '../features/profile/views/profile_page.dart';
import '../features/tasks/bloc/tasks_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/events/bloc/events_bloc.dart';
import '../features/schedule/bloc/schedule_bloc.dart';
import '../core/format.dart';
import '../core/clock.dart';
import 'widgets/primitives.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key});
  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  int index = 0;
  static const labels = ['Home', 'Schedule', 'Tasks', 'Campus', 'Profile'];
  static const icons = [
    CupertinoIcons.house,
    CupertinoIcons.calendar,
    CupertinoIcons.checkmark_circle,
    CupertinoIcons.square_grid_2x2,
    CupertinoIcons.person_crop_circle,
  ];
  void select(int i) {
    HapticFeedback.selectionClick();
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wide = context.wide;
    final pages = [
      HomePage(onSchedule: () => select(1)),
      const SchedulePage(),
      const TasksPage(),
      const CampusPage(),
      const ProfilePage(),
    ];
    return MultiBlocListener(
      listeners: [
        BlocListener<TasksBloc, TasksState>(
          listenWhen: (a, b) => b.error != null && b.error != a.error,
          listener: (c, s) => feedback(c, s.error!),
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (a, b) => b.error != null && b.error != a.error,
          listener: (c, s) => feedback(c, s.error!),
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (wide)
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: c.surface,
                      border: Border(right: BorderSide(color: c.line)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const MyClassMark(),
                        const SizedBox(height: 32),
                        for (var i = 0; i < 5; i++)
                          _NavItem(
                            label: labels[i],
                            icon: icons[i],
                            selected: index == i,
                            onTap: () => select(i),
                            vertical: true,
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1100 : 600),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: IndexedStack(index: index, children: pages),
                          ),
                          if (MediaQuery.sizeOf(context).width >= 1000 &&
                              index < 3)
                            const _ContextRail(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
                      child: Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Expanded(
                              child: _NavItem(
                                label: labels[i],
                                icon: icons[i],
                                selected: index == i,
                                onTap: () => select(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.vertical = false,
  });
  final String label;
  final IconData icon;
  final bool selected, vertical;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: vertical ? 16 : 8,
          horizontal: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Motion.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? context.colors.subtle : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 21,
                color: selected ? context.colors.ink : context.colors.faint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.2),
              style: context.type.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? context.colors.ink : context.colors.secondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ContextRail extends StatelessWidget {
  const _ContextRail();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ScheduleBloc>().state;
    final e = context.watch<EventsBloc>().state;
    final p = context.watch<ProfileBloc>().state.profile;
    return Container(
      width: 280,
      margin: const EdgeInsets.fromLTRB(4, 28, 24, 0),
      padding: const EdgeInsets.only(left: 22),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: context.colors.line)),
      ),
      child: ListView(
        children: [
          const Label('Your academic space'),
          const SizedBox(height: 16),
          Text(p.membership.programName, style: context.type.titleMedium),
          const SizedBox(height: 8),
          Text(
            p.membership.label,
            style: context.type.bodySmall?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SectionHeader('This week'),
          for (var i = 0; i < 7; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      Fmt.weekday(
                        weekStart(s.now).add(Duration(days: i)),
                        short: true,
                      ),
                      style: context.type.bodyMedium,
                    ),
                  ),
                  Text(
                    '${e.items.where((v) => sameDay(v.date, weekStart(s.now).add(Duration(days: i))) && v.actionable).length} events',
                    style: context.type.bodySmall?.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          const SectionHeader('A little perspective'),
          Text(
            'Keep your next obligation in view. The rest is here when you need it.',
            style: context.type.bodyMedium?.copyWith(
              color: context.colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
