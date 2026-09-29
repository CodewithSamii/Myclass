import 'package:equatable/equatable.dart';

class PersonalNote extends Equatable {
  const PersonalNote({
    required this.id,
    required this.uid,
    required this.text,
    required this.updatedAt,
    this.eventId,
    this.remindAt,
    this.completed = false,
  });

  final String id, uid, text;
  final String? eventId;
  final DateTime updatedAt;
  final DateTime? remindAt;
  final bool completed;

  PersonalNote copyWith({
    String? text,
    DateTime? remindAt,
    bool clearReminder = false,
    bool? completed,
    DateTime? updatedAt,
  }) => PersonalNote(
    id: id,
    uid: uid,
    text: text ?? this.text,
    updatedAt: updatedAt ?? this.updatedAt,
    eventId: eventId,
    remindAt: clearReminder ? null : remindAt ?? this.remindAt,
    completed: completed ?? this.completed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'text': text,
    'updatedAt': updatedAt.toIso8601String(),
    'eventId': eventId,
    'remindAt': remindAt?.toIso8601String(),
    'completed': completed,
  };

  factory PersonalNote.fromJson(Map<String, dynamic> j) => PersonalNote(
    id: j['id'] ?? '',
    uid: j['uid'] ?? '',
    text: j['text'] ?? '',
    updatedAt: DateTime.parse(j['updatedAt']),
    eventId: j['eventId'],
    remindAt: j['remindAt'] != null ? DateTime.tryParse(j['remindAt']) : null,
    completed: j['completed'] ?? false,
  );

  @override
  List<Object?> get props => [
    id,
    uid,
    text,
    eventId,
    updatedAt,
    remindAt,
    completed,
  ];
}
