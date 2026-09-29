import 'package:equatable/equatable.dart';

enum BatchResourceType { notes, pyq }

class BatchResourceItem extends Equatable {
  const BatchResourceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.uploaderName,
    required this.uploaderSection,
    required this.batchId,
    required this.type,
    this.isApproved = false,
    this.approvedByAdminName,
    required this.createdAt,
    this.fileUrl,
  });

  final String id;
  final String title;
  final String description;
  final String uploaderName;
  final String uploaderSection;
  final String batchId;
  final BatchResourceType type;
  final bool isApproved;
  final String? approvedByAdminName;
  final DateTime createdAt;
  final String? fileUrl;

  BatchResourceItem copyWith({
    bool? isApproved,
    String? approvedByAdminName,
  }) =>
      BatchResourceItem(
        id: id,
        title: title,
        description: description,
        uploaderName: uploaderName,
        uploaderSection: uploaderSection,
        batchId: batchId,
        type: type,
        isApproved: isApproved ?? this.isApproved,
        approvedByAdminName: approvedByAdminName ?? this.approvedByAdminName,
        createdAt: createdAt,
        fileUrl: fileUrl,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        uploaderName,
        uploaderSection,
        batchId,
        type,
        isApproved,
        approvedByAdminName,
        createdAt,
        fileUrl,
      ];
}

class BatchSectionInfo extends Equatable {
  const BatchSectionInfo({
    required this.sectionName,
    required this.crName,
    required this.crPhone,
    required this.crEmail,
    required this.totalStudents,
    this.department = 'CSE',
  });

  final String sectionName;
  final String crName;
  final String crPhone;
  final String crEmail;
  final int totalStudents;
  final String department;

  @override
  List<Object?> get props => [
        sectionName,
        crName,
        crPhone,
        crEmail,
        totalStudents,
        department,
      ];
}
