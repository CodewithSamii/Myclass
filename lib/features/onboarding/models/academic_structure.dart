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

enum SectionStatus { pendingApproval, approved, rejected }

class Section extends Equatable {
  const Section(
    this.id,
    this.batchId,
    this.label, {
    this.memberCount = 42,
    this.adminId,
    this.creatorName,
    this.adminPassword,
    this.studentPassword,
    this.status = SectionStatus.approved,
    this.createdAt,
    this.departmentId,
    this.departmentName,
    this.batchName,
    this.universityId = 'lu',
    this.universityName = 'Leading University',
  });

  final String id, batchId, label;
  final int memberCount;
  final String? adminId;
  final String? creatorName;
  final String? adminPassword;
  final String? studentPassword;
  final SectionStatus status;
  final DateTime? createdAt;
  final String? departmentId;
  final String? departmentName;
  final String? batchName;
  final String? universityId;
  final String? universityName;

  bool get isApproved => status == SectionStatus.approved;
  bool get isPending => status == SectionStatus.pendingApproval;

  Section copyWith({
    String? id,
    String? batchId,
    String? label,
    int? memberCount,
    String? adminId,
    String? creatorName,
    String? adminPassword,
    String? studentPassword,
    SectionStatus? status,
    DateTime? createdAt,
    String? departmentId,
    String? departmentName,
    String? batchName,
    String? universityId,
    String? universityName,
  }) => Section(
    id ?? this.id,
    batchId ?? this.batchId,
    label ?? this.label,
    memberCount: memberCount ?? this.memberCount,
    adminId: adminId ?? this.adminId,
    creatorName: creatorName ?? this.creatorName,
    adminPassword: adminPassword ?? this.adminPassword,
    studentPassword: studentPassword ?? this.studentPassword,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    departmentId: departmentId ?? this.departmentId,
    departmentName: departmentName ?? this.departmentName,
    batchName: batchName ?? this.batchName,
    universityId: universityId ?? this.universityId,
    universityName: universityName ?? this.universityName,
  );

  @override
  List<Object?> get props => [
    id,
    batchId,
    label,
    memberCount,
    adminId,
    creatorName,
    adminPassword,
    studentPassword,
    status,
    createdAt,
    departmentId,
    departmentName,
    batchName,
    universityId,
    universityName,
  ];
}

enum UserRole { student, teacher, sectionAdmin, departmentAdmin, universityAdmin, myClassOwner }

class SectionMembership extends Equatable {
  const SectionMembership({
    required this.sectionId,
    this.departmentId = "",
    required this.programId,
    required this.batchId,
    required this.programName,
    required this.batchName,
    required this.sectionName,
    this.universityId = "lu",
    this.universityName = "Leading University",
    this.role = UserRole.student,
  });
  final String departmentId;
  final String sectionId,
      programId,
      batchId,
      programName,
      batchName,
      sectionName,
      universityId,
      universityName;
  final UserRole role;
  bool get isTeacher => role == UserRole.teacher;
  bool get canManage =>
      role == UserRole.teacher ||
      role == UserRole.sectionAdmin ||
      role == UserRole.departmentAdmin ||
      role == UserRole.universityAdmin ||
      role == UserRole.myClassOwner;
  bool get isOwner => role == UserRole.myClassOwner;
  bool get isAdmin =>
      role == UserRole.sectionAdmin || role == UserRole.myClassOwner;
  String get label => '$batchName · $sectionName';
  SectionMembership withRole(UserRole value) => SectionMembership(
    sectionId: sectionId,
    departmentId: departmentId,
    programId: programId,
    batchId: batchId,
    programName: programName,
    batchName: batchName,
    sectionName: sectionName,
    universityId: universityId,
    universityName: universityName,
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
    'universityId': universityId,
    'universityName': universityName,
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
        universityId: j['universityId'] ?? 'lu',
        universityName: j['universityName'] ?? 'Leading University',
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
    universityId,
    universityName,
    role,
  ];
}

/// Opaque backend-issued capability. A section secret is never part of a model.
class SectionGrant {
  const SectionGrant(this.sectionId, this.token, {this.role = UserRole.student});
  final String sectionId, token;
  final UserRole role;
}

