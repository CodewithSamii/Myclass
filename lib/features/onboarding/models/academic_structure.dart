import 'package:equatable/equatable.dart';

class University extends Equatable {
  const University(this.id, this.name, this.timeZone);
  final String id, name, timeZone;
  @override
  List<Object?> get props => [id, name, timeZone];
}

class Department extends Equatable {
  const Department(this.id, this.name, this.shortName);
  final String id, name, shortName;
  @override
  List<Object?> get props => [id, name, shortName];
}

class AcademicProgram extends Equatable {
  const AcademicProgram({
    required this.id,
    required this.name,
    required this.shortName,
    required this.departmentId,
    required this.type,
    this.universityId = 'mu',
  });
  final String id, name, shortName, departmentId, type, universityId;
  @override
  List<Object?> get props => [id, name, departmentId, type];
}

class Batch extends Equatable {
  const Batch(this.id, this.programId, this.label);
  final String id, programId, label;
  @override
  List<Object?> get props => [id, programId, label];
}

class Section extends Equatable {
  const Section(this.id, this.batchId, this.label, {this.memberCount = 42});
  final String id, batchId, label;
  final int memberCount;
  @override
  List<Object?> get props => [id, batchId, label, memberCount];
}

enum UserRole { student, sectionAdmin, departmentAdmin, universityAdmin }

class SectionMembership extends Equatable {
  const SectionMembership({
    required this.sectionId,
    this.departmentId = "",
    required this.programId,
    required this.batchId,
    required this.programName,
    required this.batchName,
    required this.sectionName,
    this.role = UserRole.student,
  });
  final String departmentId;
  final String sectionId,
      programId,
      batchId,
      programName,
      batchName,
      sectionName;
  final UserRole role;
  bool get canManage => role != UserRole.student;
  String get label => '$batchName · $sectionName';
  SectionMembership withRole(UserRole value) => SectionMembership(
    sectionId: sectionId,
    departmentId: departmentId,
    programId: programId,
    batchId: batchId,
    programName: programName,
    batchName: batchName,
    sectionName: sectionName,
    role: value,
  );
  Map<String, dynamic> toJson() => {
    'sectionId': sectionId,
    'departmentId': departmentId,
    'programId': programId,
    'batchId': batchId,
    'programName': programName,
    'batchName': batchName,
    'sectionName': sectionName,
    'role': role.name,
  };
  factory SectionMembership.fromJson(Map<String, dynamic> j) =>
      SectionMembership(
        sectionId: j['sectionId'],
        departmentId: j['departmentId'] ?? '',
        programId: j['programId'],
        batchId: j['batchId'],
        programName: j['programName'],
        batchName: j['batchName'],
        sectionName: j['sectionName'],
        role: UserRole.values.byName(j['role']),
      );
  @override
  List<Object?> get props => [
    sectionId,
    departmentId,
    programId,
    batchId,
    programName,
    batchName,
    sectionName,
    role,
  ];
}

/// Opaque backend-issued capability. A section secret is never part of a model.
class SectionGrant {
  const SectionGrant(this.sectionId, this.token);
  final String sectionId, token;
}
