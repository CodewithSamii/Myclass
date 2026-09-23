import 'package:equatable/equatable.dart';

enum AcademicEventType {
  assignment,
  submission,
  quiz,
  classTest,
  viva,
  presentation,
  exam,
  labExam,
  project,
  report,
  general,
}

extension EventTypeLabel on AcademicEventType {
  String get label => switch (this) {
    AcademicEventType.assignment => 'Assignment',
    AcademicEventType.submission => 'Submission',
    AcademicEventType.quiz => 'Quiz',
    AcademicEventType.classTest => 'Class test',
    AcademicEventType.viva => 'Viva',
    AcademicEventType.presentation => 'Presentation',
    AcademicEventType.exam => 'Exam',
    AcademicEventType.labExam => 'Lab exam',
    AcademicEventType.project => 'Project',
    AcademicEventType.report => 'Report',
    AcademicEventType.general => 'Academic event',
  };
  bool get isDeadline => [
    AcademicEventType.assignment,
    AcademicEventType.submission,
    AcademicEventType.project,
    AcademicEventType.report,
  ].contains(this);
  bool get isExam =>
      this == AcademicEventType.exam || this == AcademicEventType.labExam;
}

enum EventStatus { scheduled, updated, postponed, cancelled, completed }

extension StatusLabel on EventStatus {
  String get label => switch (this) {
    EventStatus.scheduled => 'Scheduled',
    EventStatus.updated => 'Updated',
    EventStatus.postponed => 'Postponed',
    EventStatus.cancelled => 'Cancelled',
    EventStatus.completed => 'Completed',
  };
}

enum AttachmentKind { pdf, document, image, file }

class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.name,
    required this.kind,
    required this.sizeLabel,
    this.preview =
        'Preview content will be available when this file is connected.',
  });
  final String id, name, sizeLabel, preview;
  final AttachmentKind kind;
  @override
  List<Object?> get props => [id, name, kind, sizeLabel, preview];
}

class ScheduleChange extends Equatable {
  const ScheduleChange({
    required this.id,
    required this.label,
    required this.before,
    required this.after,
    required this.at,
    required this.author,
  });
  final String id, label, before, after, author;
  final DateTime at;
  @override
  List<Object?> get props => [id, label, before, after, at, author];
}

class AcademicEvent extends Equatable {
  const AcademicEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.courseId,
    required this.date,
    required this.sectionId,
    required this.createdAt,
    required this.updatedAt,
    this.startsAt,
    this.endsAt,
    this.deadline,
    this.location,
    this.description = '',
    this.syllabus = const [],
    this.instructions = '',
    this.attachments = const [],
    this.createdBy = 'Class representative',
    this.status = EventStatus.scheduled,
    this.changeHistory = const [],
    this.suggestedReminders,
  });
  final String id,
      title,
      courseId,
      sectionId,
      description,
      instructions,
      createdBy;
  final AcademicEventType type;
  final EventStatus status;
  final DateTime date, createdAt, updatedAt;
  final DateTime? startsAt, endsAt, deadline;
  final String? location;
  final List<String> syllabus;
  final List<Attachment> attachments;
  final List<ScheduleChange> changeHistory;
  final List<int>? suggestedReminders;
  DateTime get effectiveAt => deadline ?? startsAt ?? date;
  bool get actionable =>
      status != EventStatus.cancelled && status != EventStatus.completed;
  bool passed(DateTime now) =>
      actionable &&
      (deadline ?? endsAt ?? startsAt ?? date.add(const Duration(days: 1)))
          .isBefore(now);
  String statusAt(DateTime now) =>
      deadline != null && deadline!.isBefore(now) && actionable
      ? 'Deadline passed'
      : status.label;
  AcademicEvent copyWith({
    String? title,
    AcademicEventType? type,
    String? courseId,
    DateTime? date,
    DateTime? startsAt,
    DateTime? endsAt,
    DateTime? deadline,
    bool clearTimes = false,
    String? location,
    String? description,
    List<String>? syllabus,
    String? instructions,
    List<Attachment>? attachments,
    EventStatus? status,
    List<ScheduleChange>? changeHistory,
    DateTime? updatedAt,
    List<int>? suggestedReminders,
  }) => AcademicEvent(
    id: id,
    title: title ?? this.title,
    type: type ?? this.type,
    courseId: courseId ?? this.courseId,
    date: date ?? this.date,
    sectionId: sectionId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    startsAt: clearTimes ? startsAt : startsAt ?? this.startsAt,
    endsAt: clearTimes ? endsAt : endsAt ?? this.endsAt,
    deadline: clearTimes ? deadline : deadline ?? this.deadline,
    location: location ?? this.location,
    description: description ?? this.description,
    syllabus: syllabus ?? this.syllabus,
    instructions: instructions ?? this.instructions,
    attachments: attachments ?? this.attachments,
    createdBy: createdBy,
    status: status ?? this.status,
    changeHistory: changeHistory ?? this.changeHistory,
    suggestedReminders: suggestedReminders ?? this.suggestedReminders,
  );
  @override
  List<Object?> get props => [
    id,
    title,
    type,
    courseId,
    date,
    sectionId,
    createdAt,
    updatedAt,
    startsAt,
    endsAt,
    deadline,
    location,
    description,
    syllabus,
    instructions,
    attachments,
    createdBy,
    status,
    changeHistory,
    suggestedReminders,
  ];
}

class UpdateFeedItem extends Equatable {
  const UpdateFeedItem({
    required this.id,
    this.sessionId,
    required this.eventId,
    required this.title,
    required this.detail,
    required this.at,
  });
  final String id, eventId, title, detail;
  final String? sessionId;
  final DateTime at;
  @override
  List<Object?> get props => [id, eventId, sessionId, title, detail, at];
}
