import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../core/format.dart';
import '../../../core/clock.dart';
import '../../../core/clock_cubit.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../shared/widgets/selector.dart';
import '../../../shared/widgets/reminder_selector.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../bloc/event_editor_bloc.dart';

class EventEditorPage extends StatelessWidget {
  const EventEditorPage({
    super.key,
    this.event,
    this.postpone = false,
    this.initialDate,
    this.initialCourseId,
  });
  final AcademicEvent? event;
  final bool postpone;
  final DateTime? initialDate;
  final String? initialCourseId;

  @override
  Widget build(BuildContext context) {
    final p = context.read<ProfileBloc>().state.profile;
    final now = context.read<ClockCubit>().state;
    final targetDate = initialDate ?? dateOnly(now.add(const Duration(days: 1)));
    final scheduleState = context.read<ScheduleBloc>().state;
    final cs = scheduleState.courses;
    final daySessions = scheduleState.sessions
        .where((s) => s.weekday == targetDate.weekday)
        .toList();

    final defaultCourseId = initialCourseId ??
        (daySessions.isNotEmpty
            ? daySessions.first.courseId
            : (cs.isNotEmpty ? cs.first.id : ''));

    if (!p.membership.canManage) {
      return const DetailPage(
        title: 'Section access',
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            'Representative access needed.',
            'Only authorized section representatives can edit shared events.',
          ),
        ),
      );
    }
    return BlocProvider(
      create: (c) => EventEditorBloc(
        repository: c.read<EventRepository>(),
        now: now,
        original: event,
        postpone: postpone,
        draft:
            event ??
            AcademicEvent(
              id: 'event-${DateTime.now().microsecondsSinceEpoch}',
              title: '',
              type: AcademicEventType.assignment,
              courseId: defaultCourseId,
              date: targetDate,
              deadline: DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59),
              sectionId: p.activeSectionId,
              createdAt: now,
              updatedAt: now,
              createdBy: p.name,
            ),
      ),
      child: _EditorContent(editing: event != null, postpone: postpone),
    );
  }
}

