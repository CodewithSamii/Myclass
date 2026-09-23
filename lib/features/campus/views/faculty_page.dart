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
