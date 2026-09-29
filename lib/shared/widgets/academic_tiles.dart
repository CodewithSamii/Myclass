import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import '../../core/models.dart';
import '../../core/format.dart';
import '../../design_system/tokens.dart';
import '../../features/home/models/agenda_projection.dart';
import 'primitives.dart';

IconData eventIcon(AcademicEventType type) => switch (type) {
  AcademicEventType.viva => CupertinoIcons.mic,
  AcademicEventType.exam ||
  AcademicEventType.labExam => CupertinoIcons.doc_text_search,
  AcademicEventType.presentation => CupertinoIcons.rectangle_on_rectangle,
  AcademicEventType.quiz ||
  AcademicEventType.classTest => CupertinoIcons.pencil_circle,
  AcademicEventType.general => CupertinoIcons.calendar,
  _ => CupertinoIcons.doc_text,
};

class EventStatusBadge extends StatelessWidget {
  const EventStatusBadge(this.event, {super.key, required this.now});
  final AcademicEvent event;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final label = event.statusAt(now);
    final cancelled = event.status == EventStatus.cancelled;
    final attention =
        event.status == EventStatus.postponed || label == 'Deadline passed';
    return Badge(
      label,
      color: cancelled
          ? context.colors.red
          : attention
          ? context.colors.amber
          : context.colors.sage,
      background: cancelled
          ? context.colors.redBg
          : attention
          ? context.colors.amberBg
          : context.colors.sageBg,
    );
  }
}

class AcademicEventTile extends StatelessWidget {
  const AcademicEventTile({
    super.key,
    required this.event,
    required this.course,
    required this.now,
    required this.onTap,
    this.completed = false,
    this.onComplete,
    this.dense = false,
  });
  final AcademicEvent event;
  final Course course;
  final DateTime now;
  final VoidCallback onTap;
  final bool completed, dense;
  final VoidCallback? onComplete;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 12 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onComplete != null)
              SizedBox(
                width: 42,
                height: 44,
                child: IconButton(
                  tooltip: completed
                      ? 'Mark preparation incomplete'
                      : 'Mark my preparation complete',
                  padding: const EdgeInsets.only(right: 14),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onComplete!();
                  },
                  icon: AnimatedSwitcher(
                    duration: Motion.fast,
                    child: Icon(
                      completed
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      key: ValueKey(completed),
                      size: 23,
                      color: completed ? c.sage : c.faint,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 12),
                child: Icon(
                  eventIcon(event.type),
                  size: 19,
                  color: c.secondary,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.titleMedium?.copyWith(
                      color: completed ? c.secondary : c.ink,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    course.compactName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.bodyMedium?.copyWith(
                      color: c.secondary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${Fmt.relativeDay(event.date, now)}${event.deadline != null
                            ? ' · ${Fmt.time(event.deadline!)}'
                            : event.startsAt != null
                            ? ' · ${Fmt.time(event.startsAt!)}'
                            : ' · Time TBA'}',
                        style: context.type.bodySmall?.copyWith(
                          color: event.passed(now)
                              ? c.red
                              : now
                                    .add(const Duration(days: 1))
                                    .isAfter(event.effectiveAt)
                              ? c.amber
                              : c.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (event.status != EventStatus.scheduled)
                        EventStatusBadge(event, now: now)
                      else
                        Badge(event.type.label),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 12,
                color: c.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.entry,
    required this.now,
    required this.onTap,
    this.last = false,
    this.conflict = false,
  });
  final AgendaEntry entry;
  final DateTime now;
  final VoidCallback onTap;
  final bool last, conflict;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final important = entry.event != null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: MediaQuery.textScalerOf(context).scale(48).clamp(48, 68),
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.timeLabel,
                    style: context.type.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.secondary,
                    ),
                  ),
                  Text(
                    entry.timeUnknown
                        ? ''
                        : entry.at.hour < 12
                        ? 'AM'
                        : 'PM',
                    style: context.type.bodySmall?.copyWith(color: c.faint),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.cancelled
                        ? c.faint
                        : important
                        ? c.amber
                        : c.sage,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.only(top: 4),
                      color: c.line,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Surface(
                onTap: onTap,
                border: important,
                color: important ? c.surface : Colors.transparent,
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.deadline) ...[
                      Label('Due today', color: c.amber),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      entry.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.titleMedium?.copyWith(
                        decoration: entry.cancelled
                            ? TextDecoration.lineThrough
                            : null,
                        color: entry.cancelled ? c.faint : c.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.deadline
                          ? entry.course.compactName
                          : entry.timeUnknown
                          ? 'Time and room will be announced'
                          : '${entry.location.startsWith('Room') || entry.location.startsWith('Lab') ? entry.location : 'Room ${entry.location}'}${entry.end != null ? ' · Until ${Fmt.time(entry.end!)}' : ''}',
                      style: context.type.bodySmall?.copyWith(
                        color: c.secondary,
                      ),
                    ),
                    if (entry.cancelled ||
                        entry.event?.status == EventStatus.postponed) ...[
                      const SizedBox(height: 8),
                      Badge(
                        entry.cancelled ? 'Cancelled' : 'Postponed',
                        color: entry.cancelled ? c.red : c.amber,
                        background: entry.cancelled ? c.redBg : c.amberBg,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CourseBadge extends StatelessWidget {
  const CourseBadge(this.course, {super.key});
  final Course course;
  @override
  Widget build(BuildContext context) =>
      Badge(course.code ?? course.compactName);
}

class AttachmentTile extends StatelessWidget {
  const AttachmentTile(this.attachment, {super.key, required this.onTap});
  final Attachment attachment;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SettingsRow(
    attachment.name,
    subtitle: '${attachment.kind.name.toUpperCase()} · ${attachment.sizeLabel}',
    icon: attachment.kind == AttachmentKind.image
        ? CupertinoIcons.photo
        : CupertinoIcons.doc,
    onTap: onTap,
    trailing: Icon(
      CupertinoIcons.arrow_up_right,
      size: 16,
      color: context.colors.secondary,
    ),
  );
}