class _EditorContent extends StatelessWidget {
  const _EditorContent({required this.editing, required this.postpone});
  final bool editing, postpone;
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<EventEditorBloc, EventEditorState>(
    listenWhen: (a, b) => !a.saved && b.saved,
    listener: (context, s) {
      HapticFeedback.lightImpact();
      feedback(
        context,
        editing
            ? 'Event updated for your section.'
            : 'Event added to your section.',
      );
      Navigator.pop(context);
    },
    builder: (context, s) {
      final b = context.read<EventEditorBloc>();
      final d = s.draft;
      final courses = context.read<ScheduleBloc>().state.courses;
      final course = courses.where((c) => c.id == d.courseId).firstOrNull;
      return DetailPage(
        title: postpone
            ? 'Reschedule event'
            : editing
            ? 'Edit event'
            : 'New academic event',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: Motion.normal,
                          height: 3,
                          margin: const EdgeInsets.only(right: 8),
                          color: i <= s.step
                              ? context.colors.ink
                              : context.colors.line,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ['Essentials', 'Details', 'Review'][i],
                          style: context.type.bodySmall?.copyWith(
                            color: i == s.step
                                ? context.colors.ink
                                : context.colors.faint,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              [
                'Make the important things clear.',
                'A little context helps.',
                'Ready for your section.',
              ][s.step],
              style: context.type.headlineSmall,
            ),
            const SizedBox(height: 24),
            if (s.error != null) ...[
              ErrorNotice(s.error!),
              const SizedBox(height: 20),
            ],
            if (s.step == 0) ...[
              FieldLabel(
                'Event type',
                Surface(
                  onTap: () async {
                    final value = await selectOption<AcademicEventType>(
                      context,
                      title: 'Event type',
                      options: Future.value(AcademicEventType.values),
                      label: (v) => v.label,
                      selected: d.type,
                    );
                    if (value != null && !b.isClosed) {
                      b.add(EditorChanged(EditorField.type, value));
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(child: Text(d.type.label)),
                      const Icon(CupertinoIcons.chevron_down, size: 14),
                    ],
                  ),
                ),
              ),
              FieldLabel(
                'Class / Routine Slot',
                Surface(
                  onTap: () async {
                    final daySessions = context
                        .read<ScheduleBloc>()
                        .state
                        .sessions
                        .where((s) => s.weekday == d.date.weekday)
                        .toList();

                    final availableCourses = daySessions.isNotEmpty
                        ? daySessions
                            .map((s) => courses.firstWhere(
                                  (c) => c.id == s.courseId,
                                  orElse: () => Course(
                                    id: s.courseId,
                                    name: s.courseId,
                                    facultyId: '',
                                    departmentId: '',
                                  ),
                                ))
                            .toSet()
                            .toList()
                        : courses;

                    final value = await selectOption<Course>(
                      context,
                      title: 'Select routine class',
                      options: Future.value(availableCourses),
                      label: (v) {
                        final session = daySessions.where((s) => s.courseId == v.id).firstOrNull;
                        if (session != null) {
                          final startStr = Fmt.minute(session.startMinute, suffix: false);
                          final endStr = Fmt.minute(session.endMinute);
                          return '${v.name} ($startStr–$endStr${session.room != null && session.room!.isNotEmpty ? " · ${session.room}" : ""})';
                        }
                        return v.name;
                      },
                      selected: course,
                    );
                    if (value != null && !b.isClosed) {
                      b.add(EditorChanged(EditorField.course, value.id));
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(child: Text(course?.name ?? 'Select routine class')),
                      const Icon(CupertinoIcons.chevron_down, size: 14),
                    ],
                  ),
                ),
              ),
              FieldLabel(
                'Title',
                TextFormField(
                  key: ValueKey('title-${d.id}'),
                  initialValue: d.title,
                  maxLength: 160,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (v) => b.add(EditorChanged(EditorField.title, v)),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Chapter 4 Assignment, Midterm Quiz',
                    counterText: '',
                  ),
                ),
              ),
              FieldLabel(
                'Date',
                Surface(
                  onTap: () async {
                    final scheduleBloc = context.read<ScheduleBloc>();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: d.date,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (date != null && !b.isClosed) {
                      b.add(EditorChanged(EditorField.date, date));
                      final nextSessions = scheduleBloc
                          .state
                          .sessions
                          .where((s) => s.weekday == date.weekday)
                          .toList();
                      if (nextSessions.isNotEmpty && !nextSessions.any((s) => s.courseId == d.courseId)) {
                        b.add(EditorChanged(EditorField.course, nextSessions.first.courseId));
                      }
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text(Fmt.fullDate(d.date))),
                      const Icon(CupertinoIcons.chevron_right, size: 13),
                    ],
                  ),
                ),
              ),
              FieldLabel(
                'Time',
                Surface(
                  onTap: () => _time(context, b, d),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.clock, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          d.startsAt == null && d.deadline == null
                              ? 'Time to be announced'
                              : Fmt.time(d.effectiveAt),
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right, size: 13),
                    ],
                  ),
                ),
              ),
              if (!d.type.isDeadline) ...[
                if (d.startsAt != null)
                  FieldLabel(
                    'End time',
                    Surface(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            d.endsAt ??
                                d.startsAt!.add(const Duration(hours: 1)),
                          ),
                        );
                        if (t != null && !b.isClosed) {
                          b.add(
                            EditorChanged(
                              EditorField.endTime,
                              t.hour * 60 + t.minute,
                            ),
                          );
                        }
                      },
                      child: Text(Fmt.time(d.endsAt ?? d.startsAt!)),
                    ),
                  ),
                TextButton(
                  onPressed: () => b.add(EditorChanged(EditorField.time, null)),
                  child: const Text('Time not confirmed yet'),
                ),
                const SizedBox(height: 12),
                FieldLabel(
                  'Room or location · Optional',
                  TextFormField(
                    initialValue: d.location,
                    onChanged: (v) =>
                        b.add(EditorChanged(EditorField.location, v)),
                    decoration: const InputDecoration(
                      hintText: 'Room 402, online, or leave blank',
                    ),
                  ),
                ),
              ],
            ] else if (s.step == 1) ...[
              FieldLabel(
                d.type == AcademicEventType.presentation
                    ? 'Topics · One per line'
                    : 'Syllabus · One topic per line',
                TextFormField(
                  initialValue: d.syllabus.join('\n'),
                  maxLines: 5,
                  onChanged: (v) =>
                      b.add(EditorChanged(EditorField.syllabus, v)),
                  decoration: const InputDecoration(
                    hintText: 'Add what students should prepare',
                  ),
                ),
              ),
              FieldLabel(
                'Instructions · Optional',
                TextFormField(
                  initialValue: d.instructions,
                  maxLines: 4,
                  onChanged: (v) =>
                      b.add(EditorChanged(EditorField.instructions, v)),
                  decoration: InputDecoration(
                    hintText: d.type.isDeadline
                        ? 'Submission format, naming, or group instructions'
                        : 'What should everyone know?',
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text('Attachments', style: context.type.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: () => _attach(context, b),
                    icon: const Icon(CupertinoIcons.paperclip, size: 16),
                    label: const Text('Add sample'),
                  ),
                ],
              ),
              for (final a in d.attachments)
                SettingsRow(
                  a.name,
                  subtitle: a.sizeLabel,
                  icon: CupertinoIcons.doc,
                  trailing: IconButton(
                    tooltip: 'Remove ${a.name}',
                    onPressed: () => b.add(
                      EditorChanged(EditorField.removeAttachment, a.id),
                    ),
                    icon: const Icon(CupertinoIcons.xmark, size: 15),
                  ),
                ),
              if (d.attachments.isEmpty)
                Text(
                  'Add a sample PDF, document, image or file.',
                  style: context.type.bodySmall?.copyWith(
                    color: context.colors.secondary,
                  ),
                ),
              const SizedBox(height: 22),
              SettingsRow(
                'Suggested reminders',
                subtitle: d.suggestedReminders == null
                    ? 'Use students’ personal defaults'
                    : Fmt.offsets(d.suggestedReminders!),
                icon: CupertinoIcons.bell,
                onTap: () async {
                  final value = await openSheet<ReminderChoice>(
                    context,
                    ReminderSelector(
                      selected:
                          d.suggestedReminders ??
                          context
                              .read<ProfileBloc>()
                              .state
                              .profile
                              .reminders
                              .forType(d.type),
                    ),
                  );
                  if (value != null && !b.isClosed) {
                    b.add(EditorChanged(EditorField.reminders, value.offsets));
                  }
                },
              ),
            ] else ...[
              Surface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Badge(d.type.label),
                    const SizedBox(height: 18),
                    Text(d.title, style: context.type.headlineSmall),
                    const SizedBox(height: 10),
                    Text(
                      course?.name ?? '',
                      style: context.type.bodyMedium?.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(Fmt.fullDate(d.date), style: context.type.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      d.startsAt == null && d.deadline == null
                          ? 'Time to be announced'
                          : Fmt.time(d.effectiveAt),
                      style: context.type.bodyLarge,
                    ),
                    if (d.location?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Location · ${d.location}',
                        style: context.type.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      '${d.syllabus.length} syllabus topics · ${d.attachments.length} attachments',
                      style: context.type.bodySmall?.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (d.instructions.isNotEmpty) ...[
                const SectionHeader('Instructions'),
                Text(d.instructions, style: context.type.bodyLarge),
              ],
              if (s.changes.isNotEmpty) ...[
                const SectionHeader('Changes students will see'),
                for (final change in s.changes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(change.label, style: context.type.titleSmall),
                        const SizedBox(height: 5),
                        Text(
                          '${change.before.isEmpty ? 'Not provided' : change.before} → ${change.after.isEmpty ? 'Removed' : change.after}',
                          style: context.type.bodyMedium?.copyWith(
                            color: context.colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              Text(
                'This is shared with your section. Personal notes and progress stay private.',
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              s.step == 2
                  ? (editing ? 'Save changes' : 'Add to section')
                  : 'Continue',
              busy: s.saving,
              onPressed: () =>
                  b.add(s.step == 2 ? EditorSubmitted() : EditorNext()),
              icon: s.step == 2
                  ? CupertinoIcons.checkmark
                  : CupertinoIcons.arrow_right,
            ),
            if (s.step > 0)
              Center(
                child: TextButton(
                  onPressed: s.saving ? null : () => b.add(EditorBack()),
                  child: const Text('Back'),
                ),
              ),
          ],
        ),
      );
    },
  );
  Future<void> _time(
    BuildContext context,
    EventEditorBloc b,
    AcademicEvent d,
  ) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(d.effectiveAt),
    );
    if (t != null && !b.isClosed) {
      b.add(EditorChanged(EditorField.time, t.hour * 60 + t.minute));
    }
  }

  Future<void> _attach(BuildContext context, EventEditorBloc b) async {
    final attachment = await openSheet<Attachment>(
      context,
      const _AttachmentCreatorSheet(),
    );
    if (attachment != null && !b.isClosed) {
      b.add(EditorChanged(EditorField.attachment, attachment));
    }
  }
}

