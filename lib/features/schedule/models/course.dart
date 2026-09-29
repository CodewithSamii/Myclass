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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'facultyId': facultyId,
    'departmentId': departmentId,
    'shortName': shortName,
  };

  factory Course.fromJson(Map<String, dynamic> j) => Course(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    code: j['code'],
    facultyId: j['facultyId'] ?? '',
    departmentId: j['departmentId'] ?? '',
    shortName: j['shortName'],
  );

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
    this.specificDate,
    this.isTemporary = false,
    this.isShifted = false,
    this.originalDate,
    this.originalTimeLabel,
    this.notes,
    this.meetingLink,
    this.customCourseName,
    this.facultyName,
  });
  final String id, sectionId, courseId;
  final int weekday, startMinute, endMinute;
  final String? room;
  final bool isLab, isOnline, cancelled, changed;
  final DateTime? specificDate;
  final bool isTemporary, isShifted;
  final DateTime? originalDate;
  final String? originalTimeLabel;
  final String? notes, meetingLink, customCourseName, facultyName;

  DateTime startOn(DateTime d) =>
      DateTime(d.year, d.month, d.day, startMinute ~/ 60, startMinute % 60);
  DateTime endOn(DateTime d) =>
      DateTime(d.year, d.month, d.day, endMinute ~/ 60, endMinute % 60);

  ClassSession copyWith({
    String? id,
    String? sectionId,
    String? courseId,
    int? weekday,
    int? startMinute,
    int? endMinute,
    String? room,
    bool? isLab,
    bool? isOnline,
    bool? cancelled,
    bool? changed,
    DateTime? specificDate,
    bool? isTemporary,
    bool? isShifted,
    DateTime? originalDate,
    String? originalTimeLabel,
    String? notes,
    String? meetingLink,
    String? customCourseName,
    String? facultyName,
  }) => ClassSession(
    id: id ?? this.id,
    sectionId: sectionId ?? this.sectionId,
    courseId: courseId ?? this.courseId,
    weekday: weekday ?? this.weekday,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    room: room ?? this.room,
    isLab: isLab ?? this.isLab,
    isOnline: isOnline ?? this.isOnline,
    cancelled: cancelled ?? this.cancelled,
    changed: changed ?? this.changed,
    specificDate: specificDate ?? this.specificDate,
    isTemporary: isTemporary ?? this.isTemporary,
    isShifted: isShifted ?? this.isShifted,
    originalDate: originalDate ?? this.originalDate,
    originalTimeLabel: originalTimeLabel ?? this.originalTimeLabel,
    notes: notes ?? this.notes,
    meetingLink: meetingLink ?? this.meetingLink,
    customCourseName: customCourseName ?? this.customCourseName,
    facultyName: facultyName ?? this.facultyName,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sectionId': sectionId,
    'courseId': courseId,
    'weekday': weekday,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'room': room,
    'isLab': isLab,
    'isOnline': isOnline,
    'cancelled': cancelled,
    'changed': changed,
    'specificDate': specificDate?.toIso8601String(),
    'isTemporary': isTemporary,
    'isShifted': isShifted,
    'originalDate': originalDate?.toIso8601String(),
    'originalTimeLabel': originalTimeLabel,
    'notes': notes,
    'meetingLink': meetingLink,
    'customCourseName': customCourseName,
    'facultyName': facultyName,
  };

  factory ClassSession.fromJson(Map<String, dynamic> j) => ClassSession(
    id: j['id'] ?? '',
    sectionId: j['sectionId'] ?? '',
    courseId: j['courseId'] ?? '',
    weekday: j['weekday'] ?? 1,
    startMinute: j['startMinute'] ?? 0,
    endMinute: j['endMinute'] ?? 0,
    room: j['room'],
    isLab: j['isLab'] ?? false,
    isOnline: j['isOnline'] ?? false,
    cancelled: j['cancelled'] ?? false,
    changed: j['changed'] ?? false,
    specificDate: j['specificDate'] != null ? DateTime.tryParse(j['specificDate']) : null,
    isTemporary: j['isTemporary'] ?? false,
    isShifted: j['isShifted'] ?? false,
    originalDate: j['originalDate'] != null ? DateTime.tryParse(j['originalDate']) : null,
    originalTimeLabel: j['originalTimeLabel'],
    notes: j['notes'],
    meetingLink: j['meetingLink'],
    customCourseName: j['customCourseName'],
    facultyName: j['facultyName'],
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
    specificDate,
    isTemporary,
    isShifted,
    originalDate,
    originalTimeLabel,
    notes,
    meetingLink,
    customCourseName,
    facultyName,
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

  Map<String, dynamic> toJson() => {
    'title': title,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'classesSuspended': classesSuspended,
  };

  factory AcademicPeriod.fromJson(Map<String, dynamic> j) => AcademicPeriod(
    title: j['title'] ?? '',
    start: DateTime.parse(j['start']),
    end: DateTime.parse(j['end']),
    classesSuspended: j['classesSuspended'] ?? false,
  );

  @override
  List<Object?> get props => [title, start, end, classesSuspended];
}

class TimeSlot extends Equatable {
  const TimeSlot({
    required this.id,
    required this.label,
    required this.startMinute,
    required this.endMinute,
    this.orderIndex = 0,
  });

  final String id, label;
  final int startMinute, endMinute, orderIndex;

  String get display => label.isNotEmpty
      ? label
      : '${formatMin(startMinute)}–${formatMin(endMinute)}';

  static String formatMin(int m) {
    final hour24 = m ~/ 60;
    final minute = m % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minStr = minute == 0 ? ':00' : ':${minute.toString().padLeft(2, '0')}';
    return '$hour12$minStr $period';
  }

  TimeSlot copyWith({
    String? id,
    String? label,
    int? startMinute,
    int? endMinute,
    int? orderIndex,
  }) => TimeSlot(
    id: id ?? this.id,
    label: label ?? this.label,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    orderIndex: orderIndex ?? this.orderIndex,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'orderIndex': orderIndex,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> j) => TimeSlot(
    id: j['id'] ?? '',
    label: j['label'] ?? '',
    startMinute: j['startMinute'] ?? 0,
    endMinute: j['endMinute'] ?? 0,
    orderIndex: j['orderIndex'] ?? 0,
  );

  @override
  List<Object?> get props => [id, label, startMinute, endMinute, orderIndex];
}
