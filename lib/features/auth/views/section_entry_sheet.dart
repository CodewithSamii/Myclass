import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/auth_bloc.dart';
import '../../teacher/services/teacher_section_service.dart';

class SectionEntrySheet extends StatefulWidget {
  const SectionEntrySheet({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<SectionEntrySheet> createState() => _SectionEntrySheetState();
}

class _SectionEntrySheetState extends State<SectionEntrySheet> {
  late int tabIndex; // 0: Join Classroom, 1: Create Classroom, 2: Teacher Mode

  // University state
  List<University> universities = [];
  University? selectedUniversity;
  University? createUniversity;

  // Join flow state
  Department? selectedDept;
  Batch? selectedBatch;
  Section? selectedSection;
  bool isEnteringAsAdmin = false;
  final TextEditingController joinNameController = TextEditingController(text: 'user');
  final TextEditingController joinPasswordController = TextEditingController();
  bool joinObscurePassword = true;

  // Create flow state
  Department? createDept;
  final TextEditingController createDeptNameController = TextEditingController(text: 'Computer Science & Engineering');
  final TextEditingController createBatchController = TextEditingController(text: '64');
  final TextEditingController createSectionController = TextEditingController(text: 'Section D');
  final TextEditingController createCreatorNameController = TextEditingController(text: 'user');
  final TextEditingController createSectionCodeController = TextEditingController();
  final TextEditingController confirmSectionCodeController = TextEditingController();
  bool createObscureCode = true;
  bool confirmObscureCode = true;
  bool createSuccess = false;
  String? createMessage;

  // Teacher flow state
  int teacherAuthTab = 0; // 0: Sign In, 1: Sign Up
  final TextEditingController teacherNameController = TextEditingController();
  final TextEditingController teacherEmailController = TextEditingController();
  final TextEditingController teacherPassController = TextEditingController();
  final TextEditingController teacherSectionCodeController = TextEditingController();
  bool teacherObscurePass = true;
  bool isAddingTeacherSection = false;

  // Owner pass controller (kept for fallback)
  final TextEditingController ownerPassController = TextEditingController();

  List<Department> departments = [];
  List<Department> createDepartments = [];
  List<Batch> batches = [];
  List<Section> sections = [];
  bool loadingData = false;
  String? errorMessage;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    tabIndex = widget.initialTab;
    _loadInitialData();
  }

  @override
  void dispose() {
    joinNameController.dispose();
    joinPasswordController.dispose();
    createDeptNameController.dispose();
    createBatchController.dispose();
    createSectionController.dispose();
    createCreatorNameController.dispose();
    createSectionCodeController.dispose();
    confirmSectionCodeController.dispose();
    ownerPassController.dispose();
    teacherNameController.dispose();
    teacherEmailController.dispose();
    teacherPassController.dispose();
    teacherSectionCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => loadingData = true);
    try {
      final repo = context.read<AcademicStructureRepository>();
      final uList = await repo.universities();

      // Find Leading University as default, or fallback to first
      final defaultUni = uList.firstWhere(
        (u) => u.name == 'Leading University' || u.id == 'lu',
        orElse: () => uList.isNotEmpty ? uList.first : const University('lu', 'Leading University', 'Asia/Dhaka'),
      );

      final depts = await repo.departments('Undergraduate', universityId: defaultUni.id);

      setState(() {
        universities = uList;
        selectedUniversity = defaultUni;
        createUniversity = defaultUni;
        departments = depts;
        createDepartments = depts;
        if (depts.isNotEmpty) {
          selectedDept = depts.first;
          createDept = depts.first;
          createDeptNameController.text = depts.first.name;
        } else {
          selectedDept = null;
          createDept = null;
        }
      });

      if (selectedDept != null) {
        await _loadBatchesForDept(selectedDept!, universityId: defaultUni.id);
      }
    } catch (e) {
      setState(() => errorMessage = 'Failed to load initial academic data: $e');
    } finally {
      setState(() => loadingData = false);
    }
  }

