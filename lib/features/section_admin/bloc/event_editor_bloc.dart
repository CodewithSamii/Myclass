import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../core/format.dart';

enum EditorField {
  title,
  type,
  course,
  date,
  time,
  endTime,
  location,
  syllabus,
  instructions,
  attachment,
  removeAttachment,
  reminders,
}

class EventEditorState extends Equatable {
  const EventEditorState({
    required this.draft,
    this.step = 0,
    this.saving = false,
    this.saved = false,
    this.error,
    this.changes = const [],
  });
  final AcademicEvent draft;
  final int step;
  final bool saving, saved;
  final String? error;
  final List<ScheduleChange> changes;
  EventEditorState copyWith({
    AcademicEvent? draft,
    int? step,
    bool? saving,
    bool? saved,
    String? error,
    List<ScheduleChange>? changes,
  }) => EventEditorState(
    draft: draft ?? this.draft,
    step: step ?? this.step,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    error: error,
    changes: changes ?? this.changes,
  );
  @override
  List<Object?> get props => [draft, step, saving, saved, error, changes];
}

sealed class EventEditorEvent {}

class EditorChanged extends EventEditorEvent {
  EditorChanged(this.field, this.value);
  final EditorField field;
  final Object? value;
}

class EditorNext extends EventEditorEvent {}

class EditorBack extends EventEditorEvent {}

class EditorSubmitted extends EventEditorEvent {}

class EventEditorBloc extends Bloc<EventEditorEvent, EventEditorState> {
  EventEditorBloc({
    required this.repository,
    required AcademicEvent draft,
    required this.now,
    this.original,
    this.postpone = false,
  }) : super(EventEditorState(draft: draft)) {
    on<EditorChanged>((e, emit) {
      final d = state.draft;
      AcademicEvent next = d;
      final v = e.value;
      switch (e.field) {
        case EditorField.title:
          next = d.copyWith(title: v as String);
        case EditorField.course:
          next = d.copyWith(courseId: v as String);
        case EditorField.type:
          final type = v as AcademicEventType;
          final at = DateTime(
            d.date.year,
            d.date.month,
            d.date.day,
            type.isDeadline ? 23 : 10,
            type.isDeadline ? 59 : 0,
          );
          next = d.copyWith(
            type: type,
            clearTimes: true,
            startsAt: type.isDeadline ? null : at,
            endsAt: type.isDeadline ? null : at.add(const Duration(hours: 1)),
            deadline: type.isDeadline ? at : null,
          );
        case EditorField.date:
          final date = v as DateTime;
          DateTime? move(DateTime? time) => time == null
              ? null
              : DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
          next = d.copyWith(
            date: date,
            clearTimes: true,
            startsAt: move(d.startsAt),
            endsAt: move(d.endsAt),
            deadline: move(d.deadline),
          );
        case EditorField.time:
          final minute = v as int?;
          final time = minute == null
              ? null
              : DateTime(
                  d.date.year,
                  d.date.month,
                  d.date.day,
                  minute ~/ 60,
                  minute % 60,
                );
          next = d.copyWith(
            clearTimes: true,
            startsAt: d.type.isDeadline ? null : time,
            endsAt: d.type.isDeadline || time == null
                ? null
                : time.add(const Duration(hours: 1)),
            deadline: d.type.isDeadline ? time : null,
          );
        case EditorField.endTime:
          final minute = v as int;
          next = d.copyWith(
            endsAt: DateTime(
              d.date.year,
              d.date.month,
              d.date.day,
              minute ~/ 60,
              minute % 60,
            ),
          );
        case EditorField.location:
          next = d.copyWith(location: v as String);
        case EditorField.syllabus:
          next = d.copyWith(
            syllabus: (v as String)
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
          );
        case EditorField.instructions:
          next = d.copyWith(instructions: v as String);
        case EditorField.attachment:
          next = d.copyWith(attachments: [...d.attachments, v as Attachment]);
        case EditorField.removeAttachment:
          next = d.copyWith(
            attachments: d.attachments.where((a) => a.id != v).toList(),
          );
        case EditorField.reminders:
          next = d.copyWith(suggestedReminders: v as List<int>);
      }
      emit(state.copyWith(draft: next, changes: _changes(next)));
    });
    on<EditorNext>((e, emit) {
      final error = _validate(state.draft);
      if (state.step == 0 && error != null) {
        emit(state.copyWith(error: error));
        return;
      }
      emit(
        state.copyWith(
          step: (state.step + 1).clamp(0, 2),
          changes: _changes(state.draft),
        ),
      );
    });
    on<EditorBack>(
      (e, emit) => emit(state.copyWith(step: (state.step - 1).clamp(0, 2))),
    );
    on<EditorSubmitted>((e, emit) async {
      if (state.saving) return;
      final error = _validate(state.draft);
      if (error != null) {
        emit(state.copyWith(error: error));
        return;
      }
      if (postpone &&
          original != null &&
          original!.effectiveAt == state.draft.effectiveAt) {
        emit(
          state.copyWith(error: 'Choose a new date or time before postponing.'),
        );
        return;
      }
      emit(state.copyWith(saving: true));
      try {
        final d = state.draft.copyWith(
          title: state.draft.title.trim(),
          updatedAt: now,
          status: original == null
              ? EventStatus.scheduled
              : postpone
              ? EventStatus.postponed
              : EventStatus.updated,
          changeHistory: [
            ...?original?.changeHistory,
            ..._changes(state.draft),
          ],
        );
        await repository.save(d);
        emit(state.copyWith(draft: d, saving: false, saved: true));
      } on AppFailure catch (f) {
        emit(state.copyWith(saving: false, error: f.message));
      } catch (_) {
        emit(
          state.copyWith(
            saving: false,
            error:
                'Could not save this event. Your draft is safe here. Try again.',
          ),
        );
      }
    });
  }
  final EventRepository repository;
  final AcademicEvent? original;
  final DateTime now;
  final bool postpone;
  String? _validate(AcademicEvent d) {
    if (d.title.trim().isEmpty) return 'Give this event a clear title.';
    if (d.title.length > 160) return 'Keep the title under 160 characters.';
    if (d.courseId.isEmpty) return 'Choose a course.';
    if (d.type.isDeadline && d.deadline == null) {
      return 'A submission needs a deadline.';
    }
    if (d.startsAt != null &&
        d.endsAt != null &&
        !d.endsAt!.isAfter(d.startsAt!)) {
      return 'End time must be after the start time.';
    }
    return null;
  }

