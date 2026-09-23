import 'package:equatable/equatable.dart';

class Course extends Equatable {
  const Course({
    required this.id,
    required this.name,
    this.code,
    required this.facultyId,
    required this.departmentId,
    this.shortName,
  });
  final String id, name, facultyId, departmentId;
  final String? code, shortName;
  String get compactName => shortName ?? name;
  @override
  List<Object?> get props => [
    id,
    name,
    code,
    facultyId,
    departmentId,
    shortName,
  ];
}

class ClassSession extends Equatable {
  const ClassSession({
    required this.id,
    required this.sectionId,
    required this.courseId,
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    this.room,
    this.isLab = false,
    this.isOnline = false,
    this.cancelled = false,
    this.changed = false,
  });
  final String id, sectionId, courseId;
  final int weekday, startMinute, endMinute;
  final String? room;
  final bool isLab, isOnline, cancelled, changed;
  DateTime startOn(DateTime d) =>
      DateTime(d.year, d.month, d.day, startMinute ~/ 60, startMinute % 60);
  DateTime endOn(DateTime d) =>
      DateTime(d.year, d.month, d.day, endMinute ~/ 60, endMinute % 60);
  ClassSession copyWith({
    int? weekday,
    int? startMinute,
    int? endMinute,
    String? room,
    bool? cancelled,
    bool? changed,
  }) => ClassSession(
    id: id,
    sectionId: sectionId,
    courseId: courseId,
    weekday: weekday ?? this.weekday,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    room: room ?? this.room,
    isLab: isLab,
    isOnline: isOnline,
    cancelled: cancelled ?? this.cancelled,
    changed: changed ?? this.changed,
  );
  @override
  List<Object?> get props => [
    id,
    sectionId,
    courseId,
    weekday,
    startMinute,
    endMinute,
    room,
    isLab,
    isOnline,
    cancelled,
    changed,
  ];
}

/// University calendar periods affect recurring classes, not shared event truth.
class AcademicPeriod extends Equatable {
  const AcademicPeriod({
    required this.title,
    required this.start,
    required this.end,
    this.classesSuspended = false,
  });
  final String title;
  final DateTime start, end;
  final bool classesSuspended;
  bool includes(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  @override
  List<Object?> get props => [title, start, end, classesSuspended];
}