  Future<void> _onUniversityChanged(University uni, {required bool isCreate}) async {
    if (!isCreate) {
      if (selectedUniversity?.id == uni.id) return;
      setState(() {
        selectedUniversity = uni;
        selectedDept = null;
        selectedBatch = null;
        selectedSection = null;
        departments = [];
        batches = [];
        sections = [];
        errorMessage = null;
        loadingData = true;
      });

      try {
        final repo = context.read<AcademicStructureRepository>();
        final depts = await repo.departments('Undergraduate', universityId: uni.id);
        setState(() {
          departments = depts;
          if (depts.isNotEmpty) {
            selectedDept = depts.first;
          } else {
            selectedDept = null;
            selectedBatch = null;
            selectedSection = null;
            batches = [];
            sections = [];
          }
        });

        if (selectedDept != null) {
          await _loadBatchesForDept(selectedDept!, universityId: uni.id);
        }
      } catch (e) {
        setState(() => errorMessage = 'Failed to load university departments: $e');
      } finally {
        setState(() => loadingData = false);
      }
    } else {
      if (createUniversity?.id == uni.id) return;
      setState(() {
        createUniversity = uni;
        createDept = null;
        createDepartments = [];
      });

      try {
        final repo = context.read<AcademicStructureRepository>();
        final depts = await repo.departments('Undergraduate', universityId: uni.id);
        setState(() {
          createDepartments = depts;
          if (depts.isNotEmpty) {
            createDept = depts.first;
            createDeptNameController.text = depts.first.name;
          } else {
            createDept = null;
          }
        });
      } catch (e) {
        setState(() => errorMessage = 'Failed to load university departments: $e');
      }
    }
  }

  Future<void> _loadBatchesForDept(Department dept, {String? universityId}) async {
    try {
      final repo = context.read<AcademicStructureRepository>();
      final uId = universityId ?? selectedUniversity?.id;
      final progs = await repo.programs(dept.id, 'Undergraduate', universityId: uId);
      if (progs.isNotEmpty) {
        final bList = await repo.batches(progs.first.id);
        setState(() {
          batches = bList;
          if (bList.isNotEmpty) {
            selectedBatch = bList.firstWhere(
              (b) => b.label.contains('64'),
              orElse: () => bList.first,
            );
          } else {
            selectedBatch = null;
          }
        });
        if (selectedBatch != null) {
          await _loadSectionsForBatch(selectedBatch!);
        }
      } else {
        setState(() {
          batches = [];
          selectedBatch = null;
          sections = [];
          selectedSection = null;
        });
      }
    } catch (e) {
      setState(() => errorMessage = 'Failed to load batches: $e');
    }
  }

  Future<void> _loadSectionsForBatch(Batch batch) async {
    try {
      final repo = context.read<AcademicStructureRepository>();
      final sList = await repo.approvedSections(batch.id);
      setState(() {
        sections = sList;
        if (sList.isNotEmpty) {
          selectedSection = sList.firstWhere(
            (s) => s.label.contains('Section I') || s.label.endsWith('I') || s.id.endsWith('-I'),
            orElse: () => sList.first,
          );
        } else {
          selectedSection = null;
        }
      });
    } catch (e) {
      setState(() => errorMessage = 'Failed to load classrooms: $e');
    }
  }

