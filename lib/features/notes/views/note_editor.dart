import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/format.dart';
import '../../../core/clock_cubit.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/notes_bloc.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({super.key, this.note, this.eventId});
  final PersonalNote? note;
  final String? eventId;
  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final text = TextEditingController(text: widget.note?.text);
  late DateTime? reminder = widget.note?.remindAt;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<NotesBloc, NotesState>(
    listenWhen: (a, b) => b.saved > a.saved,
    listener: (c, s) {
      feedback(context, 'Private note saved.');
      Navigator.pop(context);
    },
    builder: (context, s) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.note == null
                      ? 'A note to yourself.'
                      : 'Edit your note',
                  style: context.type.headlineSmall,
                ),
              ),
              Icon(
                CupertinoIcons.lock,
                size: 17,
                color: context.colors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.eventId == null
                ? 'Private. Just for you.'
                : 'Linked to this event. Only you can see it.',
            style: context.type.bodyMedium?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: text,
            autofocus: false,
            scrollPadding: const EdgeInsets.only(bottom: 120),
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Something to remember…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SettingsRow(
            reminder == null
                ? 'Add a reminder'
                : '${Fmt.fullDate(reminder!)} · ${Fmt.time(reminder!)}',
            icon: CupertinoIcons.bell,
            onTap: () => _pickReminder(context),
            trailing: reminder == null
                ? null
                : IconButton(
                    tooltip: 'Remove reminder',
                    onPressed: () => setState(() => reminder = null),
                    icon: const Icon(CupertinoIcons.xmark, size: 14),
                  ),
          ),
          if (s.error != null) ...[
            const SizedBox(height: 12),
            ErrorNotice(s.error!),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            'Save note',
            busy: s.saving,
            icon: CupertinoIcons.checkmark,
            onPressed: () => context.read<NotesBloc>().add(
              NoteSaved(
                id: widget.note?.id,
                text: text.text,
                eventId: widget.eventId ?? widget.note?.eventId,
                remindAt: reminder,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> _pickReminder(BuildContext context) async {
    final now = context.read<ClockCubit>().state;
    final d = await showDatePicker(
      context: context,
      initialDate: reminder ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (d == null || !context.mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: reminder == null
          ? const TimeOfDay(hour: 10, minute: 0)
          : TimeOfDay.fromDateTime(reminder!),
    );
    if (t != null && mounted) {
      setState(
        () => reminder = DateTime(d.year, d.month, d.day, t.hour, t.minute),
      );
    }
  }
}
