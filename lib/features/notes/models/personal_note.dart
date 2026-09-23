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
