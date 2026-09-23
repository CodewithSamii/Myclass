import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../design_system/tokens.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/views/auth_page.dart';
import '../features/auth/views/section_entry_sheet.dart';
import '../features/home/views/home_page.dart';
import '../features/campus/views/campus_page.dart';
import '../features/profile/views/profile_page.dart';
import '../features/tasks/bloc/tasks_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/events/bloc/events_bloc.dart';
import '../features/schedule/bloc/schedule_bloc.dart';
import '../features/section_admin/views/set_slots_page.dart';
import '../features/section_admin/views/set_routine_page.dart';
import '../features/section_admin/views/owner_approvals_page.dart';
import '../core/models.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void select(int i) {
    HapticFeedback.selectionClick();
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wide = context.wide;
    final authState = context.watch<AuthBloc>().state;
    final isLoggedIn = authState.phase == AuthPhase.ready &&
        authState.profile != null &&
        authState.profile!.uid != 'guest';

    final profile = context.watch<ProfileBloc>().state.profile;
    final membership = profile.membership;
    final isAdmin = membership.isAdmin;
    final isOwner = membership.isOwner;

    final labels = isLoggedIn
        ? ['Home', 'Campus', 'Profile']
        : ['Home', 'Profile'];

    final icons = isLoggedIn
        ? [
            CupertinoIcons.house,
            CupertinoIcons.square_grid_2x2,
            CupertinoIcons.person_crop_circle,
          ]
        : [
            CupertinoIcons.house,
            CupertinoIcons.person_crop_circle,
          ];

    final pages = isLoggedIn
        ? [
            HomePage(
              onSchedule: () => select(0),
            ),
            const CampusPage(),
            const ProfilePage(),
          ]
        : [
            HomePage(
              onSchedule: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const SectionEntrySheet(),
              ),
            ),
            const ProfilePage(),
          ];

    final safeIndex = index >= pages.length ? 0 : index;

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
          key: _scaffoldKey,
          drawer: _buildBurgerMenuDrawer(
            context: context,
            c: c,
            isLoggedIn: isLoggedIn,
            membership: membership,
            isAdmin: isAdmin,
            isOwner: isOwner,
          ),
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
                        for (var i = 0; i < labels.length; i++)
                          _NavItem(
                            label: labels[i],
                            icon: icons[i],
                            selected: safeIndex == i,
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
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(CupertinoIcons.bars, size: 24),
                                  tooltip: 'Open Menu',
                                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isLoggedIn
                                        ? '${membership.batchName} · ${membership.sectionName}'
                                        : 'MyClass Workspace',
                                    style: context.type.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isLoggedIn)
                                  FilledButton.tonal(
                                    onPressed: () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      builder: (_) => const SectionEntrySheet(),
                                    ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      minimumSize: const Size(0, 36),
                                    ),
                                    child: const Text('Enter Classroom', style: TextStyle(fontSize: 12)),
                                  )
                                else if (isOwner)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.amberBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Owner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: c.amber,
                                      ),
                                    ),
                                  )
                                else if (isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.sageBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: c.sage,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: IndexedStack(index: safeIndex, children: pages),
                                ),
                                if (MediaQuery.sizeOf(context).width >= 1000 && safeIndex < 3)
                                  const _ContextRail(),
                              ],
                            ),
                          ),
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
                          for (var i = 0; i < labels.length; i++)
                            Expanded(
                              child: _NavItem(
                                label: labels[i],
                                icon: icons[i],
                                selected: safeIndex == i,
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

  Widget _buildBurgerMenuDrawer({
    required BuildContext context,
    required MyClassColors c,
    required bool isLoggedIn,
    required SectionMembership membership,
    required bool isAdmin,
    required bool isOwner,
  }) {
    return Drawer(
      backgroundColor: c.canvas,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const MyClassMark(),
                      const SizedBox(width: 14),
                      Text(
                        'MyClass',
                        style: context.type.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isLoggedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  membership.label,
                                  style: context.type.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOwner
                                      ? c.amberBg
                                      : isAdmin
                                          ? c.sageBg
                                          : c.subtle,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOwner
                                      ? 'OWNER'
                                      : isAdmin
                                          ? 'ADMIN'
                                          : 'STUDENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOwner
                                        ? c.amber
                                        : isAdmin
                                            ? c.sage
                                            : c.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            membership.programName,
                            style: context.type.bodySmall?.copyWith(color: c.secondary),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Welcome to MyClass',
                      style: context.type.titleSmall?.copyWith(color: c.secondary),
                    ),
                  ],
                ],
              ),
            ),
            Divider(color: c.line, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  if (isLoggedIn) ...[
                    ListTile(
                      leading: const Icon(CupertinoIcons.calendar, size: 20),
                      title: const Text('Class Schedule'),
                      onTap: () {
                        Navigator.of(context).pop();
                        select(0);
                      },
                    ),
                  ],

                  if (isAdmin || isOwner) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 6),
                      child: Text(
                        'ADMIN CONTROLS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: c.secondary,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(CupertinoIcons.clock, size: 20),
                      title: const Text('Set Slots'),
                      subtitle: const Text('Define universal time periods'),
                      onTap: () {
                        Navigator.of(context).pop();
                        openPage(context, const SetSlotsPage());
                      },
                    ),
                    ListTile(
                      leading: const Icon(CupertinoIcons.slider_horizontal_3, size: 20),
                      title: const Text('Set Routine'),
                      subtitle: const Text('Map Saturday–Friday routine'),
                      onTap: () {
                        Navigator.of(context).pop();
                        openPage(context, const SetRoutinePage());
                      },
                    ),
                  ],

                  if (isOwner) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 6),
                      child: Text(
                        'OWNER WORKFLOW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: c.amber,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(CupertinoIcons.checkmark_shield, size: 20, color: c.amber),
                      title: const Text('Classroom Approvals'),
                      subtitle: const Text('Verify & approve pending sections'),
                      onTap: () {
                        Navigator.of(context).pop();
                        openPage(context, const OwnerApprovalsPage());
                      },
                    ),
                  ],
                ],
              ),
            ),

            Divider(color: c.line, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isLoggedIn
                  ? OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<AuthBloc>().add(AuthLoggedOut());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out of classroom session.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(CupertinoIcons.square_arrow_right, size: 18),
                      label: const Text('Switch Section / Logout'),
                    )
                  : FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => const SectionEntrySheet(),
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Join or Create Classroom'),
                    ),
            ),
          ],
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
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
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
                  color: selected ? c.subtle : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? c.ink : c.faint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                style: context.type.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? c.ink : c.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
