import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/format.dart';
import '../../../core/clock_cubit.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../shared/widgets/academic_tiles.dart';
import '../../../shared/widgets/reminder_selector.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../../tasks/bloc/tasks_bloc.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../notes/bloc/notes_bloc.dart';
import '../../notes/views/note_editor.dart';
import '../../section_admin/views/event_editor_page.dart';
import '../bloc/events_bloc.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final es = context.watch<EventsBloc>().state;
    final e = es.byId(id);
    final now = context.watch<ClockCubit>().state;
    final profile = context.watch<ProfileBloc>().state.profile;
    final progress = context.watch<TasksBloc>().state.forEvent(id);
    final notes = context
        .watch<NotesBloc>()
        .state
        .items
        .where((n) => n.eventId == id)
        .toList();
    if (e == null) {
      return const DetailPage(
        title: 'Event',
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            'This event is no longer here.',
            'It may have been removed by your class representative.',
          ),
        ),
      );
    }
    final course = context.watch<ScheduleBloc>().state.course(e.courseId);
    final defaults = profile.reminders.forType(e.type);
    final offsets = progress.reminderOffsets ?? defaults;
    return DetailPage(
      title: e.type.label,
      actions: [
        if (profile.membership.canManage)
          PopupMenuButton<String>(
            tooltip: 'Manage event',
            icon: const Icon(CupertinoIcons.ellipsis),
            onSelected: (v) => _manage(context, e, v, now),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit event')),
              const PopupMenuItem(
                value: 'postpone',
                child: Text('Postpone / reschedule'),
              ),
              PopupMenuItem(
                value: e.status == EventStatus.cancelled ? 'restore' : 'cancel',
                child: Text(
                  e.status == EventStatus.cancelled
                      ? 'Restore event'
                      : 'Cancel event',
                ),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete event')),
            ],
          ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CourseBadge(course),
              EventStatusBadge(e, now: now),
            ],
          ),
          const SizedBox(height: 18),
          Text(e.title, style: context.type.headlineLarge),
          const SizedBox(height: 10),
          Text(
            course.name,
            style: context.type.bodyLarge?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 26),
          Surface(
            child: Column(
              children: [
                _detail(context, CupertinoIcons.calendar, Fmt.fullDate(e.date)),
                const SizedBox(height: 16),
                _detail(
                  context,
                  CupertinoIcons.clock,
                  e.deadline != null
                      ? Fmt.time(e.deadline!)
                      : e.startsAt != null
                      ? '${Fmt.time(e.startsAt!)}${e.endsAt != null ? ' – ${Fmt.time(e.endsAt!)}' : ''}'
                      : 'Time to be announced',
                ),
                if (e.deadline == null) ...[
                  const SizedBox(height: 16),
                  _detail(
                    context,
                    CupertinoIcons.location,
                    e.location == null || e.location!.isEmpty
                        ? 'Room to be announced'
                        : e.location!.startsWith('Room')
                        ? e.location!
                        : 'Room ${e.location!}',
                  ),
                ],
              ],
            ),
          ),
          if (e.status == EventStatus.cancelled) ...[
            const SizedBox(height: 16),
            const ErrorNotice(
              'This event has been cancelled. It is kept here so everyone can see what changed.',
            ),
          ] else if (e.status == EventStatus.postponed) ...[
            const SizedBox(height: 16),
            Surface(
              color: context.colors.amberBg,
              border: false,
              child: Text(
                'Postponed. The date above is the revised schedule.',
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.amber,
                ),
              ),
            ),
          ],
          if (es.error != null) ...[
            const SizedBox(height: 16),
            ErrorNotice(es.error!),
          ],
          if (e.description.isNotEmpty) ...[
            const SectionHeader('About this event'),
            Text(e.description, style: context.type.bodyLarge),
          ],
          const SectionHeader('Syllabus'),
          if (e.syllabus.isEmpty)
            Text(
              'No syllabus shared yet. Check back for updates.',
              style: context.type.bodyMedium?.copyWith(
                color: context.colors.secondary,
              ),
            )
          else
            _Syllabus(items: e.syllabus),
          if (e.instructions.isNotEmpty) ...[
            const SectionHeader('Instructions'),
            Text(
              e.instructions,
              style: context.type.bodyLarge?.copyWith(height: 1.65),
            ),
          ],
          if (e.attachments.isNotEmpty) ...[
            SectionHeader(
              'Attachments',
              trailing: Text(
                '${e.attachments.length} ${e.attachments.length == 1 ? 'file' : 'files'}',
                style: context.type.bodySmall?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ),
            for (final a in e.attachments)
              AttachmentTile(
                a,
                onTap: () =>
                    openPage(context, AttachmentPreviewPage(attachment: a)),
              ),
          ],
          const SectionHeader('Make it yours'),
          Surface(
            child: Column(
              children: [
                SettingsRow(
                  'Remind me',
                  subtitle:
                      '${Fmt.offsets(offsets)}${progress.reminderOffsets == null ? ' · Default' : ''}',
                  icon: CupertinoIcons.bell,
                  onTap: () async {
                    final bloc = context.read<TasksBloc>();
                    final selection = await openSheet<ReminderChoice>(
                      context,
                      ReminderSelector(selected: offsets, defaults: defaults),
                    );
                    if (selection != null && !bloc.isClosed) {
                      bloc.add(
                        EventRemindersChanged(
                          id,
                          selection.inherit ? null : selection.offsets,
                        ),
                      );
                    }
                  },
                ),
                const Divider(),
                SettingsRow(
                  progress.completed
                      ? 'Preparation complete'
                      : 'Mark my preparation done',
                  subtitle: 'Only changes your personal progress',
                  icon: progress.completed
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  onTap: e.status == EventStatus.cancelled
                      ? null
                      : () => context.read<TasksBloc>().add(TaskToggled(id)),
                  trailing: progress.completed
                      ? Icon(
                          CupertinoIcons.checkmark,
                          size: 17,
                          color: context.colors.sage,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (e.suggestedReminders != null)
            SettingsRow(
              'Section reminder suggestion',
              subtitle: Fmt.offsets(e.suggestedReminders!),
              icon: CupertinoIcons.bell,
              onTap: () => context.read<TasksBloc>().add(
                EventRemindersChanged(id, e.suggestedReminders),
              ),
              trailing: Text('Use', style: context.type.labelMedium),
            ),
          SectionHeader(
            'Personal note',
            trailing: Icon(
              CupertinoIcons.lock,
              size: 14,
              color: context.colors.faint,
            ),
            action: notes.isEmpty ? 'Add' : 'Edit',
            onAction: () => openSheet(
              context,
              NoteEditor(note: notes.firstOrNull, eventId: id),
            ),
          ),
          if (notes.isEmpty)
            Text(
              'Only you can see notes added here.',
              style: context.type.bodyMedium?.copyWith(
                color: context.colors.secondary,
              ),
            )
          else
            for (final note in notes)
              Surface(
                onTap: () =>
                    openSheet(context, NoteEditor(note: note, eventId: id)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.text, style: context.type.bodyLarge),
                    if (note.remindAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Reminder · ${Fmt.fullDate(note.remindAt!)} · ${Fmt.time(note.remindAt!)}',
                        style: context.type.bodySmall?.copyWith(
                          color: context.colors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          if (e.changeHistory.isNotEmpty) ...[
            const SectionHeader('What changed'),
            for (final h in e.changeHistory.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_2_squarepath,
                      size: 17,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.label, style: context.type.titleSmall),
                          const SizedBox(height: 5),
                          Text(
                            '${h.before} → ${h.after}',
                            style: context.type.bodyMedium?.copyWith(
                              color: context.colors.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${h.author} · ${Fmt.date(h.at)}',
                            style: context.type.bodySmall?.copyWith(
                              color: context.colors.faint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 30),
          Text(
            'Shared by ${e.createdBy.toLowerCase()} · Updated ${Fmt.date(e.updatedAt)}',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.faint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(BuildContext c, IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 18, color: c.colors.secondary),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: c.type.bodyLarge)),
    ],
  );
  Future<void> _manage(
    BuildContext context,
    AcademicEvent e,
    String action,
    DateTime now,
  ) async {
    final bloc = context.read<EventsBloc>();
    if (action == 'edit' || action == 'postpone') {
      openPage(
        context,
        EventEditorPage(event: e, postpone: action == 'postpone'),
      );
      return;
    }
    final approved = await confirmAction(
      context,
      title: action == 'delete'
          ? 'Delete this event?'
          : action == 'restore'
          ? 'Restore this event?'
          : 'Cancel this event?',
      message: action == 'delete'
          ? 'This removes the event from the section. Cancel it instead if students need to see its history.'
          : action == 'restore'
          ? 'The event will return to the section schedule.'
          : 'Everyone will still see the event, clearly marked as cancelled.',
      confirm: action == 'delete'
          ? 'Delete'
          : action == 'restore'
          ? 'Restore'
          : 'Cancel event',
    );
    if (!approved || bloc.isClosed) return;
    if (action == 'delete') {
      bloc.add(EventDeleteRequested(e.id));
    } else {
      bloc.add(
        EventStatusRequested(
          e,
          action == 'restore' ? EventStatus.updated : EventStatus.cancelled,
          now,
        ),
      );
    }
  }
}

class _Syllabus extends StatefulWidget {
  const _Syllabus({required this.items});
  final List<String> items;
  @override
  State<_Syllabus> createState() => _SyllabusState();
}

class _SyllabusState extends State<_Syllabus> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: Motion.normal,
    alignment: Alignment.topCenter,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final text in widget.items.take(
          expanded ? widget.items.length : 5,
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.faint,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: context.type.bodyLarge)),
              ],
            ),
          ),
        if (widget.items.length > 5)
          TextButton(
            onPressed: () => setState(() => expanded = !expanded),
            child: Text(
              expanded
                  ? 'Show less'
                  : 'Show ${widget.items.length - 5} more topics',
            ),
          ),
      ],
    ),
  );
}

class AttachmentPreviewPage extends StatelessWidget {
  const AttachmentPreviewPage({super.key, required this.attachment});
  final Attachment attachment;
  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'Attachment',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          attachment.kind == AttachmentKind.image
              ? CupertinoIcons.photo
              : CupertinoIcons.doc_text,
          size: 32,
          color: context.colors.secondary,
        ),
        const SizedBox(height: 20),
        Text(attachment.name, style: context.type.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${attachment.kind.name.toUpperCase()} · ${attachment.sizeLabel} · Sample preview',
          style: context.type.bodySmall?.copyWith(
            color: context.colors.secondary,
          ),
        ),
        const SizedBox(height: 26),
        Surface(
          padding: const EdgeInsets.all(24),
          child: Text(
            attachment.preview,
            style: context.type.bodyLarge?.copyWith(height: 1.8),
          ),
        ),
      ],
    ),
  );
}
