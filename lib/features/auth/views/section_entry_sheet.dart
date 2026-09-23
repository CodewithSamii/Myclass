import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../bloc/auth_bloc.dart';

class SectionEntrySheet extends StatefulWidget {
  const SectionEntrySheet({super.key});

  @override
  State<SectionEntrySheet> createState() => _SectionEntrySheetState();
}

class _SectionEntrySheetState extends State<SectionEntrySheet> {
  int tabIndex = 0; // 0: Join Classroom, 1: Create Classroom, 2: Owner Login

  // University state
  List<University> universities = [];
  University? selectedUniversity;
  University? createUniversity;

  // Join flow state
  Department? selectedDept;
  Batch? selectedBatch;
  Section? selectedSection;
  bool isEnteringAsAdmin = false;
  final TextEditingController joinNameController = TextEditingController(text: 'Student User');
  final TextEditingController joinPasswordController = TextEditingController();
  bool joinObscurePassword = true;

  // Create flow state
  Department? createDept;
  final TextEditingController createDeptNameController = TextEditingController(text: 'Computer Science & Engineering');
  final TextEditingController createBatchController = TextEditingController(text: '64');
  final TextEditingController createSectionController = TextEditingController(text: 'Section D');
  final TextEditingController createCreatorNameController = TextEditingController(text: 'Class Rep');
  final TextEditingController createAdminPassController = TextEditingController();
  final TextEditingController createStudentPassController = TextEditingController();
  bool createSuccess = false;
  String? createMessage;

  // Owner flow state
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
    createAdminPassController.dispose();
    createStudentPassController.dispose();
    ownerPassController.dispose();
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
            selectedBatch = bList.first;
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
          selectedSection = sList.first;
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

  Future<void> _joinClassroom() async {
    if (selectedUniversity == null) {
      setState(() => errorMessage = 'Please select a university first.');
      return;
    }
    if (selectedSection == null) {
      setState(() => errorMessage = 'Please select a classroom first.');
      return;
    }
    final password = joinPasswordController.text.trim();
    if (password.isEmpty) {
      setState(() => errorMessage = 'Please enter the access password.');
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
          ? (isEnteringAsAdmin ? 'Class Admin' : 'Student')
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
    final adminPass = createAdminPassController.text.trim();
    final studentPass = createStudentPassController.text.trim();

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
    if (adminPass.isEmpty) {
      setState(() => errorMessage = 'Please set an Admin Password for managing the classroom.');
      return;
    }
    if (studentPass.isEmpty) {
      setState(() => errorMessage = 'Please set a Student Password for student access.');
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
        adminPassword: adminPass,
        studentPassword: studentPass,
        creatorName: creatorName.isEmpty ? 'Class Representative' : creatorName,
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

  Future<void> _loginAsOwner() async {
    final pass = ownerPassController.text.trim();
    if (pass.isEmpty) {
      setState(() => errorMessage = 'Please enter the owner master key.');
      return;
    }
    if (pass != 'yyoyyo' && pass != 'owner' && pass != 'admin' && pass != '123456') {
      setState(() => errorMessage = 'Invalid master key.');
      return;
    }

    const membership = SectionMembership(
      sectionId: 'bsc-cse-64-B',
      departmentId: 'cse',
      programId: 'bsc-cse',
      batchId: 'bsc-cse-64',
      programName: 'Computer Science & Engineering',
      batchName: 'Batch 64',
      sectionName: 'Section B',
      universityId: 'lu',
      universityName: 'Leading University',
      role: UserRole.myClassOwner,
    );

    context.read<AuthBloc>().add(
      AuthSectionLoggedIn(
        name: 'MyClass Owner',
        membership: membership,
        grant: const SectionGrant('bsc-cse-64-B', 'owner-token', role: UserRole.myClassOwner),
      ),
    );

    Navigator.of(context).pop();
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
                _ => 'Owner Mode',
              },
              onChanged: (i) {
                setState(() {
                  tabIndex = i;
                  errorMessage = null;
                  createSuccess = false;
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
                  _ => _buildOwnerTab(c),
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
                      if (isEnteringAsAdmin && s != null && s.creatorName != null && s.creatorName!.isNotEmpty) {
                        joinNameController.text = s.creatorName!;
                      }
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
                  if (selectedSection != null && joinNameController.text == selectedSection!.creatorName) {
                    joinNameController.text = 'Student User';
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
                  final creator = selectedSection?.creatorName;
                  if (selectedSection != null && (joinNameController.text == 'Student User' || joinNameController.text.isEmpty)) {
                    joinNameController.text = (creator != null && creator.isNotEmpty) ? creator : 'Shuvo';
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

        // 7. Classroom Password
        Label(
          isEnteringAsAdmin ? 'Admin Password' : 'Student Access Password',
          color: c.secondary,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: joinPasswordController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          obscureText: joinObscurePassword,
          decoration: InputDecoration(
            hintText: isEnteringAsAdmin ? 'Enter Admin Password' : 'Enter Student Password',
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

        // Admin Password & Student Password
        Label('Admin Password (for classroom controls)', color: c.secondary),
        const SizedBox(height: 6),
        TextField(
          controller: createAdminPassController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          decoration: const InputDecoration(
            hintText: 'Set a secret Admin password',
            prefixIcon: Icon(CupertinoIcons.shield_lefthalf_fill, size: 18),
          ),
        ),
        const SizedBox(height: 14),

        Label('Student Access Password (for your classmates)', color: c.secondary),
        const SizedBox(height: 6),
        TextField(
          controller: createStudentPassController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          decoration: const InputDecoration(
            hintText: 'Set student access password',
            prefixIcon: Icon(CupertinoIcons.person_2, size: 18),
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

  Widget _buildOwnerTab(MyClassColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Surface(
          color: c.amberBg,
          border: false,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(CupertinoIcons.star_circle_fill, size: 20, color: c.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'MyClass Owner Mode allows approving or rejecting submitted classrooms across all departments and batches.',
                  style: context.type.bodySmall?.copyWith(color: c.amber, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Label('Owner Master Passkey', color: c.secondary),
        const SizedBox(height: 6),
        TextField(
          controller: ownerPassController,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter owner master passkey (e.g. yyoyyo)',
            prefixIcon: Icon(CupertinoIcons.lock_shield, size: 18),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _loginAsOwner,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: c.amber,
          ),
          child: const Text('Enter as MyClass Owner'),
        ),
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
