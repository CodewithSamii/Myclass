import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/format.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/schedule_bloc.dart';

class RoutineEditor extends StatefulWidget {
  const RoutineEditor({super.key, required this.session});
  final ClassSession session;
  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor> {
  late ClassSession draft = widget.session;
  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ScheduleBloc, ScheduleState>(
        listenWhen: (a, b) => a.saving && !b.saving,
        listener: (c, s) {
          if (s.error == null) {
            feedback(context, 'Routine updated.');
            Navigator.pop(context);
          }
        },
        builder: (c, s) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit repeating class', style: context.type.headlineSmall),
              const SizedBox(height: 10),
              Text(
                s.course(draft.courseId).name,
                style: context.type.bodyLarge?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              FieldLabel(
                'Day',
                DropdownButtonFormField<int>(
                  initialValue: draft.weekday,
                  items: [
                    for (var i = 1; i <= 7; i++)
                      DropdownMenuItem(value: i, child: Text(Fmt.days[i - 1])),
                  ],
                  onChanged: (v) =>
                      setState(() => draft = draft.copyWith(weekday: v)),
                ),
              ),
              SettingsRow(
                'Starts',
                subtitle: Fmt.minute(draft.startMinute),
                icon: CupertinoIcons.clock,
                onTap: () => _time(true),
              ),
              SettingsRow(
                'Ends',
                subtitle: Fmt.minute(draft.endMinute),
                icon: CupertinoIcons.clock,
                onTap: () => _time(false),
              ),
              const SizedBox(height: 12),
              FieldLabel(
                'Room',
                TextFormField(
                  initialValue: draft.room,
                  decoration: const InputDecoration(
                    hintText: 'Leave blank if unknown',
                  ),
                  onChanged: (v) => draft = draft.copyWith(room: v),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Cancel this repeating class',
                  style: context.type.bodyLarge,
                ),
                value: draft.cancelled,
                onChanged: (v) =>
                    setState(() => draft = draft.copyWith(cancelled: v)),
              ),
              Text(
                'This changes the weekly routine for the section.',
                style: context.type.bodySmall?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
              if (s.error != null) ...[
                const SizedBox(height: 12),
                ErrorNotice(s.error!),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                'Save routine',
                busy: s.saving,
                icon: CupertinoIcons.checkmark,
                onPressed: () => context.read<ScheduleBloc>().add(
                  RoutineSaveRequested(draft.copyWith(changed: true)),
                ),
              ),
            ],
          ),
        ),
      );
  Future<void> _time(bool start) async {
    final m = start ? draft.startMinute : draft.endMinute;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (t != null && mounted) {
      setState(
        () => draft = start
            ? draft.copyWith(startMinute: t.hour * 60 + t.minute)
            : draft.copyWith(endMinute: t.hour * 60 + t.minute),
      );
    }
  }
}
