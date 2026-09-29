import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../demo/fixtures.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/schedule_bloc.dart';
import '../../events/bloc/events_bloc.dart';
import '../../home/models/agenda_projection.dart';
import '../../section_admin/views/set_routine_page.dart';

enum _AdminStep {
  menu,
  selectClassForCancel,
  selectClassForShift,
  shiftRoutinePicker,
}

class AdminOptionsSheet extends StatefulWidget {
  const AdminOptionsSheet({super.key, required this.selectedDate});
  final DateTime selectedDate;

  @override
  State<AdminOptionsSheet> createState() => _AdminOptionsSheetState();
}

class _AdminOptionsSheetState extends State<AdminOptionsSheet> {
  _AdminStep _step = _AdminStep.menu;
  ClassSession? _sessionToShift;

  // Shift Routine Picker State
  late int _shiftWeekday;
  late DateTime _targetDate;
  String? _selectedSlotId;
  late int _startMinute;
  late int _endMinute;
  late TextEditingController _roomController;

  static const _daysOfWeek = [
    (DateTime.saturday, 'Saturday', 'Sat'),
    (DateTime.sunday, 'Sunday', 'Sun'),
    (DateTime.monday, 'Monday', 'Mon'),
    (DateTime.tuesday, 'Tuesday', 'Tue'),
    (DateTime.wednesday, 'Wednesday', 'Wed'),
    (DateTime.thursday, 'Thursday', 'Thu'),
    (DateTime.friday, 'Friday', 'Fri'),
  ];

