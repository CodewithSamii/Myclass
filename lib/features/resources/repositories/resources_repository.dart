import '../models/resource_item.dart';

class ResourcesRepository {
  static final ResourcesRepository instance = ResourcesRepository._();
  ResourcesRepository._() {
    _initFixtures();
  }

  final List<BatchResourceItem> _items = [];
  final List<BatchSectionInfo> _sections = [];

  void _initFixtures() {
    _items.addAll([
      BatchResourceItem(
        id: 'note-1',
        title: 'Operating Systems Process Synchronization & Semaphores',
        description: 'Detailed lecture notes on Mutex, Semaphores, and Dining Philosophers problem.',
        uploaderName: 'Rafid Ahmed',
        uploaderSection: 'Section A',
        batchId: 'bsc-cse-64',
        type: BatchResourceType.notes,
        isApproved: true,
        approvedByAdminName: 'Admin Monir',
        createdAt: DateTime(2026, 9, 10),
      ),
      BatchResourceItem(
        id: 'note-2',
        title: 'Database Normalization Quick Formula Sheet (1NF to BCNF)',
        description: 'Step by step decomposition examples with functional dependencies.',
        uploaderName: 'Tasmia Khan',
        uploaderSection: 'Section B',
        batchId: 'bsc-cse-64',
        type: BatchResourceType.notes,
        isApproved: true,
        approvedByAdminName: 'Admin Monir',
        createdAt: DateTime(2026, 9, 12),
      ),
      BatchResourceItem(
        id: 'note-3',
        title: 'Computer Networks Socket Programming in Java & C++',
        description: 'Complete TCP client-server implementation notes with packet capture analysis.',
        uploaderName: 'Rafid Ahmed',
        uploaderSection: 'Section A',
        batchId: 'bsc-cse-64',
        type: BatchResourceType.notes,
        isApproved: true,
        approvedByAdminName: 'Admin Monir',
        createdAt: DateTime(2026, 9, 14),
      ),
      BatchResourceItem(
        id: 'note-4',
        title: 'Data Structures Trees & Graphs Traversal Summary',
        description: 'BFS, DFS, Dijkstra, and Kruskal algorithms handwritten notes.',
        uploaderName: 'Sadik Rahman',
        uploaderSection: 'Section I',
        batchId: 'bsc-cse-64',
        type: BatchResourceType.notes,
        isApproved: true,
        approvedByAdminName: 'Admin Sami',
        createdAt: DateTime(2026, 9, 18),
      ),
      BatchResourceItem(
        id: 'note-5',
        title: 'Microprocessor 8086 Instruction Set Cheatsheet',
        description: 'Arithmetic, logical, and string instructions with flag register operations.',
        uploaderName: 'Nafis Fuad',
        uploaderSection: 'Section C',
        batchId: 'bsc-cse-64',
        type: BatchResourceType.notes,
        isApproved: true,
        approvedByAdminName: 'Admin Sami',
        createdAt: DateTime(2026, 9, 20),
      ),
      // Previous Year Questions
      BatchResourceItem(
        id: 'pyq-1',
        title: 'CSE 211 Theory of Computation Midterm (Spring 2024)',
        description: 'Leading University Department of CSE Midterm question paper.',
        uploaderName: 'Fahim Shahriar',
        uploaderSection: 'Section D',
        batchId: 'bsc-cse-64',
        type: BatchResourceType.pyq,
        isApproved: true,
        approvedByAdminName: 'Admin Monir',
        createdAt: DateTime(2026, 9, 05),
      ),
      BatchResourceItem(
        id: 'pyq-2',
        title: 'CSE 213 Numerical Methods Final Examination (Fall 2024)',
        description: 'Comprehensive final exam question with solution highlights.',
        uploaderName: 'Fahim Shahriar',
        uploaderSection: 'Section D',
        batchId: 'bsc-cse-64',
        type: BatchResourceType.pyq,
        isApproved: true,
        approvedByAdminName: 'Admin Monir',
        createdAt: DateTime(2026, 9, 08),
      ),
      BatchResourceItem(
        id: 'pyq-3',
        title: 'CSE 225 Design & Analysis of Algorithms Midterm (2025)',
        description: 'Master theorem, recurrence relations, and dynamic programming exam paper.',
        uploaderName: 'Ayesha Siddiqua',
        uploaderSection: 'Section E',
        batchId: 'bsc-cse-64',
        type: BatchResourceType.pyq,
        isApproved: true,
        approvedByAdminName: 'Admin Sami',
        createdAt: DateTime(2026, 9, 15),
      ),
    ]);

    _sections.addAll([
      const BatchSectionInfo(
        sectionName: 'Section A',
        crName: 'Tanvir Hasan',
        crPhone: '+880 1711-234501',
        crEmail: 'cr.sec.a@leading.edu',
        totalStudents: 52,
      ),
      const BatchSectionInfo(
        sectionName: 'Section B',
        crName: 'Nusrat Anjum',
        crPhone: '+880 1711-234502',
        crEmail: 'cr.sec.b@leading.edu',
        totalStudents: 50,
      ),
      const BatchSectionInfo(
        sectionName: 'Section C',
        crName: 'Mehedi Hasan',
        crPhone: '+880 1711-234503',
        crEmail: 'cr.sec.c@leading.edu',
        totalStudents: 48,
      ),
      const BatchSectionInfo(
        sectionName: 'Section D',
        crName: 'Zarin Tasnim',
        crPhone: '+880 1711-234504',
        crEmail: 'cr.sec.d@leading.edu',
        totalStudents: 51,
      ),
      const BatchSectionInfo(
        sectionName: 'Section E',
        crName: 'Shahriar Kabir',
        crPhone: '+880 1711-234505',
        crEmail: 'cr.sec.e@leading.edu',
        totalStudents: 49,
      ),
      const BatchSectionInfo(
        sectionName: 'Section F',
        crName: 'Sumaiya Akter',
        crPhone: '+880 1711-234506',
        crEmail: 'cr.sec.f@leading.edu',
        totalStudents: 53,
      ),
      const BatchSectionInfo(
        sectionName: 'Section G',
        crName: 'Rayhan Ahmed',
        crPhone: '+880 1711-234507',
        crEmail: 'cr.sec.g@leading.edu',
        totalStudents: 47,
      ),
      const BatchSectionInfo(
        sectionName: 'Section H',
        crName: 'Sabrina Islam',
        crPhone: '+880 1711-234508',
        crEmail: 'cr.sec.h@leading.edu',
        totalStudents: 50,
      ),
      const BatchSectionInfo(
        sectionName: 'Section I',
        crName: 'Shuvo Sarker',
        crPhone: '+880 1711-234509',
        crEmail: 'cr.sec.i@leading.edu',
        totalStudents: 54,
      ),
    ]);
  }

  List<BatchResourceItem> getNotes({String? batchId}) {
    return _items.where((i) => i.type == BatchResourceType.notes).toList();
  }

  List<BatchResourceItem> getPYQs({String? batchId}) {
    return _items.where((i) => i.type == BatchResourceType.pyq).toList();
  }

  List<BatchResourceItem> getApprovedNotesByStudent(String studentName) {
    return _items
        .where((i) =>
            i.type == BatchResourceType.notes &&
            i.isApproved &&
            i.uploaderName.toLowerCase().trim() == studentName.toLowerCase().trim())
        .toList();
  }

  List<BatchResourceItem> getApprovedPYQsByStudent(String studentName) {
    return _items
        .where((i) =>
            i.type == BatchResourceType.pyq &&
            i.isApproved &&
            i.uploaderName.toLowerCase().trim() == studentName.toLowerCase().trim())
        .toList();
  }

  void addResource(BatchResourceItem item) {
    _items.insert(0, item);
  }

  void approveResource(String id, String adminName) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        isApproved: true,
        approvedByAdminName: adminName,
      );
    }
  }

  List<BatchSectionInfo> getSections() {
    return List.unmodifiable(_sections);
  }
}
