import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/format.dart';
import '../../../core/clock.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/schedule_bloc.dart';

class ShiftClassSheet extends StatefulWidget {
  const ShiftClassSheet({
    super.key,
    required this.session,
    required this.sourceDate,
  });

  final ClassSession session;
  final DateTime sourceDate;

  @override
  State<ShiftClassSheet> createState() => _ShiftClassSheetState();
}

class _ShiftClassSheetState extends State<ShiftClassSheet> {
  late DateTime targetDate = widget.sourceDate.add(const Duration(days: 2));
  late int startMinute = widget.session.startMinute;
  late int endMinute = widget.session.endMinute;
  late TextEditingController roomController;
  String? selectedSlotId;
  bool customTime = false;

  @override
  void initState() {
    super.initState();
    roomController = TextEditingController(text: widget.session.room ?? '');
  }

  @override
  void dispose() {
    roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ScheduleBloc>().state;
    final course = s.course(widget.session.courseId);
    final courseName = widget.session.customCourseName?.isNotEmpty == true
        ? widget.session.customCourseName!
        : course.name;

    return BlocConsumer<ScheduleBloc, ScheduleState>(
      listenWhen: (a, b) => a.saving && !b.saving,
      listener: (context, state) {
        if (state.error == null) {
          feedback(context, 'Class shifted to ${Fmt.shortDate(targetDate)}.');
          Navigator.pop(context, true);
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shift Class', style: context.type.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Move this class to another date or time without re-entering details.',
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
              const SizedBox(height: 18),

              // Existing Class Info Card
              Surface(
                color: context.colors.subtle,
                border: false,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(CupertinoIcons.calendar, size: 14, color: context.colors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Current: ${Fmt.fullDate(widget.sourceDate)} · ${Fmt.minute(widget.session.startMinute)}–${Fmt.minute(widget.session.endMinute)}',
                          style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const SectionHeader('Destination Schedule'),

              // Destination Date
              SettingsRow(
                'New Date',
                subtitle: Fmt.fullDate(targetDate),
                icon: CupertinoIcons.calendar_today,
                onTap: _pickDate,
              ),

              const SizedBox(height: 14),

              // Slot Selector or Custom Time
              if (s.timeSlots.isNotEmpty && !customTime) ...[
                FieldLabel(
                  'Select Slot',
                  DropdownButtonFormField<String>(
                    initialValue: selectedSlotId,
                    hint: const Text('Choose a time slot'),
                    items: [
                      for (final slot in s.timeSlots)
                        DropdownMenuItem(
                          value: slot.id,
                          child: Text(slot.display),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        final slot = s.timeSlots.firstWhere((t) => t.id == val);
                        setState(() {
                          selectedSlotId = val;
                          startMinute = slot.startMinute;
                          endMinute = slot.endMinute;
                        });
                      }
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => customTime = true),
                    child: const Text('Use unusual/custom time instead'),
                  ),
                ),
              ] else ...[
                SettingsRow(
                  'Start Time',
                  subtitle: Fmt.minute(startMinute),
                  icon: CupertinoIcons.clock,
                  onTap: () => _pickTime(true),
                ),
                SettingsRow(
                  'End Time',
                  subtitle: Fmt.minute(endMinute),
                  icon: CupertinoIcons.clock,
                  onTap: () => _pickTime(false),
                ),
                if (s.timeSlots.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => customTime = false),
                      child: const Text('Select from standard slots'),
                    ),
                  ),
              ],

              const SizedBox(height: 12),
              FieldLabel(
                'Room / Location',
                TextFormField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 402 or Leave blank',
                  ),
                ),
              ),

              if (state.error != null) ...[
                const SizedBox(height: 12),
                ErrorNotice(state.error!),
              ],

              const SizedBox(height: 24),
              PrimaryButton(
                'Confirm Shift',
                busy: state.saving,
                icon: CupertinoIcons.arrow_right_arrow_left,
                onPressed: () {
                  if (sameDay(targetDate, widget.sourceDate) &&
                      startMinute == widget.session.startMinute &&
                      endMinute == widget.session.endMinute) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a different date or time.')),
                    );
                    return;
                  }
                  context.read<ScheduleBloc>().add(
                    ShiftSessionRequested(
                      session: widget.session,
                      sourceDate: widget.sourceDate,
                      targetDate: targetDate,
                      newStartMinute: startMinute,
                      newEndMinute: endMinute,
                      newRoom: roomController.text.trim().isEmpty ? null : roomController.text.trim(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: targetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null && mounted) {
      setState(() => targetDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final m = isStart ? startMinute : endMinute;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (t != null && mounted) {
      setState(() {
        if (isStart) {
          startMinute = t.hour * 60 + t.minute;
          if (endMinute <= startMinute) {
            endMinute = startMinute + 60;
          }
        } else {
          endMinute = t.hour * 60 + t.minute;
        }
      });
    }
  }
}
