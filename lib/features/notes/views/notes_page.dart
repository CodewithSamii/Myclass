import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/format.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../events/bloc/events_bloc.dart';
import '../bloc/notes_bloc.dart';
import 'note_editor.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<NotesBloc>().state;
    final events = context.watch<EventsBloc>().state;
    return DetailPage(
      title: 'Personal notes',
      actions: [
        IconButton(
          tooltip: 'New private note',
          onPressed: () => openSheet(context, const NoteEditor()),
          icon: const Icon(CupertinoIcons.add, size: 23),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('A little off your mind.', style: context.type.headlineMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                CupertinoIcons.lock,
                size: 13,
                color: context.colors.secondary,
              ),
              const SizedBox(width: 7),
              Text(
                'Only you can see these.',
                style: context.type.bodyMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          if (s.error != null) ...[
            ErrorNotice(s.error!),
            const SizedBox(height: 14),
          ],
          if (s.items.isEmpty)
            EmptyState(
              'No personal notes yet.',
              'Keep the small things from slipping away.',
              icon: CupertinoIcons.square_pencil,
              action: 'Write a note',
              onAction: () => openSheet(context, const NoteEditor()),
            )
          else
            for (final note in s.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Surface(
                  onTap: () => openSheet(context, NoteEditor(note: note)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              note.text,
                              style: context.type.bodyLarge?.copyWith(
                                decoration: note.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: note.completed
                                    ? context.colors.secondary
                                    : context.colors.ink,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Note actions',
                            icon: Icon(
                              CupertinoIcons.ellipsis,
                              size: 17,
                              color: context.colors.secondary,
                            ),
                            onSelected: (v) async {
                              final bloc = context.read<NotesBloc>();
                              if (v == 'complete') {
                                bloc.add(NoteToggled(note));
                              } else if (await confirmAction(
                                context,
                                title: 'Delete this note?',
                                message: 'This private note will be removed.',
                                confirm: 'Delete',
                              )) {
                                if (!bloc.isClosed) {
                                  bloc.add(NoteDeleted(note.id));
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'complete',
                                child: Text(
                                  note.completed
                                      ? 'Mark incomplete'
                                      : 'Mark done',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete note'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (note.eventId != null) ...[
                        const SizedBox(height: 10),
                        Badge(
                          events.byId(note.eventId!)?.title ??
                              'Linked academic event',
                          icon: CupertinoIcons.link,
                        ),
                      ],
                      if (note.remindAt != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.bell,
                              size: 13,
                              color: context.colors.amber,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${Fmt.fullDate(note.remindAt!)} · ${Fmt.time(note.remindAt!)}',
                                style: context.type.bodySmall?.copyWith(
                                  color: context.colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
