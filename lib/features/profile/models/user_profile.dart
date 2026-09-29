import 'package:equatable/equatable.dart';
import '../../onboarding/models/academic_structure.dart';
import '../../events/models/academic_event.dart';

enum Appearance { system, light, dark }

class ReminderPreference extends Equatable {
  const ReminderPreference({
    this.classOffsets = const [15],
    this.assignmentOffsets = const [4320, 1440],
    this.vivaOffsets = const [4320, 1440],
    this.presentationOffsets = const [4320, 1440],
    this.examOffsets = const [10080, 4320, 1440],
    this.dailySummary = false,
    this.summaryMinute = 1200,
    this.scheduleChanges = true,
    this.busReminderMinutes = 15,
    this.busReminderMode = 'classDaysOnly',
    this.busReminderDays = const [1, 2, 3, 4, 5, 6, 7],
  });
  final List<int> classOffsets,
      assignmentOffsets,
      vivaOffsets,
      presentationOffsets,
      examOffsets;
  final bool dailySummary, scheduleChanges;
  final int summaryMinute;
  final int busReminderMinutes;
  final String busReminderMode; // 'classDaysOnly', 'everyDay', 'custom'
  final List<int> busReminderDays; // 1 (Mon) .. 7 (Sun)

  bool isBusReminderActiveForDay({required DateTime date, required bool hasClasses}) {
    if (busReminderMinutes <= 0) return false;
    if (busReminderMode == 'everyDay') return true;
    if (busReminderMode == 'classDaysOnly') return hasClasses;
    if (busReminderMode == 'custom') return busReminderDays.contains(date.weekday);
    return hasClasses;
  }

  List<int> forType(AcademicEventType t) => t.isExam
      ? examOffsets
      : t == AcademicEventType.viva
      ? vivaOffsets
      : t == AcademicEventType.presentation
      ? presentationOffsets
      : assignmentOffsets;
  ReminderPreference copyWith({
    List<int>? classOffsets,
    List<int>? assignmentOffsets,
    List<int>? vivaOffsets,
    List<int>? presentationOffsets,
    List<int>? examOffsets,
    bool? dailySummary,
    int? summaryMinute,
    bool? scheduleChanges,
    int? busReminderMinutes,
    String? busReminderMode,
    List<int>? busReminderDays,
  }) => ReminderPreference(
    classOffsets: classOffsets ?? this.classOffsets,
    assignmentOffsets: assignmentOffsets ?? this.assignmentOffsets,
    vivaOffsets: vivaOffsets ?? this.vivaOffsets,
    presentationOffsets: presentationOffsets ?? this.presentationOffsets,
    examOffsets: examOffsets ?? this.examOffsets,
    dailySummary: dailySummary ?? this.dailySummary,
    summaryMinute: summaryMinute ?? this.summaryMinute,
    scheduleChanges: scheduleChanges ?? this.scheduleChanges,
    busReminderMinutes: busReminderMinutes ?? this.busReminderMinutes,
    busReminderMode: busReminderMode ?? this.busReminderMode,
    busReminderDays: busReminderDays ?? this.busReminderDays,
  );
  Map<String, dynamic> toJson() => {
    'class': classOffsets,
    'assignment': assignmentOffsets,
    'viva': vivaOffsets,
    'presentation': presentationOffsets,
    'exam': examOffsets,
    'daily': dailySummary,
    'minute': summaryMinute,
    'changes': scheduleChanges,
    'bus': busReminderMinutes,
    'busMode': busReminderMode,
    'busDays': busReminderDays,
  };
  factory ReminderPreference.fromJson(Map<String, dynamic> j) =>
      ReminderPreference(
        classOffsets: List<int>.from(j['class']),
        assignmentOffsets: List<int>.from(j['assignment']),
        vivaOffsets: List<int>.from(j['viva']),
        presentationOffsets: List<int>.from(j['presentation']),
        examOffsets: List<int>.from(j['exam']),
        dailySummary: j['daily'],
        summaryMinute: j['minute'],
        scheduleChanges: j['changes'],
        busReminderMinutes: j['bus'] ?? 15,
        busReminderMode: j['busMode'] ?? 'classDaysOnly',
        busReminderDays: j['busDays'] != null
            ? List<int>.from(j['busDays'])
            : const [1, 2, 3, 4, 5, 6, 7],
      );
  @override
  List<Object?> get props => [
    classOffsets,
    assignmentOffsets,
    vivaOffsets,
    presentationOffsets,
    examOffsets,
    dailySummary,
    summaryMinute,
    scheduleChanges,
    busReminderMinutes,
    busReminderMode,
    busReminderDays,
  ];
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.memberships,
    required this.activeSectionId,
    this.appearance = Appearance.system,
    this.reminders = const ReminderPreference(),
    this.avatarUrl,
  });
  final String uid, name, email, activeSectionId;
  final List<SectionMembership> memberships;
  final Appearance appearance;
  final ReminderPreference reminders;
  final String? avatarUrl;
  SectionMembership get membership =>
      memberships.firstWhere((m) => m.sectionId == activeSectionId);
  UserProfile copyWith({
    String? name,
    List<SectionMembership>? memberships,
    String? activeSectionId,
    Appearance? appearance,
    ReminderPreference? reminders,
    String? avatarUrl,
    bool clearAvatar = false,
  }) => UserProfile(
    uid: uid,
    name: name ?? this.name,
    email: email,
    memberships: memberships ?? this.memberships,
    activeSectionId: activeSectionId ?? this.activeSectionId,
    appearance: appearance ?? this.appearance,
    reminders: reminders ?? this.reminders,
    avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
  );
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'memberships': memberships.map((m) => m.toJson()).toList(),
    'activeSectionId': activeSectionId,
    'appearance': appearance.name,
    'reminders': reminders.toJson(),
    'avatarUrl': avatarUrl,
  };
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    uid: j['uid'],
    name: j['name'],
    email: j['email'],
    memberships: (j['memberships'] as List)
        .map((m) => SectionMembership.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
    activeSectionId: j['activeSectionId'],
    appearance: Appearance.values.byName(j['appearance']),
    reminders: ReminderPreference.fromJson(j['reminders']),
    avatarUrl: j['avatarUrl'] as String?,
  );
  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    memberships,
    activeSectionId,
    appearance,
    reminders,
    avatarUrl,
  ];
}

class PersonalProgress extends Equatable {
  const PersonalProgress({
    required this.eventId,
    this.completed = false,
    this.reminderOffsets,
  });
  final String eventId;
  final bool completed;

  /// Null inherits current defaults; an empty list explicitly disables reminders.
  final List<int>? reminderOffsets;
  PersonalProgress copyWith({
    bool? completed,
    List<int>? reminderOffsets,
    bool inherit = false,
  }) => PersonalProgress(
    eventId: eventId,
    completed: completed ?? this.completed,
    reminderOffsets: inherit ? null : reminderOffsets ?? this.reminderOffsets,
  );
  @override
  List<Object?> get props => [eventId, completed, reminderOffsets];
}
