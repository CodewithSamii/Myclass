import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../demo/fixtures.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';

class SetRoutinePage extends StatefulWidget {
  const SetRoutinePage({super.key});

  @override
  State<SetRoutinePage> createState() => _SetRoutinePageState();
}

class _SetRoutinePageState extends State<SetRoutinePage> {
  // Days of week: Saturday (6), Sunday (7), Monday (1), Tuesday (2), Wednesday (3), Thursday (4), Friday (5)
  static const days = [
    (6, 'Saturday', 'Sat'),
    (7, 'Sunday', 'Sun'),
    (1, 'Monday', 'Mon'),
    (2, 'Tuesday', 'Tue'),
    (3, 'Wednesday', 'Wed'),
    (4, 'Thursday', 'Thu'),
    (5, 'Friday', 'Fri'),
  ];

  int selectedWeekday = 6; // starts on Saturday
  late List<ClassSession> sessions;
  late List<TimeSlot> slots;
  bool isDirty = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ScheduleBloc>().state;
    sessions = List.from(state.sessions);
    if (state.timeSlots.isNotEmpty) {
      slots = List.from(state.timeSlots);
    } else {
      slots = List.from(Fixtures.defaultTimeSlots);
    }
  }

  ClassSession? _sessionFor(int weekday, TimeSlot slot) {
    try {
      return sessions.firstWhere(
        (s) =>
            s.weekday == weekday &&
            ((s.startMinute >= slot.startMinute && s.startMinute < slot.endMinute) ||
                (s.startMinute == slot.startMinute)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _configureSlot(int weekday, TimeSlot slot, ClassSession? currentSession) async {
    final state = context.read<ScheduleBloc>().state;
    final courses = state.courses;
    final sectionId = context.read<ProfileBloc>().state.profile.activeSectionId;

    final roomController = TextEditingController(text: currentSession?.room ?? '402');
    bool isLab = currentSession?.isLab ?? false;
    String? selectedCourseId = currentSession?.courseId ?? (courses.isNotEmpty ? courses.first.id : null);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final c = ctx.colors;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assign Class (${slot.display})',
                        style: ctx.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Label('Select Subject / Course', color: c.secondary),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCourseId,
                        items: courses
                            .map((course) => DropdownMenuItem(
                                  value: course.id,
                                  child: Text('${course.code != null ? "${course.code} - " : ""}${course.compactName}'),
                                ))
                            .toList(),
                        onChanged: (id) => setSheetState(() => selectedCourseId = id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Label('Room Number', color: c.secondary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: roomController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 402 or Lab 2',
                      prefixIcon: Icon(CupertinoIcons.location, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Is this a Lab session?'),
                    value: isLab,
                    onChanged: (v) => setSheetState(() => isLab = v),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (currentSession != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop({'action': 'clear'}),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text('Set as Empty Slot'),
                          ),
                        ),
                      if (currentSession != null) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (selectedCourseId == null) return;
                            Navigator.of(ctx).pop({
                              'action': 'save',
                              'courseId': selectedCourseId,
                              'room': roomController.text.trim(),
                              'isLab': isLab,
                            });
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Assign Slot'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      // Remove any existing session for this day + slot
      sessions.removeWhere(
        (s) =>
            s.weekday == weekday &&
            ((s.startMinute >= slot.startMinute && s.startMinute < slot.endMinute) ||
                (s.startMinute == slot.startMinute)),
      );

      if (result['action'] == 'save') {
        final newSession = ClassSession(
          id: '$sectionId-$weekday-${slot.startMinute}',
          sectionId: sectionId,

          courseId: result['courseId'] as String,
          weekday: weekday,
          startMinute: slot.startMinute,
          endMinute: slot.endMinute,
          room: (result['room'] as String).isNotEmpty ? result['room'] as String : null,
          isLab: result['isLab'] as bool,
        );
        sessions.add(newSession);
      }
      isDirty = true;
    });
  }

  void _saveRoutine() {
    context.read<ScheduleBloc>().add(RoutineBulkSaveRequested(sessions));
    setState(() => isDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Routine updated and saved for all students!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<ScheduleBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set 7-Day Routine'),
        actions: [
          if (isDirty)
            TextButton(
              onPressed: _saveRoutine,
              child: const Text('Save Routine', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Day selector (Saturday to Friday)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: days.map((d) {
                  final selected = d.$1 == selectedWeekday;
                  final daySessionsCount = sessions.where((s) => s.weekday == d.$1).length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('${d.$3} ($daySessionsCount)'),
                      selected: selected,
                      onSelected: (_) => setState(() => selectedWeekday = d.$1),
                      selectedColor: c.hero,
                      labelStyle: TextStyle(
                        color: selected ? c.onHero : c.ink,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${days.firstWhere((d) => d.$1 == selectedWeekday).$2} Routine',
                      style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${sessions.where((s) => s.weekday == selectedWeekday).length} assigned classes',
                      style: context.type.bodySmall?.copyWith(color: c.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                for (final slot in slots) ...[
                  Builder(
                    builder: (ctx) {
                      final session = _sessionFor(selectedWeekday, slot);
                      final course = session != null ? state.course(session.courseId) : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Surface(
                          onTap: () => _configureSlot(selectedWeekday, slot, session),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Left: Slot time badge
                              Container(
                                width: 110,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: c.subtle,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(CupertinoIcons.clock, size: 14, color: c.secondary),
                                    const SizedBox(height: 4),
                                    Text(
                                      slot.display,
                                      style: context.type.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Right: Course assignment info or empty
                              Expanded(
                                child: session != null && course != null
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  course.name,
                                                  style: context.type.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (session.isLab)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: c.sageBg,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'LAB',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: c.sage,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Room: ${session.room ?? "TBA"}${course.code != null ? " · ${course.code}" : ""}',
                                            style: context.type.bodySmall?.copyWith(color: c.secondary),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Icon(CupertinoIcons.moon_zzz, size: 18, color: c.faint),
                                          const SizedBox(width: 8),
                                          Text(
                                            'No class (Empty Slot)',
                                            style: context.type.bodyMedium?.copyWith(
                                              color: c.faint,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              Icon(CupertinoIcons.pencil_circle, color: c.secondary, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isDirty ? _saveRoutine : null,
                  child: const Text('Save Routine Changes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
