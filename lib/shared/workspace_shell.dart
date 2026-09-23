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
import '../core/repositories.dart';
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
                          if (isOwner)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: c.amberBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: c.amber.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.shield_fill, color: c.amber, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${membership.universityName} · ${membership.programName} · ${membership.batchName} · ${membership.sectionName}',
                                      style: context.type.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: c.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _showOwnerSectionSwitcher(context),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: c.amber,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(CupertinoIcons.arrow_2_squarepath, size: 12, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'Switch',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
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
                    ListTile(
                      leading: Icon(CupertinoIcons.arrow_2_squarepath, size: 20, color: c.amber),
                      title: const Text('Switch Section / Classroom'),
                      subtitle: const Text('Navigate across universities & batches'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showOwnerSectionSwitcher(context);
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

void _showOwnerSectionSwitcher(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const OwnerSectionSwitcherSheet(),
  );
}

class OwnerSectionSwitcherSheet extends StatefulWidget {
  const OwnerSectionSwitcherSheet({super.key});

  @override
  State<OwnerSectionSwitcherSheet> createState() => _OwnerSectionSwitcherSheetState();
}

class _OwnerSectionSwitcherSheetState extends State<OwnerSectionSwitcherSheet> {
  List<University> universities = [];
  University? selectedUniversity;

  List<Department> departments = [];
  Department? selectedDept;

  List<Batch> batches = [];
  Batch? selectedBatch;

  List<Section> sections = [];
  Section? selectedSection;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => loading = true);
    try {
      final repo = context.read<AcademicStructureRepository>();
      final uList = await repo.universities();
      if (!mounted) return;
      final currentProfile = context.read<ProfileBloc>().state.profile;
      final currentMem = currentProfile.membership;

      final defaultUni = uList.firstWhere(
        (u) => u.id == currentMem.universityId,
        orElse: () => uList.isNotEmpty ? uList.first : const University('lu', 'Leading University', 'Asia/Dhaka'),
      );

      final dList = await repo.departments('Undergraduate', universityId: defaultUni.id);
      final defaultDept = dList.firstWhere(
        (d) => d.id == currentMem.departmentId,
        orElse: () => dList.isNotEmpty ? dList.first : const Department('cse', 'Computer Science & Engineering', 'CSE'),
      );

      final progs = await repo.programs(defaultDept.id, 'Undergraduate', universityId: defaultUni.id);
      final prog = progs.isNotEmpty
          ? progs.first
          : AcademicProgram(
              id: 'prog-${defaultDept.id}',
              name: defaultDept.name,
              shortName: defaultDept.shortName,
              departmentId: defaultDept.id,
              type: 'Undergraduate',
              universityId: defaultUni.id,
            );

      final bList = await repo.batches(prog.id);
      final defaultBatch = bList.firstWhere(
        (b) => b.id == currentMem.batchId,
        orElse: () => bList.isNotEmpty ? bList.first : const Batch('b64', 'prog-cse', 'Batch 64'),
      );

      final sList = await repo.sections(defaultBatch.id);
      final defaultSec = sList.firstWhere(
        (s) => s.id == currentMem.sectionId,
        orElse: () => sList.isNotEmpty ? sList.first : const Section('s-b', 'b64', 'Section B'),
      );

      if (mounted) {
        setState(() {
          universities = uList;
          selectedUniversity = defaultUni;
          departments = dList;
          selectedDept = defaultDept;
          batches = bList;
          selectedBatch = defaultBatch;
          sections = sList;
          selectedSection = defaultSec;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> _onUniversityChanged(University u) async {
    setState(() {
      selectedUniversity = u;
      loading = true;
      departments = [];
      selectedDept = null;
      batches = [];
      selectedBatch = null;
      sections = [];
      selectedSection = null;
    });
    try {
      final repo = context.read<AcademicStructureRepository>();
      final dList = await repo.departments('Undergraduate', universityId: u.id);
      Department? firstDept = dList.isNotEmpty ? dList.first : null;

      List<Batch> bList = [];
      Batch? firstBatch;
      List<Section> sList = [];
      Section? firstSec;

      if (firstDept != null) {
        final progs = await repo.programs(firstDept.id, 'Undergraduate', universityId: u.id);
        final progId = progs.isNotEmpty ? progs.first.id : 'prog-${firstDept.id}';
        bList = await repo.batches(progId);
        firstBatch = bList.isNotEmpty ? bList.first : null;

        if (firstBatch != null) {
          sList = await repo.sections(firstBatch.id);
          firstSec = sList.isNotEmpty ? sList.first : null;
        }
      }

      if (mounted) {
        setState(() {
          departments = dList;
          selectedDept = firstDept;
          batches = bList;
          selectedBatch = firstBatch;
          sections = sList;
          selectedSection = firstSec;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _onDeptChanged(Department d) async {
    setState(() {
      selectedDept = d;
      loading = true;
      batches = [];
      selectedBatch = null;
      sections = [];
      selectedSection = null;
    });
    try {
      final repo = context.read<AcademicStructureRepository>();
      final progs = await repo.programs(d.id, 'Undergraduate', universityId: selectedUniversity?.id);
      final progId = progs.isNotEmpty ? progs.first.id : 'prog-${d.id}';
      final bList = await repo.batches(progId);
      final firstBatch = bList.isNotEmpty ? bList.first : null;

      List<Section> sList = [];
      Section? firstSec;
      if (firstBatch != null) {
        sList = await repo.sections(firstBatch.id);
        firstSec = sList.isNotEmpty ? sList.first : null;
      }

      if (mounted) {
        setState(() {
          batches = bList;
          selectedBatch = firstBatch;
          sections = sList;
          selectedSection = firstSec;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _onBatchChanged(Batch b) async {
    setState(() {
      selectedBatch = b;
      loading = true;
      sections = [];
      selectedSection = null;
    });
    try {
      final repo = context.read<AcademicStructureRepository>();
      final sList = await repo.sections(b.id);
      final firstSec = sList.isNotEmpty ? sList.first : null;

      if (mounted) {
        setState(() {
          sections = sList;
          selectedSection = firstSec;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  void _applySwitch() {
    if (selectedSection == null || selectedBatch == null || selectedDept == null) return;

    final membership = SectionMembership(
      sectionId: selectedSection!.id,
      departmentId: selectedDept!.id,
      programId: selectedBatch!.programId,
      batchId: selectedBatch!.id,
      programName: selectedDept!.name,
      batchName: selectedBatch!.label,
      sectionName: selectedSection!.label,
      universityId: selectedUniversity?.id ?? 'lu',
      universityName: selectedUniversity?.name ?? 'Leading University',
      role: UserRole.myClassOwner,
    );

    context.read<AuthBloc>().add(
      AuthSectionLoggedIn(
        name: 'MyClass Owner',
        membership: membership,
        grant: SectionGrant(selectedSection!.id, 'owner-token', role: UserRole.myClassOwner),
      ),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${selectedDept!.name} · ${selectedBatch!.label} · ${selectedSection!.label}'),
        backgroundColor: context.colors.sage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.shield_fill, color: c.amber, size: 22),
                const SizedBox(width: 8),
                Text('Owner Mode — Switch Section', style: context.type.headlineSmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Navigate and manage any university, department, batch, and section.',
              style: context.type.bodySmall?.copyWith(color: c.secondary),
            ),
            const SizedBox(height: 20),

            if (loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator()))
            else ...[
              if (error != null) ...[
                ErrorNotice(error!),
                const SizedBox(height: 12),
              ],

              // 1. University
              Label('University', color: c.secondary),
              const SizedBox(height: 6),
              DropdownButtonFormField<University>(
                value: selectedUniversity,
                isExpanded: true,
                items: universities
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(u.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (u) {
                  if (u != null) _onUniversityChanged(u);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(CupertinoIcons.building_2_fill, size: 18),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Department
              Label('Department', color: c.secondary),
              const SizedBox(height: 6),
              DropdownButtonFormField<Department>(
                value: selectedDept,
                isExpanded: true,
                items: departments
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (d) {
                  if (d != null) _onDeptChanged(d);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(CupertinoIcons.folder, size: 18),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Batch
              Label('Batch', color: c.secondary),
              const SizedBox(height: 8),
              if (batches.isEmpty)
                Text('No batches available', style: TextStyle(color: c.secondary, fontSize: 12))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: batches
                      .map(
                        (b) => ChoiceChip(
                          label: Text(b.label),
                          selected: selectedBatch?.id == b.id,
                          onSelected: (_) => _onBatchChanged(b),
                          selectedColor: c.amber,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedBatch?.id == b.id ? FontWeight.bold : FontWeight.normal,
                            color: selectedBatch?.id == b.id ? Colors.white : c.ink,
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 16),

              // 4. Section
              Label('Section', color: c.secondary),
              const SizedBox(height: 8),
              if (sections.isEmpty)
                Text('No sections available', style: TextStyle(color: c.secondary, fontSize: 12))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: sections
                      .map(
                        (s) => ChoiceChip(
                          label: Text(s.label),
                          selected: selectedSection?.id == s.id,
                          onSelected: (_) => setState(() => selectedSection = s),
                          selectedColor: c.amber,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedSection?.id == s.id ? FontWeight.bold : FontWeight.normal,
                            color: selectedSection?.id == s.id ? Colors.white : c.ink,
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 20),

              // Current Selection Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.subtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info_circle, size: 18, color: c.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target: ${selectedUniversity?.name ?? "-"} ➔ ${selectedDept?.name ?? "-"} ➔ ${selectedBatch?.label ?? "-"} ➔ ${selectedSection?.label ?? "-"}',
                        style: context.type.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              FilledButton(
                onPressed: selectedSection != null ? _applySwitch : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: c.amber,
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.checkmark_shield, size: 18),
                    SizedBox(width: 8),
                    Text('Manage Selected Section', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