class _AttachmentCreatorSheet extends StatefulWidget {
  const _AttachmentCreatorSheet();
  @override
  State<_AttachmentCreatorSheet> createState() => _AttachmentCreatorSheetState();
}

class _AttachmentCreatorSheetState extends State<_AttachmentCreatorSheet> {
  AttachmentKind kind = AttachmentKind.pdf;
  final TextEditingController nameController = TextEditingController(text: 'Assignment Brief.pdf');
  String sizeLabel = '1.4 MB';

  void _selectKind(AttachmentKind k, String defaultName) {
    setState(() {
      kind = k;
      nameController.text = defaultName;
      sizeLabel = switch (k) {
        AttachmentKind.pdf => '1.4 MB',
        AttachmentKind.image => '850 KB',
        AttachmentKind.document => '320 KB',
        AttachmentKind.file => '3.8 MB',
      };
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attach File to Event', style: context.type.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Support JPG, JPEG, PNG, PDF, Word documents, and archives.',
            style: context.type.bodySmall?.copyWith(color: c.secondary),
          ),
          const SizedBox(height: 18),
          Label('File Format', color: c.secondary),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _formatChip(
                label: 'PDF Document (.pdf)',
                icon: CupertinoIcons.doc_text,
                selected: kind == AttachmentKind.pdf,
                onTap: () => _selectKind(AttachmentKind.pdf, 'Assignment Brief.pdf'),
              ),
              _formatChip(
                label: 'PNG Image (.png)',
                icon: CupertinoIcons.photo,
                selected: kind == AttachmentKind.image && nameController.text.endsWith('.png'),
                onTap: () => _selectKind(AttachmentKind.image, 'Reference Diagram.png'),
              ),
              _formatChip(
                label: 'JPG Image (.jpg)',
                icon: CupertinoIcons.photo,
                selected: kind == AttachmentKind.image && (nameController.text.endsWith('.jpg') || nameController.text.endsWith('.jpeg')),
                onTap: () => _selectKind(AttachmentKind.image, 'Class Board Notes.jpg'),
              ),
              _formatChip(
                label: 'Document (.docx)',
                icon: CupertinoIcons.doc,
                selected: kind == AttachmentKind.document,
                onTap: () => _selectKind(AttachmentKind.document, 'Project Guidelines.docx'),
              ),
              _formatChip(
                label: 'Archive / Zip (.zip)',
                icon: CupertinoIcons.archivebox,
                selected: kind == AttachmentKind.file,
                onTap: () => _selectKind(AttachmentKind.file, 'Lab Resources.zip'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Label('File Name', color: c.secondary),
          const SizedBox(height: 6),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter file name (e.g. Syllabus.pdf)',
              prefixIcon: Icon(CupertinoIcons.paperclip, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            'Attach File',
            icon: CupertinoIcons.checkmark,
            onPressed: () {
              final raw = nameController.text.trim();
              if (raw.isEmpty) return;
              Navigator.of(context).pop(
                Attachment(
                  id: 'attachment-${DateTime.now().microsecondsSinceEpoch}',
                  name: raw,
                  kind: kind,
                  sizeLabel: sizeLabel,
                  preview:
                      'ATTACHMENT: $raw\n\nKind: ${kind.name.toUpperCase()} · Size: $sizeLabel\n\nThis file is attached to this academic event for your classroom section.',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _formatChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return ChoiceChip(
      avatar: Icon(icon, size: 15, color: selected ? c.canvas : c.ink),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.ink,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? c.canvas : c.ink,
      ),
    );
  }
}
