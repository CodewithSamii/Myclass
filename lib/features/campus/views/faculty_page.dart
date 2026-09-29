import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../schedule/bloc/schedule_bloc.dart';
import '../bloc/campus_bloc.dart';

class FacultyPage extends StatelessWidget {
  const FacultyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<CampusBloc>().state;
    return DetailPage(
      title: 'Faculty directory',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('The right person.', style: context.type.headlineLarge),
          const SizedBox(height: 10),
          Text(
            'Find a faculty member by name or department.',
            style: context.type.bodyMedium?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: s.query,
            onChanged: (v) =>
                context.read<CampusBloc>().add(FacultyQueryChanged(v)),
            decoration: const InputDecoration(
              hintText: 'Search faculty',
              prefixIcon: Icon(CupertinoIcons.search, size: 19),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final d in <String?>[null, 'cse', 'bba', 'law', 'eng'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(d?.toUpperCase() ?? 'All'),
                      selected: s.department == d,
                      showCheckmark: false,
                      onSelected: (_) => context.read<CampusBloc>().add(
                        FacultyFilterChanged(d),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => openSheet(context, const _AddFacultySheet()),
                icon: const Icon(CupertinoIcons.plus, size: 14),
                label: const Text('Add Faculty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 36),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final schedule = context.read<ScheduleBloc>().state;
                  final courses = schedule.courses;
                  final sessions = schedule.sessions;
                  final routineFaculty = <FacultyMember>[];

                  for (final c in courses) {
                    if (c.facultyId.isNotEmpty) {
                      final existing = s.faculty.any((f) => f.name.toLowerCase() == c.compactName.toLowerCase() || f.id == c.facultyId);
                      if (!existing) {
                        routineFaculty.add(FacultyMember(
                          id: c.facultyId,
                          name: c.compactName,
                          designation: 'Course Instructor',
                          departmentId: c.departmentId,
                          email: '${c.facultyId}@example.edu',
                          office: 'Department Office',
                        ));
                      }
                    }
                  }

                  for (final sess in sessions) {
                    if (sess.facultyName != null && sess.facultyName!.trim().isNotEmpty) {
                      final name = sess.facultyName!.trim();
                      final existing = s.faculty.any((f) => f.name.toLowerCase() == name.toLowerCase()) ||
                          routineFaculty.any((f) => f.name.toLowerCase() == name.toLowerCase());
                      if (!existing) {
                        routineFaculty.add(FacultyMember(
                          id: 'rf-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}',
                          name: name,
                          designation: 'Faculty Instructor',
                          departmentId: 'cse',
                          email: '${name.toLowerCase().replaceAll(' ', '.')}@example.edu',
                          office: 'Faculty Room',
                        ));
                      }
                    }
                  }

                  if (routineFaculty.isNotEmpty) {
                    context.read<CampusBloc>().add(FacultyMembersAdded(routineFaculty));
                    feedback(context, 'Added ${routineFaculty.length} faculty from your routine.');
                  } else {
                    feedback(context, 'All routine faculty are already in your directory.');
                  }
                },
                icon: const Icon(CupertinoIcons.square_grid_2x2, size: 14),
                label: const Text('Add All / Routine', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (s.visibleFaculty.isEmpty)
            const EmptyState(
              'No faculty match this search.',
              'Try another name or department.',
              icon: CupertinoIcons.person,
            )
          else
            for (final member in s.visibleFaculty) ...[
              FacultyRow(member: member),
              const Divider(),
            ],
          const SizedBox(height: 24),
          Text(
            'Names and contact details are fictional preview data.',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.faint,
            ),
          ),
        ],
      ),
    );
  }
}

class FacultyRow extends StatelessWidget {
  const FacultyRow({super.key, required this.member});
  final FacultyMember member;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => openPage(context, FacultyProfilePage(member: member)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.subtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.initials,
              style: context.type.titleSmall?.copyWith(
                color: context.colors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  '${member.designation} · ${member.departmentId.toUpperCase()}',
                  maxLines: 2,
                  style: context.type.bodySmall?.copyWith(
                    color: context.colors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_right,
            size: 12,
            color: context.colors.faint,
          ),
        ],
      ),
    ),
  );
}

