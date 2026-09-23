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
      id: 'cse3115',
      name: 'Numerical Methods',
      code: 'CSE 3115',
      facultyId: 'f1',
      departmentId: 'cse',
      shortName: 'Numerical Methods',
    ),
    Course(
      id: 'cse3116',
      name: 'Numerical Methods Lab',
      code: 'CSE 3116',
      facultyId: 'f1',
      departmentId: 'cse',
      shortName: 'Numerical Methods Lab',
    ),
    Course(
      id: 'cse3213',
      name: 'Software Engineering',
      code: 'CSE 3213',
      facultyId: 'f4',
      departmentId: 'cse',
      shortName: 'Software Engineering',
    ),
    Course(
      id: 'cse3212',
      name: 'Smartphone App Development Lab',
      code: 'CSE 3212',
      facultyId: 'f2',
      departmentId: 'cse',
      shortName: 'Smartphone App Lab',
    ),
    Course(
      id: 'cse3214',
      name: 'Software Engineering Sessional',
      code: 'CSE 3214',
      facultyId: 'f4',
      departmentId: 'cse',
      shortName: 'SE Sessional',
    ),
    Course(
      id: 'cse2231',
      name: 'Data Communications',
      code: 'CSE 2231',
      facultyId: 'f3',
      departmentId: 'cse',
      shortName: 'Data Communications',
    ),
    Course(
      id: 'ged1291',
      name: 'Principles of Accounting',
      code: 'GED 1291',
      facultyId: 'f7',
      departmentId: 'cse',
      shortName: 'Principles of Accounting',
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

  static const defaultTimeSlots = [
    TimeSlot(id: 'ts1', label: '9:00–10:05', startMinute: 540, endMinute: 605, orderIndex: 0),
    TimeSlot(id: 'ts2', label: '10:05–11:10', startMinute: 605, endMinute: 670, orderIndex: 1),
    TimeSlot(id: 'ts3', label: '11:10–12:15', startMinute: 670, endMinute: 735, orderIndex: 2),
    TimeSlot(id: 'ts4', label: '12:15–1:20', startMinute: 735, endMinute: 800, orderIndex: 3),
    TimeSlot(id: 'ts5', label: '1:20–1:50', startMinute: 800, endMinute: 830, orderIndex: 4),
    TimeSlot(id: 'ts6', label: '1:50–2:55', startMinute: 830, endMinute: 895, orderIndex: 5),
    TimeSlot(id: 'ts7', label: '2:55–4:00', startMinute: 895, endMinute: 960, orderIndex: 6),
    TimeSlot(id: 'ts8', label: '4:00–5:05', startMinute: 960, endMinute: 1025, orderIndex: 7),
  ];

  static List<ClassSession> routine(String section) {
    return [
      // Sunday (weekday 7)
      ClassSession(
        id: '$section-sun-3',
        sectionId: section,
        courseId: 'cse2231',
        weekday: 7,
        startMinute: 670,
        endMinute: 735,
        room: 'ACL-302',
      ),
      ClassSession(
        id: '$section-sun-4',
        sectionId: section,
        courseId: 'cse3214',
        weekday: 7,
        startMinute: 735,
        endMinute: 800,
        room: 'ACL-4',
        isLab: true,
      ),
      ClassSession(
        id: '$section-sun-6',
        sectionId: section,
        courseId: 'cse3116',
        weekday: 7,
        startMinute: 830,
        endMinute: 895,
        room: 'ACL-4',
        isLab: true,
      ),
      ClassSession(
        id: '$section-sun-7',
        sectionId: section,
        courseId: 'ged1291',
        weekday: 7,
        startMinute: 895,
        endMinute: 960,
        room: 'RKB-402',
      ),
      ClassSession(
        id: '$section-sun-8',
        sectionId: section,
        courseId: 'cse3115',
        weekday: 7,
        startMinute: 960,
        endMinute: 1025,
        room: 'RKB-103',
      ),

      // Monday (weekday 1)
      ClassSession(
        id: '$section-mon-4',
        sectionId: section,
        courseId: 'cse3214',
        weekday: 1,
        startMinute: 735,
        endMinute: 800,
        room: 'ACL-3',
        isLab: true,
      ),
      ClassSession(
        id: '$section-mon-6',
        sectionId: section,
        courseId: 'ged1291',
        weekday: 1,
        startMinute: 830,
        endMinute: 895,
        room: 'RKB-303',
      ),
      ClassSession(
        id: '$section-mon-7',
        sectionId: section,
        courseId: 'cse2231',
        weekday: 1,
        startMinute: 895,
        endMinute: 960,
        room: 'RKB-407',
      ),

      // Tuesday (weekday 2)
      ClassSession(
        id: '$section-tue-1',
        sectionId: section,
        courseId: 'cse3115',
        weekday: 2,
        startMinute: 540,
        endMinute: 605,
        room: 'RKB-407',
      ),
      ClassSession(
        id: '$section-tue-2',
        sectionId: section,
        courseId: 'cse3116',
        weekday: 2,
        startMinute: 605,
        endMinute: 670,
        room: 'ACL-1',
        isLab: true,
      ),

      // Wednesday (weekday 3)
      ClassSession(
        id: '$section-wed-6',
        sectionId: section,
        courseId: 'cse3213',
        weekday: 3,
        startMinute: 830,
        endMinute: 895,
        room: 'RKB-403',
      ),
      ClassSession(
        id: '$section-wed-7',
        sectionId: section,
        courseId: 'cse3212',
        weekday: 3,
        startMinute: 895,
        endMinute: 960,
        room: 'ACL-4',
        isLab: true,
      ),

      // Thursday (weekday 4) - No classes

      // Friday (weekday 5)
      ClassSession(
        id: '$section-fri-1',
        sectionId: section,
        courseId: 'cse3212',
        weekday: 5,
        startMinute: 540,
        endMinute: 605,
        room: 'ACL-2',
        isLab: true,
      ),
      ClassSession(
        id: '$section-fri-2',
        sectionId: section,
        courseId: 'cse3213',
        weekday: 5,
        startMinute: 605,
        endMinute: 670,
        room: 'RKB-402',
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
      String? location = 'RKB-407',
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
          'SOFTWARE ENGINEERING · ASSIGNMENT 03\n\nDesign architectural diagrams and UML class structures.\n\n1. Identify system boundaries and actors.\n2. Create sequence diagrams for primary use cases.\n3. Detail exception handling mechanisms.\n\nSubmission: one PDF.',
    );
    const topics = Attachment(
      id: 'topics',
      name: 'Viva Topics.pdf',
      kind: AttachmentKind.pdf,
      sizeLabel: '96 KB',
      preview:
          'DATA COMMUNICATIONS VIVA\n\nOSI layers · TCP/IP · Routing algorithms · IPv4 subnetting\n\nPrepare to explain one worked subnetting example. Bring your lab report.',
    );
    return [
      e(
        'network-viva',
        'Data Communications Viva',
        AcademicEventType.viva,
        22,
        10,
        30,
        5,
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
            after: 'Room RKB-407',
            at: DateTime(2026, 9, 21, 10, 40),
            author: 'Class representative',
          ),
        ],
        location: 'RKB-407',
        status: EventStatus.updated,
      ),
      e(
        'num-viva',
        'Numerical Methods Viva',
        AcademicEventType.viva,
        22,
        11,
        0,
        0,
        syllabus: [
          'Root finding algorithms',
          'Matrix inversion',
        ],
      ),
      e(
        'project',
        'Smartphone App Project Proposal',
        AcademicEventType.project,
        22,
        23,
        59,
        3,
        instructions:
            'One proposal per group. Include problem statement and UI wireframes.',
      ),
      e(
        'report',
        'Numerical Methods Lab Report',
        AcademicEventType.report,
        22,
        23,
        59,
        1,
      ),
      e(
        'se-assignment',
        'Software Requirements Draft',
        AcademicEventType.assignment,
        22,
        18,
        0,
        2,
      ),
      e(
        'quiz',
        'Data Communications Quiz',
        AcademicEventType.quiz,
        22,
        10,
        45,
        5,
      ),
      e(
        'cancelled-test',
        'Data Communications Class Test',
        AcademicEventType.quiz,
        23,
        11,
        15,
        5,
        status: EventStatus.cancelled,
      ),
      e(
        'midterm',
        'Numerical Methods Midterm Exam',
        AcademicEventType.exam,
        24,
        9,
        0,
        0,
        location: 'RKB-103',
        syllabus: [
          'Root finding: Bisection, Newton-Raphson',
          'Linear systems: Gauss elimination',
          'Interpolation and Lagrange polynomials',
          'Numerical integration and differentiation',
        ],
      ),
      e(
        'db-tutorial',
        'Database Tutorial',
        AcademicEventType.general,
        25,
        10,
        0,
        0,
        location: 'RKB-407',
        instructions: 'Bring your tutorial exercises and notes.',
      ),
      e(
        'cse-quiz',
        'CSE Quiz',
        AcademicEventType.quiz,
        25,
        13,
        0,
        5,
        location: 'ACL-302',
        syllabus: ['Framing', 'Error detection', 'Flow control'],
      ),
      e(
        'project-pres',
        'Project Presentation',
        AcademicEventType.presentation,
        25,
        15,
        0,
        3,
        location: 'ACL-4',
        syllabus: ['App structure', 'State management', 'API integration'],
        instructions: 'Groups of three. 8 minutes per presentation.',
      ),
      e(
        'db-assignment',
        'Database Assignment 3 Due',
        AcademicEventType.assignment,
        25,
        23,
        15,
        2,
        attachments: [brief],
        instructions:
            'Upload a single PDF. Include your student ID in the filename. Maximum 8 pages.',
      ),
      e(
        'cse-pres',
        'CSE Presentation',
        AcademicEventType.presentation,
        26,
        14,
        0,
        4,
        location: 'ACL-3',
        syllabus: ['Requirements engineering', 'System design patterns'],
      ),
      e(
        'accounting-exam',
        'Principles of Accounting Assessment',
        AcademicEventType.exam,
        29,
        11,
        0,
        6,
        location: 'RKB-402',
      ),
      e(
        'tba-exam',
        'Smartphone App Development Lab Exam',
        AcademicEventType.labExam,
        30,
        0,
        0,
        3,
        tba: true,
        location: null,
      ),
      e(
        'past-ass',
        'Numerical Methods Assignment 1',
        AcademicEventType.assignment,
        19,
        23,
        59,
        0,
        status: EventStatus.completed,
      ),
    ];
  }
}
