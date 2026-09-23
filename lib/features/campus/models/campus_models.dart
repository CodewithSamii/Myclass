import 'package:equatable/equatable.dart';

class BusStop extends Equatable {
  const BusStop(this.name, this.minuteOffset);
  final String name;
  final int minuteOffset;
  @override
  List<Object?> get props => [name, minuteOffset];
}

class BusDeparture extends Equatable {
  const BusDeparture(this.minute, {this.toCampus = true});
  final int minute;
  final bool toCampus;
  @override
  List<Object?> get props => [minute, toCampus];
}

class BusRoute extends Equatable {
  const BusRoute({
    required this.id,
    required this.number,
    required this.name,
    required this.stops,
    required this.departures,
    required this.durationMinutes,
    this.notice,
  });
  final String id, name;
  final int number, durationMinutes;
  final List<BusStop> stops;
  final List<BusDeparture> departures;
  final String? notice;
  @override
  List<Object?> get props => [
    id,
    number,
    name,
    stops,
    departures,
    durationMinutes,
    notice,
  ];
}

class FacultyMember extends Equatable {
  const FacultyMember({
    required this.id,
    required this.name,
    required this.designation,
    required this.departmentId,
    required this.email,
    required this.office,
    this.phone,
    this.officeHours = 'Sunday–Thursday · By appointment',
    this.interests = const [],
  });
  final String id, name, designation, departmentId, email, office, officeHours;
  final String? phone;
  final List<String> interests;
  String get initials => name
      .split(' ')
      .where((n) => !['Dr.', 'Md.', 'Prof.'].contains(n))
      .take(2)
      .map((n) => n[0])
      .join();
  @override
  List<Object?> get props => [
    id,
    name,
    designation,
    departmentId,
    email,
    office,
    phone,
    officeHours,
    interests,
  ];
}
