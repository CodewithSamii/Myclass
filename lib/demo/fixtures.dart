import '../core/models.dart';

/// Entire fixture set is fictional. Routes and people are NOT university notices.
abstract final class Fixtures {
  static const university = University(
    'mu',
    'Metropolitan University',
    'Asia/Dhaka',
  );
  static const departments = [
    Department('cse', 'Computer Science & Engineering', 'CSE'),
    Department('bba', 'Business Administration', 'Business'),
    Department('law', 'Law & Justice', 'Law'),
    Department('eng', 'English', 'English'),
  ];
  static const programs = [
    AcademicProgram(
      id: 'bsc-cse',
      name: 'B.Sc. in Computer Science & Engineering',
      shortName: 'B.Sc. in CSE',
      departmentId: 'cse',
      type: 'Undergraduate',
    ),
    AcademicProgram(
      id: 'bba',
      name: 'Bachelor of Business Administration',
      shortName: 'BBA',
      departmentId: 'bba',
      type: 'Undergraduate',
    ),
    AcademicProgram(
      id: 'llb',
      name: 'Bachelor of Laws',
      shortName: 'LLB',
      departmentId: 'law',
      type: 'Undergraduate',
    ),
    AcademicProgram(
      id: 'ba-eng',
      name: 'B.A. in English',
      shortName: 'B.A. in English',
      departmentId: 'eng',
      type: 'Undergraduate',
    ),
    AcademicProgram(
      id: 'msc-cse',
      name: 'M.Sc. in Computer Science',
      shortName: 'M.Sc. in CS',
      departmentId: 'cse',
      type: 'Postgraduate',
    ),
    AcademicProgram(
      id: 'mba',
      name: 'Master of Business Administration',
      shortName: 'MBA',
      departmentId: 'bba',
      type: 'Postgraduate',
    ),
    AcademicProgram(
      id: 'llm',
      name: 'Master of Laws',
      shortName: 'LLM',
      departmentId: 'law',
      type: 'Postgraduate',
    ),
    AcademicProgram(
      id: 'ma-eng',
      name: 'M.A. in English',
      shortName: 'M.A. in English',
      departmentId: 'eng',
      type: 'Postgraduate',
    ),
  ];
  static const courses = [
    Course(
      id: 'ai',
      name: 'Artificial Intelligence',
      code: 'CSE 421',
      facultyId: 'f1',
      departmentId: 'cse',
      shortName: 'Artificial Intelligence',
    ),
    Course(
      id: 'db',
      name: 'Database Management Systems',
      code: 'CSE 311',
      facultyId: 'f2',
      departmentId: 'cse',
      shortName: 'Database Systems',
    ),
    Course(
      id: 'cn',
      name: 'Computer Networks',
      code: 'CSE 331',
      facultyId: 'f3',
      departmentId: 'cse',
    ),
    Course(
      id: 'se',
      name: 'Software Engineering',
      code: 'CSE 321',
      facultyId: 'f4',
      departmentId: 'cse',
    ),
    Course(
      id: 'os',
      name: 'Operating Systems',
      code: 'CSE 313',
      facultyId: 'f5',
      departmentId: 'cse',
    ),
    Course(
      id: 'compiler',
      name: 'Compiler Design and Advanced Language Processing',
      code: 'CSE 411',
      facultyId: 'f6',
      departmentId: 'cse',
      shortName: 'Compiler Design',
    ),
    Course(
      id: 'research',
      name: 'Research Methods and Professional Communication for Computing',
      facultyId: 'f4',
      departmentId: 'cse',
      shortName: 'Research Methods',
    ),
    Course(
      id: 'acc',
      name: 'Financial Accounting',
      code: 'ACC 201',
      facultyId: 'f7',
      departmentId: 'bba',
    ),
    Course(
      id: 'mkt',
      name: 'Principles of Marketing',
      code: 'MKT 211',
      facultyId: 'f8',
      departmentId: 'bba',
    ),
    Course(
      id: 'law',
      name: 'Constitutional Law of Bangladesh',
      code: 'LAW 203',
      facultyId: 'f9',
      departmentId: 'law',
    ),
    Course(
      id: 'lit',
      name: 'Modern British Literature',
      code: 'ENG 302',
      facultyId: 'f10',
      departmentId: 'eng',
    ),
  ];
  static const faculty = [
    FacultyMember(
      id: 'f1',
      name: 'Ishrar Rahman',
      designation: 'Lecturer',
      departmentId: 'cse',
      email: 'ishrar.rahman@example.edu',
      office: 'Faculty room 408',
      officeHours: 'Monday & Wednesday · 2:00–3:00 PM',
      interests: ['Artificial intelligence', 'Human-computer interaction'],
    ),
    FacultyMember(
      id: 'f2',
      name: 'Dr. Farhan Ahmed',
      designation: 'Associate Professor',
      departmentId: 'cse',
      email: 'farhan.ahmed@example.edu',
      office: 'Room 405',
      interests: ['Data systems', 'Distributed computing'],
    ),
    FacultyMember(
      id: 'f3',
      name: 'Nusrat Jahan',
      designation: 'Assistant Professor',
      departmentId: 'cse',
      email: 'nusrat.jahan@example.edu',
      office: 'Room 502',
      interests: ['Computer networks', 'Network security'],
    ),
    FacultyMember(
      id: 'f4',
      name: 'Rafiq Hasan',
      designation: 'Senior Lecturer',
      departmentId: 'cse',
      email: 'rafiq.hasan@example.edu',
      office: 'Room 409',
      interests: ['Software architecture', 'Research methods'],
    ),
    FacultyMember(
      id: 'f5',
      name: 'Samira Chowdhury',
      designation: 'Lecturer',
      departmentId: 'cse',
      email: 'samira.chowdhury@example.edu',
      office: 'Room 406',
    ),
    FacultyMember(
      id: 'f6',
      name: 'Dr. Abdullah Al Mahmud Chowdhury',
      designation: 'Professor',
      departmentId: 'cse',
      email: 'abdullah.chowdhury@example.edu',
      office: 'Room 411',
      interests: ['Programming languages', 'Compilers'],
    ),
    FacultyMember(
      id: 'f7',
      name: 'Tahmina Akter',
      designation: 'Assistant Professor',
      departmentId: 'bba',
      email: 'tahmina.akter@example.edu',
      office: 'Business faculty · 204',
    ),
    FacultyMember(
      id: 'f8',
      name: 'Rezaul Karim',
      designation: 'Lecturer',
      departmentId: 'bba',
      email: 'rezaul.karim@example.edu',
      office: 'Room 205',
    ),
    FacultyMember(
      id: 'f9',
      name: 'Dr. Sadia Sultana',
      designation: 'Associate Professor',
      departmentId: 'law',
      email: 'sadia.sultana@example.edu',
      office: 'Law faculty · 301',
    ),
    FacultyMember(
      id: 'f10',
      name: 'Arif Mahmud',
      designation: 'Lecturer',
      departmentId: 'eng',
      email: 'arif.mahmud@example.edu',
      office: 'Arts faculty · 302',
    ),
  ];
  static const routes = [
    BusRoute(
      id: 'r1',
      number: 1,
      name: 'Amberkhana',
      durationMinutes: 40,
      stops: [
        BusStop('Amberkhana', 0),
        BusStop('Chowhatta', 8),
        BusStop('Zindabazar', 14),
        BusStop('Tilagor', 27),
        BusStop('Campus', 40),
      ],
      departures: [
        BusDeparture(440),
        BusDeparture(520),
        BusDeparture(600),
        BusDeparture(870, toCampus: false),
        BusDeparture(960, toCampus: false),
        BusDeparture(1050, toCampus: false),
      ],
    ),
    BusRoute(
      id: 'r2',
      number: 2,
      name: 'Subidbazar',
      durationMinutes: 45,
      stops: [
        BusStop('Subidbazar', 0),
        BusStop('Pathantula', 8),
        BusStop('Mira Bazar', 22),
        BusStop('Shibganj', 30),
        BusStop('Campus', 45),
      ],
      departures: [
        BusDeparture(430),
        BusDeparture(510),
        BusDeparture(880, toCampus: false),
        BusDeparture(1020, toCampus: false),
      ],
      notice: 'The afternoon return leaves from the east gate.',
    ),
    BusRoute(
      id: 'r3',
      number: 3,
      name: 'South Surma',
      durationMinutes: 55,
      stops: [
        BusStop('South Surma', 0),
        BusStop('Kadamtali', 12),
        BusStop('Bandar Bazar', 24),
        BusStop('Tilagor', 40),
        BusStop('Campus', 55),
      ],
      departures: [
        BusDeparture(420),
        BusDeparture(500),
        BusDeparture(900, toCampus: false),
        BusDeparture(1035, toCampus: false),
      ],
    ),
    BusRoute(
      id: 'r4',
      number: 4,
      name: 'Shahporan',
      durationMinutes: 25,
      stops: [
        BusStop('Shahporan Gate', 0),
        BusStop('Major Tila', 7),
        BusStop('Bateshwar', 17),
        BusStop('Campus', 25),
      ],
      departures: [
        BusDeparture(450),
        BusDeparture(540),
        BusDeparture(630),
        BusDeparture(850, toCampus: false),
        BusDeparture(950, toCampus: false),
        BusDeparture(1040, toCampus: false),
      ],
    ),
  ];
  static List<Course> coursesFor(String section) {
    final dept = section.startsWith('bba') || section.startsWith('mba')
        ? 'bba'
        : section.startsWith('ll')
        ? 'law'
        : section.contains('eng')
        ? 'eng'
        : 'cse';
    return courses.where((c) => c.departmentId == dept).toList();
  }

