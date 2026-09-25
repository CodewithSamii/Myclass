import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/schedule_bloc.dart';

class TemporaryClassSheet extends StatefulWidget {
  const TemporaryClassSheet({
    super.key,
    required this.initialDate,
    this.sessionToEdit,
  });

  final DateTime initialDate;
  final ClassSession? sessionToEdit;

  @override
  State<TemporaryClassSheet> createState() => _TemporaryClassSheetState();
}

class _TemporaryClassSheetState extends State<TemporaryClassSheet> {
  late DateTime date;
  late int startMinute;
  late int endMinute;
  late bool isOnline;
  late TextEditingController courseController;
  late TextEditingController facultyController;
  late TextEditingController locationController;
  late TextEditingController notesController;
  String? selectedCourseId;
  String? selectedSlotId;
  bool customTime = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.sessionToEdit;
    date = edit?.specificDate ?? widget.initialDate;
    startMinute = edit?.startMinute ?? 9 * 60;
    endMinute = edit?.endMinute ?? (10 * 60 + 5);
    isOnline = edit?.isOnline ?? false;
    selectedCourseId = edit != null && !edit.courseId.startsWith('custom-') ? edit.courseId : null;
    courseController = TextEditingController(text: edit?.customCourseName ?? '');
    facultyController = TextEditingController(text: edit?.facultyName ?? '');
    locationController = TextEditingController(
      text: isOnline ? (edit?.meetingLink ?? '') : (edit?.room ?? ''),
    );
    notesController = TextEditingController(text: edit?.notes ?? '');
  }

  @override
  void dispose() {
    courseController.dispose();
    facultyController.dispose();
    locationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ScheduleBloc>().state;
    final isEditing = widget.sessionToEdit != null;

    return BlocConsumer<ScheduleBloc, ScheduleState>(
      listenWhen: (a, b) => a.saving && !b.saving,
      listener: (context, state) {
        if (state.error == null) {
          feedback(
            context,
            isEditing
                ? 'Temporary class updated.'
                : 'Temporary class scheduled and students notified.',
          );
          Navigator.pop(context, true);
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Temporary Class' : 'New Temporary Class',
                    style: context.type.headlineSmall,
                  ),
                  if (isEditing)
                    IconButton(
                      tooltip: 'Remove Temporary Class',
                      icon: Icon(CupertinoIcons.trash, color: context.colors.red, size: 20),
                      onPressed: () => _confirmDelete(context),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Add a one-time extra or makeup class. This does not change the repeating weekly routine.',
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
              const SizedBox(height: 20),

              // Date
              SettingsRow(
                'Class Date',
                subtitle: Fmt.fullDate(date),
                icon: CupertinoIcons.calendar_today,
                onTap: _pickDate,
              ),

              const SizedBox(height: 14),

              // Course Selection
              if (s.courses.isNotEmpty) ...[
                FieldLabel(
                  'Course',
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourseId,
                    hint: const Text('Select a registered course or custom'),
                    items: [
                      for (final c in s.courses)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      const DropdownMenuItem(
                        value: 'custom',
                        child: Text('+ Custom / Other Class Name'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedCourseId = val;
                        if (val != null && val != 'custom') {
                          final c = s.courses.firstWhere((item) => item.id == val);
                          courseController.text = c.name;
                        } else if (val == 'custom') {
                          courseController.clear();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (selectedCourseId == 'custom' || s.courses.isEmpty || selectedCourseId == null) ...[
                FieldLabel(
                  'Course / Class Name',
                  TextFormField(
                    controller: courseController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Extra Numerical Methods, Guest Lecture',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Faculty / Teacher Name
              FieldLabel(
                'Teacher / Faculty (Optional)',
                TextFormField(
                  controller: facultyController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dr. Rahman',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Slot Selector / Custom Time
              if (s.timeSlots.isNotEmpty && !customTime) ...[
                FieldLabel(
                  'Select Slot',
                  DropdownButtonFormField<String>(
                    initialValue: selectedSlotId,
                    hint: const Text('Choose a standard time slot'),
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
                  'Starts',
                  subtitle: Fmt.minute(startMinute),
                  icon: CupertinoIcons.clock,
                  onTap: () => _pickTime(true),
                ),
                SettingsRow(
                  'Ends',
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

              const SizedBox(height: 16),

              // Online / Offline Mode
              const Label('Format'),
              const SizedBox(height: 8),
              ChoiceBar<bool>(
                values: const [false, true],
                selected: isOnline,
                label: (v) => v ? 'Online Class' : 'In-Person / Offline',
                onChanged: (v) => setState(() => isOnline = v),
              ),

              const SizedBox(height: 14),

              // Location or Meeting Info
              FieldLabel(
                isOnline ? 'Online Meeting Link / Instructions' : 'Room / Location',
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(
                    hintText: isOnline
                        ? 'e.g. Google Meet / Zoom link or code'
                        : 'e.g. Room 402 or ACL-1',
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Additional Notes
              FieldLabel(
                'Instructions / Notes for Students',
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Please bring assignment prints, or attend with camera on.',
                  ),
                ),
              ),

              if (state.error != null) ...[
                const SizedBox(height: 12),
                ErrorNotice(state.error!),
              ],

              const SizedBox(height: 24),
              PrimaryButton(
                isEditing ? 'Save Changes' : 'Publish Temporary Class',
                busy: state.saving,
                icon: CupertinoIcons.checkmark_circle,
                onPressed: _saveTemporaryClass,
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveTemporaryClass() {
    final title = courseController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course or class name.')),
      );
      return;
    }
    if (endMinute <= startMinute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class end time must be after start time.')),
      );
      return;
    }

    final bloc = context.read<ScheduleBloc>();
    final sectionId = bloc.section;
    final sessionId = widget.sessionToEdit?.id ??
        'temp-${DateTime.now().microsecondsSinceEpoch}';

    final courseId = selectedCourseId != null && selectedCourseId != 'custom'
        ? selectedCourseId!
        : 'custom-${title.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}';

    final session = ClassSession(
      id: sessionId,
      sectionId: sectionId,
      courseId: courseId,
      weekday: date.weekday,
      startMinute: startMinute,
      endMinute: endMinute,
      room: isOnline ? null : locationController.text.trim(),
      isOnline: isOnline,
      meetingLink: isOnline ? locationController.text.trim() : null,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      specificDate: DateTime(date.year, date.month, date.day),
      isTemporary: true,
      customCourseName: title,
      facultyName: facultyController.text.trim().isEmpty ? null : facultyController.text.trim(),
    );

    bloc.add(TemporaryClassSaveRequested(session));
  }

  void _confirmDelete(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Remove Temporary Class'),
        content: const Text('Are you sure you want to delete this temporary class? Students will be notified.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ScheduleBloc>().add(
                TemporaryClassDeleteRequested(widget.sessionToEdit!.id),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null && mounted) {
      setState(() => date = picked);
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