  @override
  void initState() {
    super.initState();
    _roomController = TextEditingController();
    _shiftWeekday = widget.selectedDate.weekday;
    _targetDate = widget.selectedDate.add(const Duration(days: 7));
    _startMinute = 9 * 60;
    _endMinute = 10 * 60 + 5;
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _initShiftPicker(AgendaEntry entry) {
    final session = entry.session!;
    _sessionToShift = session;
    _roomController.text = session.room ?? '';
    _startMinute = session.startMinute;
    _endMinute = session.endMinute;

    // Target default: same weekday next week, or next upcoming day
    _shiftWeekday = session.weekday;
    _targetDate = widget.selectedDate.add(const Duration(days: 7));

    final state = context.read<ScheduleBloc>().state;
    final slots = state.timeSlots.isNotEmpty ? state.timeSlots : Fixtures.defaultTimeSlots;
    final matchingSlot = slots.where((s) => s.startMinute == session.startMinute).firstOrNull;
    _selectedSlotId = matchingSlot?.id ?? (slots.isNotEmpty ? slots.first.id : null);
    if (matchingSlot != null) {
      _startMinute = matchingSlot.startMinute;
      _endMinute = matchingSlot.endMinute;
    }

    setState(() => _step = _AdminStep.shiftRoutinePicker);
  }

  void _updateTargetDateForWeekday(int weekday) {
    _shiftWeekday = weekday;
    int diff = (weekday - widget.selectedDate.weekday) % 7;
    if (diff <= 0) diff += 7;
    setState(() {
      _targetDate = widget.selectedDate.add(Duration(days: diff));
    });
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<ScheduleBloc>().state;
    final es = context.watch<EventsBloc>().state;

    final entries = AgendaProjection.day(
      day: widget.selectedDate,
      sessions: ss.sessions,
      events: es.items,
      courses: ss.courses,
      periods: ss.periods,
    );
    final classEntries = entries.where((e) => e.session != null).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: AnimatedSwitcher(
        duration: Motion.fast,
        child: switch (_step) {
          _AdminStep.menu => _buildMenu(context, classEntries),
          _AdminStep.selectClassForCancel => _buildSelectClassForCancel(context, classEntries),
          _AdminStep.selectClassForShift => _buildSelectClassForShift(context, classEntries),
          _AdminStep.shiftRoutinePicker => _buildShiftRoutinePicker(context, ss),
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // VIEW: Main Admin Options Menu
  // -------------------------------------------------------------
  Widget _buildMenu(BuildContext context, List<AgendaEntry> classEntries) {
    final c = context.colors;
    return Column(
      key: const ValueKey('menu'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: c.sage),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Admin Options · ${Fmt.shortDate(widget.selectedDate)}',
                style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.xmark, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Manage classroom sessions and timetable for ${Fmt.fullDate(widget.selectedDate)}:',
          style: context.type.bodySmall?.copyWith(color: c.secondary),
        ),
        const SizedBox(height: 16),

        // Option 1: Cancel Class
        Surface(
          child: SettingsRow(
            'Cancel Class',
            subtitle: 'Cancel or reinstate a class scheduled for this date',
            icon: CupertinoIcons.clear_circled,
            onTap: () {
              if (classEntries.isEmpty) {
                feedback(context, 'No classes scheduled on ${Fmt.shortDate(widget.selectedDate)} to cancel.');
                return;
              }
              if (classEntries.length == 1) {
                _confirmCancelClass(context, classEntries.first);
              } else {
                setState(() => _step = _AdminStep.selectClassForCancel);
              }
            },
          ),
        ),
        const SizedBox(height: 10),

        // Option 2: Shift Class
        Surface(
          child: SettingsRow(
            'Shift Class',
            subtitle: 'Move a class & attached events to another date or slot',
            icon: CupertinoIcons.arrow_right_arrow_left,
            onTap: () {
              if (classEntries.isEmpty) {
                feedback(context, 'No classes scheduled on ${Fmt.shortDate(widget.selectedDate)} to shift.');
                return;
              }
              if (classEntries.length == 1) {
                _initShiftPicker(classEntries.first);
              } else {
                setState(() => _step = _AdminStep.selectClassForShift);
              }
            },
          ),
        ),
        const SizedBox(height: 10),

        // Option 3: Manage Routine (Left untouched as requested)
        Surface(
          child: SettingsRow(
            'Manage Routine',
            subtitle: 'Edit permanent weekly timetable for this section',
            icon: CupertinoIcons.calendar,
            onTap: () {
              Navigator.of(context).pop();
              openPage(context, const SetRoutinePage());
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // VIEW: Select Class for Cancel
  // -------------------------------------------------------------
  Widget _buildSelectClassForCancel(BuildContext context, List<AgendaEntry> classEntries) {
    final c = context.colors;
    return Column(
      key: const ValueKey('select_cancel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.chevron_left, size: 20),
              onPressed: () => setState(() => _step = _AdminStep.menu),
            ),
            Expanded(
              child: Text(
                'Cancel Class · Select Course',
                style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.xmark, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select the course you wish to cancel on ${Fmt.shortDate(widget.selectedDate)}:',
          style: context.type.bodySmall?.copyWith(color: c.secondary),
        ),
        const SizedBox(height: 14),
        for (final entry in classEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(
              child: SettingsRow(
                entry.course.name.isNotEmpty ? entry.course.name : 'Class slot',
                subtitle: '${Fmt.time(entry.at, suffix: false)}–${entry.end != null ? Fmt.time(entry.end!) : ""} · ${entry.cancelled ? "Currently Cancelled" : "Scheduled"}',
                icon: entry.cancelled ? CupertinoIcons.arrow_counterclockwise : CupertinoIcons.clear_circled,
                onTap: () => _confirmCancelClass(context, entry),
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // VIEW: Select Class for Shift
  // -------------------------------------------------------------
  Widget _buildSelectClassForShift(BuildContext context, List<AgendaEntry> classEntries) {
    final c = context.colors;
    return Column(
      key: const ValueKey('select_shift'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.chevron_left, size: 20),
              onPressed: () => setState(() => _step = _AdminStep.menu),
            ),
            Expanded(
              child: Text(
                'Shift Class · Select Course',
                style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.xmark, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select the course you want to shift to another day/slot:',
          style: context.type.bodySmall?.copyWith(color: c.secondary),
        ),
        const SizedBox(height: 14),
        for (final entry in classEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(
              child: SettingsRow(
                entry.course.name.isNotEmpty ? entry.course.name : 'Class slot',
                subtitle: '${Fmt.time(entry.at, suffix: false)}–${entry.end != null ? Fmt.time(entry.end!) : ""}',
                icon: CupertinoIcons.arrow_right_arrow_left,
                onTap: () => _initShiftPicker(entry),
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // VIEW: Existing Routine Selection UI for Shifting Class
  // -------------------------------------------------------------
  Widget _buildShiftRoutinePicker(BuildContext context, ScheduleState ss) {
    final c = context.colors;
    final session = _sessionToShift!;
    final course = ss.course(session.courseId);
    final courseName = session.customCourseName?.isNotEmpty == true
        ? session.customCourseName!
        : course.name;
    final slots = ss.timeSlots.isNotEmpty ? ss.timeSlots : Fixtures.defaultTimeSlots;

    return SingleChildScrollView(
      key: const ValueKey('routine_picker'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_left, size: 20),
                onPressed: () => setState(() => _step = _AdminStep.menu),
              ),
              Expanded(
                child: Text(
                  'Shift Class',
                  style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Retained Class Information Card
          Surface(
            color: c.subtle,
            border: false,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(CupertinoIcons.calendar, size: 13, color: c.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Current: ${Fmt.fullDate(widget.selectedDate)} · ${Fmt.minute(session.startMinute)}–${Fmt.minute(session.endMinute)}',
                        style: context.type.bodySmall?.copyWith(color: c.secondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Step 1: Preferred Day (Existing routine day selector style)
          Text(
            'PREFERRED DAY',
            style: context.type.labelSmall?.copyWith(
              color: c.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _daysOfWeek.map((d) {
                final selected = d.$1 == _shiftWeekday;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(d.$3),
                    selected: selected,
                    onSelected: (_) => _updateTargetDateForWeekday(d.$1),
                    showCheckmark: false,
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(CupertinoIcons.calendar_today, size: 14, color: c.sage),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Destination Date: ${Fmt.fullDate(_targetDate)}',
                  style: context.type.bodySmall?.copyWith(
                    color: c.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _pickCustomTargetDate,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text('Change Date'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step 1: Preferred Slot (Existing routine slot selection style)
          FieldLabel(
            'PREFERRED SLOT',
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedSlotId,
              hint: const Text('Choose a standard routine slot'),
              items: [
                for (final slot in slots)
                  DropdownMenuItem(
                    value: slot.id,
                    child: Text(slot.display),
                  ),
              ],
              onChanged: (val) {
                if (val != null) {
                  final slot = slots.firstWhere((s) => s.id == val);
                  setState(() {
                    _selectedSlotId = val;
                    _startMinute = slot.startMinute;
                    _endMinute = slot.endMinute;
                  });
                }
              },
            ),
          ),

          // Room Number / Location (Retained from original class, editable)
          FieldLabel(
            'ROOM / LOCATION (OPTIONAL)',
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(
                hintText: 'e.g. 402 or ACL-4',
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action Button to proceed to Confirmation
          PrimaryButton(
            'Continue to Confirmation',
            icon: CupertinoIcons.arrow_right,
            onPressed: () => _confirmShiftClass(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null && mounted) {
      setState(() {
        _targetDate = picked;
        _shiftWeekday = picked.weekday;
      });
    }
  }

  // -------------------------------------------------------------
  // Cancel Confirmation Dialog + Notification Toggle Flow
  // -------------------------------------------------------------
  Future<void> _confirmCancelClass(BuildContext context, AgendaEntry entry) async {
    bool notifyStudents = true;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text('Cancel Class'),
              content: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Are you sure you want to cancel this class?\n\n'
                      '${entry.course.name.isNotEmpty ? entry.course.name : "Class"} '
                      '(${Fmt.time(entry.at, suffix: false)}–${entry.end != null ? Fmt.time(entry.end!) : ""}) '
                      'on ${Fmt.shortDate(widget.selectedDate)}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notify students?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            notifyStudents ? 'Yes' : 'No',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: notifyStudents
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoSwitch(
                            value: notifyStudents,
                            onChanged: (val) {
                              setDialogState(() => notifyStudents = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel / No'),
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Confirm / Yes'),
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      context.read<ScheduleBloc>().add(
        CancelSessionOnDateRequested(
          session: entry.session!,
          date: widget.selectedDate,
          cancel: true,
          notifyStudents: notifyStudents,
        ),
      );
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            notifyStudents
                ? 'Class cancelled. Notification sent to students.'
                : 'Class cancelled. Notification skipped.',
          ),
        ),
      );
    }
  }

  // -------------------------------------------------------------
  // Shift Confirmation Dialog + Notification Toggle Flow
  // -------------------------------------------------------------
  Future<void> _confirmShiftClass(BuildContext context) async {
    final session = _sessionToShift!;
    final s = context.read<ScheduleBloc>().state;
    final course = s.course(session.courseId);
    final courseName = session.customCourseName?.isNotEmpty == true
        ? session.customCourseName!
        : course.name;

    bool notifyStudents = true;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text('Shift Class'),
              content: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Are you sure you want to shift this class to the selected day and slot?\n\n'
                      '$courseName\n'
                      'From: ${Fmt.weekday(widget.selectedDate)} (${Fmt.minute(session.startMinute)}–${Fmt.minute(session.endMinute)})\n'
                      'To: ${Fmt.weekday(_targetDate)} (${Fmt.minute(_startMinute)}–${Fmt.minute(_endMinute)}) on ${Fmt.shortDate(_targetDate)}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(ctx),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notify students?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            notifyStudents ? 'Yes' : 'No',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: notifyStudents
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoSwitch(
                            value: notifyStudents,
                            onChanged: (val) {
                              setDialogState(() => notifyStudents = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel / No'),
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Confirm / Yes'),
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      context.read<ScheduleBloc>().add(
        ShiftSessionRequested(
          session: session,
          sourceDate: widget.selectedDate,
          targetDate: _targetDate,
          newStartMinute: _startMinute,
          newEndMinute: _endMinute,
          newRoom: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
          notifyStudents: notifyStudents,
        ),
      );
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            notifyStudents
                ? 'Class shifted to ${Fmt.shortDate(_targetDate)}. Notification sent to students.'
                : 'Class shifted to ${Fmt.shortDate(_targetDate)}. Notification skipped.',
          ),
        ),
      );
    }
  }
}