  static List<ClassSession> routine(String section) {
    final cs = coursesFor(section);
    return [
      for (final day in [7, 1, 2, 3, 4])
        for (var i = 0; i < 3; i++)
          ClassSession(
            id: '$section-$day-$i',
            sectionId: section,
            courseId: cs[(day == 1 ? i : day + i) % cs.length].id,
            weekday: day,
            startMinute: [630, 750, 870][i],
            endMinute: [710, 830, 950][i],
            room: day == 2 && i == 2 ? null : ['403', '501', 'Lab 2'][i],
            isLab: i == 2,
            cancelled: day == 3 && i == 1,
            changed: day == 1 && i == 0,
          ),
    ];
  }

  static List<AcademicEvent> events(String section) {
    final cs = coursesFor(section);
    String cid(int i) => cs[i % cs.length].id;
    AcademicEvent e(
      String id,
      String title,
      AcademicEventType type,
      int day,
      int hour,
      int minute,
      int c, {
      List<String> syllabus = const [],
      EventStatus status = EventStatus.scheduled,
      String? location = '402',
      bool tba = false,
      List<Attachment> attachments = const [],
      String instructions =
          'Bring your completed work and arrive 10 minutes early.',
      List<ScheduleChange> history = const [],
    }) {
      final at = DateTime(2026, 9, day, hour, minute);
      final department = cs.first.departmentId;
      if (department != 'cse') {
        title = '${cs[c % cs.length].compactName} ${type.label.toLowerCase()}';
        if (syllabus.isNotEmpty) {
          syllabus = switch (department) {
            'bba' => [
              'Core concepts from lectures 1–6',
              'Case study analysis',
              'Applied exercises from the course guide',
            ],
            'law' => [
              'Constitutional principles',
              'Case law and legal reasoning',
              'Articles covered in lectures 1–6',
            ],
            _ => [
              'Assigned texts from weeks 1–6',
              'Critical analysis',
              'Context and themes',
            ],
          };
        }
        attachments = [];
        instructions = type.isDeadline
            ? 'Submit your completed work as a single PDF. Include your student ID.'
            : 'Prepare the published syllabus and bring your class notes.';
      }
      return AcademicEvent(
        id: '$section-$id',
        title: title,
        type: type,
        courseId: cid(c),
        date: DateTime(2026, 9, day),
        sectionId: section,
        createdAt: DateTime(2026, 9, 18),
        updatedAt: DateTime(2026, 9, 21, 10, 40),
        startsAt: type.isDeadline || tba ? null : at,
        endsAt: type.isDeadline || tba
            ? null
            : at.add(const Duration(minutes: 60)),
        deadline: type.isDeadline ? at : null,
        location: type.isDeadline ? null : location,
        syllabus: syllabus,
        status: status,
        attachments: attachments,
        instructions: instructions,
        changeHistory: history,
      );
    }

    const brief = Attachment(
      id: 'brief',
      name: 'Assignment Brief.pdf',
      kind: AttachmentKind.pdf,
      sizeLabel: '248 KB',
      preview:
          'DATABASE SYSTEMS · ASSIGNMENT 03\n\nDesign a normalized relational schema for a university library.\n\n1. Identify entities, keys and relationships.\n2. Normalize your schema to third normal form.\n3. Write five SQL queries with joins.\n4. Explain your indexing choices.\n\nSubmission: one PDF, including your ER diagram and queries.',
    );
    const topics = Attachment(
      id: 'topics',
      name: 'Viva Topics.pdf',
      kind: AttachmentKind.pdf,
      sizeLabel: '96 KB',
      preview:
          'NETWORKING VIVA\n\nOSI layers · TCP/IP · Routing algorithms · IPv4 subnetting\n\nPrepare to explain one worked subnetting example. Bring your lab report.',
    );
    return [
      e(
        'viva-ai',
        'AI viva',
        AcademicEventType.viva,
        21,
        14,
        0,
        0,
        syllabus: [
          'Adversarial search',
          'Minimax algorithm',
          'Alpha-beta pruning',
          'Heuristic evaluation functions',
        ],
        instructions:
            'Individual viva. Review the worked examples from lecture 7. Bring your handwritten search tree.',
      ),
      e(
        'db-assignment',
        'Database assignment 03',
        AcademicEventType.assignment,
        21,
        23,
        59,
        1,
        attachments: [brief],
        instructions:
            'Upload a single PDF. Include your student ID in the filename. Maximum 8 pages.',
      ),
      e(
        'network-viva',
        'Networking viva',
        AcademicEventType.viva,
        22,
        10,
        30,
        2,
        syllabus: [
          'OSI layers',
          'TCP/IP model',
          'Routing algorithms',
          'IPv4 subnetting',
        ],
        attachments: [topics],
        history: [
          ScheduleChange(
            id: 'ch1',
            label: 'Room changed',
            before: 'Room 401',
            after: 'Room 602',
            at: DateTime(2026, 9, 21, 10, 40),
            author: 'Class representative',
          ),
        ],
        location: '602',
        status: EventStatus.updated,
      ),
      e(
        'os-viva',
        'Operating systems viva',
        AcademicEventType.viva,
        22,
        11,
        0,
        4,
        syllabus: [
          'Process scheduling',
          'Deadlock prevention',
          'Memory allocation',
        ],
      ),
      e(
        'project',
        'Project proposal',
        AcademicEventType.project,
        22,
        23,
        59,
        3,
        instructions:
            'One proposal per group. Include problem statement, scope, and a rough implementation plan.',
      ),
      e(
        'report',
        'Lab report submission',
        AcademicEventType.report,
        22,
        23,
        59,
        2,
        attachments: [
          const Attachment(
            id: 'doc',
            name: 'Report template.docx',
            kind: AttachmentKind.document,
            sizeLabel: '42 KB',
            preview:
                'LAB REPORT\n\nObjective\nMethod\nObservations\nConclusion',
          ),
          const Attachment(
            id: 'img',
            name: 'Network topology.png',
            kind: AttachmentKind.image,
            sizeLabel: '186 KB',
            preview:
                'Reference diagram: three subnets connected through a router. This is a mock attachment preview.',
          ),
        ],
      ),
      e(
        'quiz',
        'AI quiz',
        AcademicEventType.quiz,
        22,
        10,
        45,
        0,
        syllabus: ['Search algorithms'],
        location: null,
      ),
      e(
        'se-assignment',
        'Software requirements draft',
        AcademicEventType.assignment,
        22,
        18,
        0,
        3,
      ),
      e(
        'presentation',
        'System design presentation',
        AcademicEventType.presentation,
        23,
        12,
        30,
        3,
        syllabus: [
          'Architecture overview',
          'Component boundaries',
          'Data flow',
        ],
        instructions:
            'Groups of four. Seven minutes to present, followed by three minutes for questions.',
      ),
      e(
        'midterm',
        'Artificial Intelligence midterm',
        AcademicEventType.exam,
        24,
        9,
        0,
        0,
        syllabus: [
          'Intelligent agents and environments',
          'Uninformed search: BFS, DFS, uniform cost',
          'Informed search: A* and greedy search',
          'Adversarial search and game trees',
          'Minimax and alpha-beta pruning',
          'Constraint satisfaction problems',
          'Propositional logic',
          'Knowledge representation',
          'Bayesian inference fundamentals',
          'Worked problems from tutorials 1–6',
        ],
        attachments: [
          const Attachment(
            id: 'exam',
            name: 'Exam Syllabus.pdf',
            kind: AttachmentKind.pdf,
            sizeLabel: '180 KB',
            preview:
                'MIDTERM EXAMINATION\n\nDuration: 90 minutes.\nAnswer all short questions and any two long questions.\nCalculators permitted. No handwritten notes.',
          ),
        ],
      ),
      e(
        'research',
        'Research outline',
        AcademicEventType.assignment,
        25,
        23,
        59,
        6,
        instructions:
            'Prepare a one-page research question and include three relevant references.',
      ),
      e(
        'postponed',
        'Compiler design viva',
        AcademicEventType.viva,
        28,
        11,
        0,
        5,
        status: EventStatus.postponed,
        syllabus: [],
        history: [
          ScheduleChange(
            id: 'ch2',
            label: 'Viva postponed',
            before: 'Sep 23 · 11:00 AM',
            after: 'Sep 28 · 11:00 AM',
            at: DateTime(2026, 9, 20, 16),
            author: 'Class representative',
          ),
        ],
      ),
      e(
        'cancelled',
        'Networks class test',
        AcademicEventType.classTest,
        23,
        15,
        0,
        2,
        status: EventStatus.cancelled,
        instructions:
            'Cancelled by the course faculty. A revised assessment plan will be shared.',
      ),
      e(
        'tba',
        'Operating systems lab exam',
        AcademicEventType.labExam,
        30,
        0,
        0,
        4,
        tba: true,
        location: null,
        syllabus: [
          'Shell scripting',
          'Process synchronization',
          'Scheduling simulation',
        ],
      ),
      e(
        'long',
        'Research methods and professional communication: literature review presentation',
        AcademicEventType.presentation,
        29,
        14,
        0,
        6,
        attachments: [
          brief,
          topics,
          const Attachment(
            id: 'data',
            name: 'Reference dataset.csv',
            kind: AttachmentKind.file,
            sizeLabel: '18 KB',
            preview:
                'author,year,topic\nRahman,2024,Human-computer interaction',
          ),
        ],
      ),
      e(
        'past',
        'Database assignment 02',
        AcademicEventType.assignment,
        19,
        23,
        59,
        1,
        status: EventStatus.completed,
      ),
      e(
        'late',
        'Bring your project logbook',
        AcademicEventType.general,
        21,
        16,
        0,
        3,
        instructions:
            'Added this morning. Bring your logbook for a brief progress review.',
      ),
    ];
  }
}