  void _showUniversityPicker(BuildContext context, {required bool isCreate}) {
    final c = context.colors;
    final currentSelected = isCreate ? createUniversity : selectedUniversity;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _UniversitySearchSheet(
          universities: universities,
          selected: currentSelected,
          onSelected: (uni) {
            Navigator.of(sheetContext).pop();
            _onUniversityChanged(uni, isCreate: isCreate);
          },
        );
      },
    );
  }

  void _authenticateAsOwner() {
    const membership = SectionMembership(
      sectionId: 'bsc-cse-64-I',
      departmentId: 'cse',
      programId: 'bsc-cse',
      batchId: 'bsc-cse-64',
      programName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
      sectionName: 'Section I',
      universityId: 'lu',
      universityName: 'Leading University',
      role: UserRole.myClassOwner,
    );

    context.read<AuthBloc>().add(
      AuthSectionLoggedIn(
        name: 'Saminul Islam Sami',
        membership: membership,
        grant: const SectionGrant('bsc-cse-64-I', 'owner-token', role: UserRole.myClassOwner),
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _joinClassroom() async {
    final userName = joinNameController.text.trim();
    final password = joinPasswordController.text.trim();

    // Universal Owner Credentials Check: sami / sami or master keys
    if ((userName.toLowerCase() == 'sami' && password == 'sami') ||
        (password == 'sami' && userName.toLowerCase() == 'sami') ||
        password == 'yyoyyo') {
      _authenticateAsOwner();
      return;
    }

    if (selectedUniversity == null) {
      setState(() => errorMessage = 'Please select a university first.');
      return;
    }
    if (selectedSection == null) {
      setState(() => errorMessage = 'Please select a classroom first.');
      return;
    }
    if (password.isEmpty) {
      setState(() => errorMessage = 'Please enter the section code.');
      return;
    }

    setState(() {
      submitting = true;
      errorMessage = null;
    });

    try {
      final repo = context.read<AcademicStructureRepository>();
      final grant = await repo.verifyRoleAccess(
        selectedSection!.id,
        isAdmin: isEnteringAsAdmin,
        password: password,
      );

      if (!mounted) return;

      final membership = SectionMembership(
        sectionId: selectedSection!.id,
        departmentId: selectedDept?.id ?? 'cse',
        programId: selectedBatch?.programId ?? 'bsc-cse',
        batchId: selectedBatch?.id ?? 'bsc-cse-64',
        programName: selectedDept?.name ?? 'Computer Science & Engineering',
        batchName: selectedBatch?.label ?? 'Batch 64',
        sectionName: selectedSection!.label,
        universityId: selectedUniversity?.id ?? 'lu',
        universityName: selectedUniversity?.name ?? 'Leading University',
        role: grant.role,
      );

      final userName = joinNameController.text.trim().isEmpty
          ? 'user'
          : joinNameController.text.trim();

      context.read<AuthBloc>().add(
        AuthSectionLoggedIn(
          name: userName,
          membership: membership,
          grant: grant,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        errorMessage = e is AppFailure ? e.message : e.toString();
        submitting = false;
      });
    }
  }

  Future<void> _createClassroom() async {
    final batchText = createBatchController.text.trim();
    final sectionName = createSectionController.text.trim();
    final creatorName = createCreatorNameController.text.trim();
    final sectionCode = createSectionCodeController.text.trim();
    final confirmCode = confirmSectionCodeController.text.trim();

    final deptName = createDept != null
        ? createDept!.name
        : createDeptNameController.text.trim();
    final deptId = createDept != null
        ? createDept!.id
        : deptName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    if (createUniversity == null) {
      setState(() => errorMessage = 'Please select a university.');
      return;
    }
    if (deptName.isEmpty || batchText.isEmpty || sectionName.isEmpty) {
      setState(() => errorMessage = 'Please fill out all department and section fields.');
      return;
    }
    if (sectionCode.isEmpty) {
      setState(() => errorMessage = 'Please enter a Section Code.');
      return;
    }
    if (confirmCode.isEmpty) {
      setState(() => errorMessage = 'Please confirm the Section Code.');
      return;
    }
    if (sectionCode != confirmCode) {
      setState(() => errorMessage = 'Section Codes do not match. Please verify.');
      return;
    }

    setState(() {
      submitting = true;
      errorMessage = null;
    });

    try {
      final repo = context.read<AcademicStructureRepository>();
      final batchId = 'bsc-$deptId-$batchText';
      final batchLabel = batchText.startsWith('Batch') ? batchText : 'Batch $batchText';

      final created = await repo.createSection(
        universityId: createUniversity!.id,
        universityName: createUniversity!.name,
        departmentId: deptId,
        departmentName: deptName,
        batchId: batchId,
        batchName: batchLabel,
        sectionName: sectionName,
        adminPassword: sectionCode,
        studentPassword: sectionCode,
        creatorName: creatorName.isEmpty ? 'user' : creatorName,
      );

      setState(() {
        submitting = false;
        createSuccess = true;
        createMessage =
            'Classroom "${created.label}" for ${createUniversity!.name} requested successfully! It has been submitted for MyClass Owner verification and approval.';
      });
    } catch (e) {
      setState(() {
        errorMessage = e is AppFailure ? e.message : e.toString();
        submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight = screenHeight - bottomInset;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: Motion.fast,
      curve: Motion.curve,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: bottomInset > 0
              ? (availableHeight > 240 ? availableHeight - 16 : availableHeight)
              : screenHeight * 0.90,
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Academic Classroom',
                    style: context.type.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab switcher
            ChoiceBar<int>(
              values: const [0, 1, 2],
              selected: tabIndex,
              label: (i) => switch (i) {
                0 => 'Join Classroom',
                1 => 'Create Classroom',
                _ => 'Teacher Mode',
              },
              onChanged: (i) {
                setState(() {
                  tabIndex = i;
                  errorMessage = null;
                  createSuccess = false;
                  isAddingTeacherSection = false;
                });
              },
            ),
            const SizedBox(height: 16),
            if (errorMessage != null) ...[
              ErrorNotice(errorMessage!),
              const SizedBox(height: 14),
            ],
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 40),
                child: switch (tabIndex) {
                  0 => _buildJoinTab(c),
                  1 => _buildCreateTab(c),
                  _ => _buildTeacherTab(c),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTab(MyClassColors c) {
    if (loadingData && universities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your University, Department, Batch, and approved Section to enter:',
          style: context.type.bodyMedium?.copyWith(color: c.secondary),
        ),
        const SizedBox(height: 16),

        // 1. University Selector (Above Department)
        Label('University', color: c.secondary),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showUniversityPicker(context, isCreate: false),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.building_2_fill, size: 18, color: c.sage),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedUniversity?.name ?? 'Select University',
                    style: context.type.bodyMedium?.copyWith(
                      color: selectedUniversity != null ? c.ink : c.faint,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(CupertinoIcons.chevron_down, size: 16, color: c.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Department Selector
        Label('Department', color: c.secondary),
        const SizedBox(height: 6),
        if (loadingData)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.line),
            ),
            child: const Center(child: CupertinoActivityIndicator()),
          )
        else if (departments.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.subtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No departments configured yet for ${selectedUniversity?.name ?? 'this university'}. Switch to "Create Classroom" to request one.',
              style: context.type.bodySmall?.copyWith(color: c.secondary, height: 1.35),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Department>(
                isExpanded: true,
                value: selectedDept,
                items: departments
                    .map((d) => DropdownMenuItem(value: d, child: Text('${d.shortName} - ${d.name}')))
                    .toList(),
                onChanged: (d) {
                  if (d != null) {
                    setState(() {
                      selectedDept = d;
                      selectedBatch = null;
                      selectedSection = null;
                      batches = [];
                      sections = [];
                    });
                    _loadBatchesForDept(d, universityId: selectedUniversity?.id);
                  }
                },
              ),
            ),
          ),
        const SizedBox(height: 14),

        // 3. Batch Selector (Dependent on Department)
        if (departments.isNotEmpty) ...[
          Label('Batch', color: c.secondary),
          const SizedBox(height: 6),
          if (batches.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.subtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No batches found for this department.',
                style: context.type.bodySmall?.copyWith(color: c.secondary),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Batch>(
                  isExpanded: true,
                  value: selectedBatch,
                  items: batches
                      .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
                      .toList(),
                  onChanged: (b) {
                    if (b != null) {
                      setState(() {
                        selectedBatch = b;
                        selectedSection = null;
                        sections = [];
                      });
                      _loadSectionsForBatch(b);
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 14),
        ],

        // 4. Section Selector (Dependent on Batch)
        if (departments.isNotEmpty && batches.isNotEmpty) ...[
          Label('Approved Section / Classroom', color: c.secondary),
          const SizedBox(height: 6),
          if (sections.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.subtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No approved sections found for this batch. Switch to "Create Classroom" to request one.',
                style: context.type.bodySmall?.copyWith(color: c.secondary),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Section>(
                  isExpanded: true,
                  value: selectedSection,
                  items: sections
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.label} (${s.memberCount} members)'),
                          ))
                      .toList(),
                  onChanged: (s) {
                    setState(() {
                      selectedSection = s;
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 18),
        ],

        // 5. Role Selector: Admin or Student
        Label('Are you entering as an Admin or as a Student?', color: c.secondary),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                title: 'Student',
                subtitle: 'View routine & events',
                icon: CupertinoIcons.person_crop_circle,
                selected: !isEnteringAsAdmin,
                onTap: () => setState(() {
                  isEnteringAsAdmin = false;
                  if (joinNameController.text.trim().isEmpty) {
                    joinNameController.text = 'user';
                  }
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                title: 'Section Admin',
                subtitle: 'Manage slots & routine',
                icon: CupertinoIcons.slider_horizontal_3,
                selected: isEnteringAsAdmin,
                onTap: () => setState(() {
                  isEnteringAsAdmin = true;
                  if (joinNameController.text.trim().isEmpty) {
                    joinNameController.text = 'user';
                  }
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 6. Student/Admin Display Name
        Label('Your Name', color: c.secondary),
        const SizedBox(height: 6),
        TextField(
          controller: joinNameController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          decoration: const InputDecoration(
            hintText: 'e.g. Samir',
            prefixIcon: Icon(CupertinoIcons.person, size: 18),
          ),
        ),
        const SizedBox(height: 14),

        // 7. Classroom Section Code
        Label(
          'Section Code',
          color: c.secondary,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: joinPasswordController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          obscureText: joinObscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter Section Code',
            prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                joinObscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                size: 18,
              ),
              onPressed: () => setState(() => joinObscurePassword = !joinObscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // 8. Join Action Button
        FilledButton(
          onPressed: submitting ? null : _joinClassroom,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: submitting
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Text(isEnteringAsAdmin ? 'Enter as Section Admin' : 'Enter Classroom'),
        ),
      ],
    );
  }

  Widget _buildCreateTab(MyClassColors c) {
    if (createSuccess) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(CupertinoIcons.checkmark_seal_fill, size: 54, color: c.sage),
            const SizedBox(height: 16),
            Text(
              'Classroom Submitted!',
              style: context.type.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              createMessage ?? '',
              textAlign: TextAlign.center,
              style: context.type.bodyMedium?.copyWith(color: c.secondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => setState(() {
                createSuccess = false;
                tabIndex = 0;
              }),
              child: const Text('Back to Classroom List'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hierarchy Notice
        Surface(
          color: c.subtle,
          border: false,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.info_circle, size: 18, color: c.sage),
                  const SizedBox(width: 8),
                  Text('Classroom Hierarchy', style: context.type.titleSmall?.copyWith(color: c.sage)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'MyClass Owner → Department → Batch → Section → Admin → Students\n\n'
                'Newly created classrooms must be verified and approved by the MyClass Owner before becoming publicly available.',
                style: context.type.bodySmall?.copyWith(color: c.secondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // University Selector (Above Department)
        Label('University', color: c.secondary),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showUniversityPicker(context, isCreate: true),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.building_2_fill, size: 18, color: c.sage),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    createUniversity?.name ?? 'Select University',
                    style: context.type.bodyMedium?.copyWith(
                      color: createUniversity != null ? c.ink : c.faint,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(CupertinoIcons.chevron_down, size: 16, color: c.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Department
        Label('Department', color: c.secondary),
        const SizedBox(height: 6),
        if (createDepartments.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Department>(
                isExpanded: true,
                value: createDept,
                items: createDepartments
                    .map((d) => DropdownMenuItem(value: d, child: Text('${d.shortName} - ${d.name}')))
                    .toList(),
                onChanged: (d) => setState(() {
                  createDept = d;
                  if (d != null) {
                    createDeptNameController.text = d.name;
                  }
                }),
              ),
            ),
          )
        else
          TextField(
            controller: createDeptNameController,
            scrollPadding: const EdgeInsets.only(bottom: 80),
            decoration: const InputDecoration(
              hintText: 'e.g. Computer Science & Engineering',
              prefixIcon: Icon(CupertinoIcons.book, size: 18),
            ),
          ),
        const SizedBox(height: 14),

        // Batch & Section
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label('Batch Number', color: c.secondary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: createBatchController,
                    scrollPadding: const EdgeInsets.only(bottom: 80),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 64',
                      prefixIcon: Icon(CupertinoIcons.number, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label('Section Name', color: c.secondary),
                  const SizedBox(height: 6),
                  TextField(
                    controller: createSectionController,
                    scrollPadding: const EdgeInsets.only(bottom: 80),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Section D',
                      prefixIcon: Icon(CupertinoIcons.square_grid_2x2, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Creator Name
        Label('Your Name (Class Representative)', color: c.secondary),
        const SizedBox(height: 6),
        TextField(
          controller: createCreatorNameController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          decoration: const InputDecoration(
            hintText: 'e.g. Samir Chowdhury',
            prefixIcon: Icon(CupertinoIcons.person_badge_plus, size: 18),
          ),
        ),
        const SizedBox(height: 14),

        // Section Code Fields (Field 1: Set Section Code, Field 2: Confirm Section Code)
        Label('Set Section Code', color: c.secondary),
        const SizedBox(height: 6),
        TextField(
          controller: createSectionCodeController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          obscureText: createObscureCode,
          decoration: InputDecoration(
            hintText: 'Set Section Code',
            prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                createObscureCode ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                size: 18,
              ),
              onPressed: () => setState(() => createObscureCode = !createObscureCode),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Label('Confirm Section Code', color: c.secondary),
        const SizedBox(height: 6),
        TextField(
          controller: confirmSectionCodeController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          obscureText: confirmObscureCode,
          decoration: InputDecoration(
            hintText: 'Confirm Section Code',
            prefixIcon: const Icon(CupertinoIcons.lock_shield, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                confirmObscureCode ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                size: 18,
              ),
              onPressed: () => setState(() => confirmObscureCode = !confirmObscureCode),
            ),
          ),
        ),
        const SizedBox(height: 22),

        FilledButton(
          onPressed: submitting ? null : _createClassroom,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: submitting
              ? const CupertinoActivityIndicator(color: Colors.white)
              : const Text('Submit Classroom for Owner Approval'),
        ),
      ],
    );
  }

  Widget _buildTeacherTab(MyClassColors c) {
    final teacherService = TeacherSectionService.instance;
    final isSignedIn = teacherService.isSignedIn;

    if (!isSignedIn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Surface(
            color: c.sageBg,
            border: false,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(CupertinoIcons.briefcase_fill, size: 20, color: c.sage),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Teacher Mode allows faculty members to manage assigned classroom sections, routines, and coordinate with students.',
                    style: context.type.bodySmall?.copyWith(color: c.sage, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ChoiceBar<int>(
            values: const [0, 1],
            selected: teacherAuthTab,
            label: (i) => i == 0 ? 'Teacher Sign In' : 'Register Account',
            onChanged: (i) {
              setState(() {
                teacherAuthTab = i;
                errorMessage = null;
              });
            },
          ),
          const SizedBox(height: 18),

          if (teacherAuthTab == 1) ...[
            // Teacher Sign Up (1. Name, 2. Email, 3. Password)
            Label('Name *', color: c.secondary),
            const SizedBox(height: 6),
            TextField(
              controller: teacherNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Dr. Tariqul Islam',
                prefixIcon: Icon(CupertinoIcons.person, size: 18),
              ),
            ),
            const SizedBox(height: 14),

            Label('Email *', color: c.secondary),
            const SizedBox(height: 6),
            TextField(
              controller: teacherEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'e.g. tariqul@leading.edu',
                prefixIcon: Icon(CupertinoIcons.mail, size: 18),
              ),
            ),
            const SizedBox(height: 14),

            Label('Password *', color: c.secondary),
            const SizedBox(height: 6),
            TextField(
              controller: teacherPassController,
              obscureText: teacherObscurePass,
              decoration: InputDecoration(
                hintText: 'Create teacher password',
                prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    teacherObscurePass ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    size: 18,
                  ),
                  onPressed: () => setState(() => teacherObscurePass = !teacherObscurePass),
                ),
              ),
            ),
            const SizedBox(height: 22),

            FilledButton(
              onPressed: () {
                final name = teacherNameController.text.trim();
                final email = teacherEmailController.text.trim();
                final pass = teacherPassController.text.trim();

                if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                  setState(() => errorMessage = 'Name, email, and password are all required for teacher registration.');
                  return;
                }

                teacherService.registerTeacher(name: name, email: email, password: pass);
                setState(() {
                  isAddingTeacherSection = true;
                  errorMessage = null;
                });
                feedback(context, 'Teacher account registered! Automatically signed in.');
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: c.sage,
              ),
              child: const Text('Register & Sign In as Teacher'),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => teacherAuthTab = 0),
                child: const Text('Already have a teacher account? Sign In'),
              ),
            ),
          ] else ...[
            // Teacher Sign In
            Label('Email', color: c.secondary),
            const SizedBox(height: 6),
            TextField(
              controller: teacherEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'e.g. tariqul@leading.edu or sami',
                prefixIcon: Icon(CupertinoIcons.mail, size: 18),
              ),
            ),
            const SizedBox(height: 14),

            Label('Password', color: c.secondary),
            const SizedBox(height: 6),
            TextField(
              controller: teacherPassController,
              obscureText: teacherObscurePass,
              decoration: InputDecoration(
                hintText: 'Enter teacher password (e.g. teacher)',
                prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    teacherObscurePass ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    size: 18,
                  ),
                  onPressed: () => setState(() => teacherObscurePass = !teacherObscurePass),
                ),
              ),
            ),
            const SizedBox(height: 22),

            FilledButton(
              onPressed: () {
                final email = teacherEmailController.text.trim();
                final pass = teacherPassController.text.trim();

                // Quick teacher access check: password "teacher" or email "teacher"
                if (pass.toLowerCase() == 'teacher' || email.toLowerCase() == 'teacher') {
                  teacherService.signInTeacher(
                    email: email.isEmpty ? 'tariqul@leading.edu' : email,
                    password: 'teacher',
                  );
                  setState(() {
                    errorMessage = null;
                    if (teacherService.approvedSections.isEmpty && teacherService.pendingSections.isEmpty) {
                      isAddingTeacherSection = true;
                    }
                  });
                  feedback(context, 'Signed in as Teacher.');
                  return;
                }

                // Universal Owner Login check: sami / sami
                if ((email.toLowerCase() == 'sami' && pass == 'sami') || pass == 'sami') {
                  _authenticateAsOwner();
                  return;
                }

                if (email.isEmpty || pass.isEmpty) {
                  setState(() => errorMessage = 'Please enter teacher email and password.');
                  return;
                }

                final ok = teacherService.signInTeacher(email: email, password: pass);
                if (ok) {
                  setState(() {
                    errorMessage = null;
                    if (teacherService.approvedSections.isEmpty && teacherService.pendingSections.isEmpty) {
                      isAddingTeacherSection = true;
                    }
                  });
                  feedback(context, 'Signed in as Teacher.');
                } else {
                  setState(() => errorMessage = 'Invalid teacher credentials.');
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: c.sage,
              ),
              child: const Text('Sign In to Teacher Mode'),
            ),
            const SizedBox(height: 6),

            Center(
              child: TextButton.icon(
                onPressed: () {
                  teacherService.signInAsPreviewTeacher();
                  setState(() {
                    errorMessage = null;
                    if (teacherService.approvedSections.isEmpty && teacherService.pendingSections.isEmpty) {
                      isAddingTeacherSection = true;
                    }
                  });
                  feedback(context, 'Signed in as Preview Teacher (Dr. Tariqul Islam).');
                },
                icon: const Icon(CupertinoIcons.sparkles, size: 15),
                label: const Text('Demo: Sign In as Dr. Tariqul Islam'),
                style: TextButton.styleFrom(
                  foregroundColor: c.sage,
                ),
              ),
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Forgot Password'),
                            content: const Text(
                              'A password recovery verification link will be sent to your institutional academic email address.\n\nContact your university IT administrator if you require immediate credential reset.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Forgot Password?')),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => teacherAuthTab = 1),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Create an Account')),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Divider(color: c.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR', style: TextStyle(fontSize: 11, color: c.secondary)),
                ),
                Expanded(child: Divider(color: c.line)),
              ],
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                teacherService.signInTeacher(
                  email: 'teacher.google@leading.edu',
                  password: 'google-authenticated',
                );
                setState(() {
                  errorMessage = null;
                  if (teacherService.approvedSections.isEmpty && teacherService.pendingSections.isEmpty) {
                    isAddingTeacherSection = true;
                  }
                });
                feedback(context, 'Signed in with Google (teacher.google@leading.edu).');
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: c.line),
              ),
              icon: const Icon(CupertinoIcons.globe, size: 18),
              label: const Text('Sign in with Google / Gmail'),
            ),
          ],
        ],
      );
    }

    // Teacher IS signed in:
    final teacher = teacherService.currentTeacher;
    final approved = teacherService.approvedSections;
    final pending = teacherService.pendingSections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teacher Account Banner
        Surface(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.sageBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  teacher?.name.isNotEmpty == true ? teacher!.name[0].toUpperCase() : 'T',
                  style: TextStyle(fontWeight: FontWeight.bold, color: c.sage, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacher?.name ?? 'Teacher', style: context.type.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(teacher?.email ?? '', style: context.type.bodySmall?.copyWith(color: c.secondary)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  teacherService.signOutTeacher();
                  setState(() {});
                  feedback(context, 'Signed out of Teacher account.');
                },
                child: const Text('Sign out', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (isAddingTeacherSection) ...[
          // Section Selection Flow
          Surface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Your Section', style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, size: 16),
                      onPressed: () => setState(() => isAddingTeacherSection = false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Label('University / Varsity', color: c.secondary),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _showUniversityPicker(context, isCreate: false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.building_2_fill, size: 16, color: c.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedUniversity?.name ?? 'Select University',
                            style: context.type.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(CupertinoIcons.chevron_down, size: 14, color: c.faint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Label('Batch', color: c.secondary),
                const SizedBox(height: 6),
                DropdownButtonFormField<Batch>(
                  value: selectedBatch,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: batches.map((b) => DropdownMenuItem(value: b, child: Text(b.label))).toList(),
                  onChanged: (b) {
                    if (b != null) {
                      setState(() => selectedBatch = b);
                      _loadSectionsForBatch(b);
                    }
                  },
                ),
                const SizedBox(height: 12),

                Label('Section', color: c.secondary),
                const SizedBox(height: 6),
                DropdownButtonFormField<Section>(
                  value: selectedSection,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: sections.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                  onChanged: (s) => setState(() => selectedSection = s),
                ),
                const SizedBox(height: 12),

                Label('Section Code *', color: c.secondary),
                const SizedBox(height: 6),
                TextField(
                  controller: teacherSectionCodeController,
                  decoration: const InputDecoration(
                    hintText: 'Enter Section Code for verification',
                    prefixIcon: Icon(CupertinoIcons.lock, size: 18),
                  ),
                ),
                const SizedBox(height: 14),

                Surface(
                  color: c.subtle,
                  border: false,
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.info, size: 16, color: c.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Teacher section access requires approval from Section Admin or Owner before becoming active.',
                          style: TextStyle(fontSize: 11, color: c.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                FilledButton(
                  onPressed: () {
                    final code = teacherSectionCodeController.text.trim();
                    if (code.isEmpty) {
                      setState(() => errorMessage = 'Please enter the Section Code.');
                      return;
                    }
                    if (selectedSection == null) {
                      setState(() => errorMessage = 'Please select a section.');
                      return;
                    }

                    teacherService.requestSection(
                      sectionId: selectedSection!.id,
                      sectionName: selectedSection!.label,
                      batchName: selectedBatch?.label ?? 'Batch 64',
                      departmentName: selectedDept?.name ?? 'Computer Science & Engineering',
                      universityName: selectedUniversity?.name ?? 'Leading University',
                      sectionCode: code,
                    );

                    setState(() {
                      isAddingTeacherSection = false;
                      teacherSectionCodeController.clear();
                      errorMessage = null;
                    });

                    feedback(context, 'Section request submitted! Awaiting Admin or Owner approval.');
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: c.sage,
                  ),
                  child: const Text('Submit Request for Approval'),
                ),
              ],
            ),
          ),
        ] else ...[
          // My Sections List
          Row(
            children: [
              Expanded(
                child: Text('My Sections', style: context.type.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.sageBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${approved.length} Active',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c.sage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select an approved section to manage class schedules and activities.',
            style: context.type.bodySmall?.copyWith(color: c.secondary),
          ),
          const SizedBox(height: 16),

          if (approved.isEmpty && pending.isEmpty)
            const EmptyState(
              'No sections added yet.',
              'Tap + Add Section below to request access to your class sections.',
              icon: CupertinoIcons.folder_badge_plus,
            )
          else ...[
            for (final sec in approved) ...[
              Surface(
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: () {
                    // Enter section management as Teacher
                    final membership = teacherService.createMembershipForSection(sec);
                    context.read<AuthBloc>().add(
                      AuthSectionLoggedIn(
                        name: teacher?.name ?? 'Teacher',
                        membership: membership,
                        grant: SectionGrant(sec.sectionId, 'teacher-token-${sec.sectionId}', role: UserRole.teacher),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.sageBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          sec.sectionName.replaceAll('Section ', ''),
                          style: TextStyle(fontWeight: FontWeight.bold, color: c.sage, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sec.sectionName, style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '${sec.batchName} · ${sec.universityName}',
                              style: context.type.bodySmall?.copyWith(color: c.secondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.sageBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.sage)),
                      ),
                      const SizedBox(width: 8),
                      Icon(CupertinoIcons.chevron_right, size: 14, color: c.faint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Pending Approval Sections
            for (final sec in pending) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.amber.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.clock_fill, size: 16, color: c.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${sec.sectionName} (${sec.batchName})',
                            style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.amberBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Pending Approval',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.amber),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Access requested with Section Code. Awaiting Admin or Owner approval.',
                      style: context.type.bodySmall?.copyWith(color: c.secondary),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          teacherService.approveSection(sec.sectionId);
                          setState(() {});
                          feedback(context, 'Approved ${sec.sectionName}! Now active in My Sections.');
                        },
                        icon: const Icon(CupertinoIcons.checkmark_shield, size: 14),
                        label: const Text('Approve (Admin/Owner)'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: c.sage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],

          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                isAddingTeacherSection = true;
                errorMessage = null;
              });
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(CupertinoIcons.plus, size: 16),
            label: const Text('+ Add Section'),
          ),
        ],
      ],
    );
  }
}

class _UniversitySearchSheet extends StatefulWidget {
  const _UniversitySearchSheet({
    required this.universities,
    required this.selected,
    required this.onSelected,
  });

  final List<University> universities;
  final University? selected;
  final ValueChanged<University> onSelected;

  @override
  State<_UniversitySearchSheet> createState() => _UniversitySearchSheetState();
}

class _UniversitySearchSheetState extends State<_UniversitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight = screenHeight - bottomInset;
    final filtered = widget.universities.where((u) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase().trim();
      return u.name.toLowerCase().contains(q) || u.id.toLowerCase().contains(q);
    }).toList();

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: Motion.fast,
      curve: Motion.curve,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: bottomInset > 0
              ? (availableHeight > 240 ? availableHeight - 16 : availableHeight)
              : screenHeight * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select University',
                    style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Field
            TextField(
              controller: _searchController,
              scrollPadding: const EdgeInsets.only(bottom: 60),
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search university (e.g. Leading, Dhaka, North)...',
                prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              '${filtered.length} universities found',
              style: context.type.bodySmall?.copyWith(color: c.secondary),
            ),
            const SizedBox(height: 8),

            // University List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No universities found matching "$_query"',
                          textAlign: TextAlign.center,
                          style: context.type.bodyMedium?.copyWith(color: c.secondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
                      itemBuilder: (context, index) {
                        final uni = filtered[index];
                        final isSelected = widget.selected?.id == uni.id ||
                            widget.selected?.name == uni.name;

                        return InkWell(
                          onTap: () => widget.onSelected(uni),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? c.sageBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    uni.name,
                                    style: context.type.bodyMedium?.copyWith(
                                      color: isSelected ? c.sage : c.ink,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(CupertinoIcons.checkmark_alt_circle_fill, color: c.sage, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? c.sageBg : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.sage : c.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: selected ? c.sage : c.faint),
            const SizedBox(height: 6),
            Text(
              title,
              style: context.type.titleSmall?.copyWith(
                color: selected ? c.sage : c.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.type.bodySmall?.copyWith(
                fontSize: 10,
                color: selected ? c.sage : c.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