class FacultyProfilePage extends StatelessWidget {
  const FacultyProfilePage({super.key, required this.member});
  final FacultyMember member;
  @override
  Widget build(BuildContext context) {
    final courses = context
        .watch<ScheduleBloc>()
        .state
        .courses
        .where((c) => c.facultyId == member.id)
        .toList();
    return DetailPage(
      title: 'Faculty',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 66,
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.subtle,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(member.initials, style: context.type.headlineSmall),
            ),
          ),
          const SizedBox(height: 24),
          Text(member.name, style: context.type.headlineLarge),
          const SizedBox(height: 12),
          Text(
            '${member.designation}\nDepartment of ${switch (member.departmentId) {
              'cse' => 'Computer Science & Engineering',
              'bba' => 'Business Administration',
              'law' => 'Law & Justice',
              _ => 'English',
            }}',
            style: context.type.bodyLarge?.copyWith(
              color: context.colors.secondary,
              height: 1.6,
            ),
          ),
          const SectionHeader('Get in touch'),
          SettingsRow(
            member.email,
            subtitle: 'Tap to copy email',
            icon: CupertinoIcons.mail,
            onTap: () {
              Clipboard.setData(ClipboardData(text: member.email));
              feedback(context, 'Email address copied.');
            },
          ),
          const Divider(),
          SettingsRow(
            member.office,
            icon: CupertinoIcons.location,
            trailing: const SizedBox(),
          ),
          if (member.phone != null)
            SettingsRow(
              member.phone!,
              subtitle: 'Tap to copy number',
              icon: CupertinoIcons.phone,
              onTap: () {
                Clipboard.setData(ClipboardData(text: member.phone!));
                feedback(context, 'Phone number copied.');
              },
            ),
          const SectionHeader('Office hours'),
          Text(member.officeHours, style: context.type.bodyLarge),
          if (courses.isNotEmpty) ...[
            const SectionHeader('Your courses'),
            for (final course in courses)
              SettingsRow(
                course.name,
                subtitle: course.code,
                icon: CupertinoIcons.doc_text,
                trailing: const SizedBox(),
              ),
          ],
          if (member.interests.isNotEmpty) ...[
            const SectionHeader('Academic interests'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: member.interests.map((i) => Badge(i)).toList(),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Fictional profile for this preview.',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.faint,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFacultySheet extends StatefulWidget {
  const _AddFacultySheet();
  @override
  State<_AddFacultySheet> createState() => _AddFacultySheetState();
}

class _AddFacultySheetState extends State<_AddFacultySheet> {
  final _nameController = TextEditingController();
  final _designationController = TextEditingController(text: 'Lecturer');
  final _emailController = TextEditingController();
  final _officeController = TextEditingController(text: 'Faculty Room');
  String _department = 'cse';
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _emailController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter faculty name.');
      return;
    }
    final desig = _designationController.text.trim().isEmpty
        ? 'Lecturer'
        : _designationController.text.trim();
    final email = _emailController.text.trim().isEmpty
        ? '${name.toLowerCase().replaceAll(' ', '.')}@example.edu'
        : _emailController.text.trim();
    final office = _officeController.text.trim().isEmpty
        ? 'Faculty Room'
        : _officeController.text.trim();

    final newMember = FacultyMember(
      id: 'f-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      designation: desig,
      departmentId: _department,
      email: email,
      office: office,
    );

    context.read<CampusBloc>().add(FacultyMemberAdded(newMember));
    Navigator.of(context).pop();
    feedback(context, '$name added to Faculty Directory.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Faculty Member', style: context.type.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Add faculty information relevant to your courses or routine.',
            style: context.type.bodyMedium?.copyWith(color: context.colors.secondary),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorNotice(_error!),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Faculty Name *',
              hintText: 'e.g. A Islam',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _designationController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Designation',
              hintText: 'e.g. Assistant Professor',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _department,
            decoration: const InputDecoration(labelText: 'Department'),
            items: const [
              DropdownMenuItem(value: 'cse', child: Text('Computer Science & Engineering')),
              DropdownMenuItem(value: 'bba', child: Text('Business Administration')),
              DropdownMenuItem(value: 'law', child: Text('Law & Justice')),
              DropdownMenuItem(value: 'eng', child: Text('English')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _department = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address (optional)',
              hintText: 'name@example.edu',
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Add to Directory',
            icon: CupertinoIcons.checkmark,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