  List<ScheduleChange> _changes(AcademicEvent d) {
    final o = original;
    if (o == null) return [];
    final changes = <ScheduleChange>[];
    void compare(String label, String a, String b) {
      if (a != b) {
        changes.add(
          ScheduleChange(
            id: '${now.microsecondsSinceEpoch}-$label',
            label: label,
            before: a,
            after: b,
            at: now,
            author: 'Class representative',
          ),
        );
      }
    }

    compare('Title changed', o.title, d.title);
    compare('Type changed', o.type.label, d.type.label);
    compare('Course changed', o.courseId, d.courseId);
    compare(
      'Schedule changed',
      '${Fmt.date(o.date)} · ${o.startsAt == null && o.deadline == null ? 'TBA' : Fmt.time(o.effectiveAt)}',
      '${Fmt.date(d.date)} · ${d.startsAt == null && d.deadline == null ? 'TBA' : Fmt.time(d.effectiveAt)}',
    );
    compare(
      'End time changed',
      o.endsAt == null ? 'Not set' : Fmt.time(o.endsAt!),
      d.endsAt == null ? 'Not set' : Fmt.time(d.endsAt!),
    );
    compare('Location changed', o.location ?? 'TBA', d.location ?? 'TBA');
    compare('Syllabus updated', o.syllabus.join('; '), d.syllabus.join('; '));
    compare('Instructions updated', o.instructions, d.instructions);
    compare(
      'Attachments updated',
      o.attachments.map((a) => a.name).join(', '),
      d.attachments.map((a) => a.name).join(', '),
    );
    return changes;
  }
}
