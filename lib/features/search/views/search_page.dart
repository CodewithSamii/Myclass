import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../events/bloc/events_bloc.dart';
import '../../events/views/event_detail_page.dart';
import '../../campus/bloc/campus_bloc.dart';
import '../../campus/views/bus_page.dart';
import '../../campus/views/faculty_page.dart';
import '../../notes/bloc/notes_bloc.dart';
import '../../notes/views/note_editor.dart';
import '../bloc/search_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final controller = TextEditingController(
    text: context.read<SearchBloc>().state.query,
  );
  @override
  void initState() {
    super.initState();
    final bloc = context.read<SearchBloc>();
    if (bloc.state.query.isNotEmpty) {
      bloc.add(SearchQueryChanged(bloc.state.query));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SearchBloc>().state;
    return DetailPage(
      title: 'Search',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            scrollPadding: const EdgeInsets.only(bottom: 100),
            onChanged: (v) =>
                context.read<SearchBloc>().add(SearchQueryChanged(v)),
            decoration: InputDecoration(
              hintText: 'Find anything in your space',
              prefixIcon: const Icon(CupertinoIcons.search, size: 20),
              suffixIcon: s.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        context.read<SearchBloc>().add(SearchQueryChanged(''));
                      },
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          if (s.phase == LoadPhase.initial) ...[
            Text('What are you looking for?', style: context.type.titleLarge),
            const SizedBox(height: 10),
            Text(
              'Events, courses, faculty, bus routes and your private notes.',
              style: context.type.bodyLarge?.copyWith(
                color: context.colors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in ['Viva', 'Database', 'Ishrar', 'Route 2'])
                  ActionChip(
                    label: Text(q),
                    onPressed: () {
                      controller.text = q;
                      context.read<SearchBloc>().add(SearchQueryChanged(q));
                    },
                  ),
              ],
            ),
          ] else if (s.phase == LoadPhase.loading)
            const Skeleton()
          else if (s.phase == LoadPhase.error)
            ErrorNotice(
              'Search is not available right now.',
              onRetry: () =>
                  context.read<SearchBloc>().add(SearchQueryChanged(s.query)),
            )
          else if (s.hits.isEmpty)
            EmptyState(
              'No results for “${s.query}”.',
              'Try a course name, event type, faculty member or route number.',
              icon: CupertinoIcons.search,
            )
          else
            for (final kind in SearchKind.values)
              if (s.hits.any((h) => h.kind == kind)) ...[
                SectionHeader(switch (kind) {
                  SearchKind.event => 'Academic events',
                  SearchKind.course => 'Courses',
                  SearchKind.faculty => 'Faculty',
                  SearchKind.bus => 'Bus routes',
                  SearchKind.note => 'Your private notes',
                }),
                for (final h in s.hits.where((h) => h.kind == kind))
                  SettingsRow(
                    h.title,
                    subtitle: h.subtitle,
                    icon: switch (kind) {
                      SearchKind.event => CupertinoIcons.calendar,
                      SearchKind.course => CupertinoIcons.doc_text,
                      SearchKind.faculty => CupertinoIcons.person,
                      SearchKind.bus => CupertinoIcons.bus,
                      SearchKind.note => CupertinoIcons.lock,
                    },
                    onTap: () => _open(context, h),
                  ),
              ],
        ],
      ),
    );
  }

  void _open(BuildContext context, SearchHit hit) {
    switch (hit.kind) {
      case SearchKind.event:
        openPage(context, EventDetailPage(id: hit.id));
      case SearchKind.course:
        final events = context
            .read<EventsBloc>()
            .state
            .items
            .where((e) => e.courseId == hit.id)
            .toList();
        openPage(
          context,
          DetailPage(
            title: hit.title,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Course activity', style: context.type.headlineSmall),
                const SizedBox(height: 20),
                if (events.isEmpty)
                  const EmptyState(
                    'No academic events yet.',
                    'New events for this course will appear here.',
                  ),
                for (final e in events)
                  SettingsRow(
                    e.title,
                    subtitle: e.type.label,
                    icon: CupertinoIcons.calendar,
                    onTap: () => openPage(context, EventDetailPage(id: e.id)),
                  ),
              ],
            ),
          ),
        );
      case SearchKind.faculty:
        final member = context
            .read<CampusBloc>()
            .state
            .faculty
            .where((f) => f.id == hit.id)
            .firstOrNull;
        if (member != null) {
          openPage(context, FacultyProfilePage(member: member));
        }
      case SearchKind.bus:
        final route = context
            .read<CampusBloc>()
            .state
            .routes
            .where((r) => r.id == hit.id)
            .firstOrNull;
        if (route != null) openPage(context, BusRouteDetailPage(route: route));
      case SearchKind.note:
        final note = context
            .read<NotesBloc>()
            .state
            .items
            .where((n) => n.id == hit.id)
            .firstOrNull;
        if (note != null) openSheet(context, NoteEditor(note: note));
    }
  }
}
