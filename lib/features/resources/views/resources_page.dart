import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../models/resource_item.dart';
import '../repositories/resources_repository.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileBloc>().state.profile;
    final m = p.membership;

    return ListView(
      key: const PageStorageKey('resources'),
      padding: EdgeInsets.zero,
      children: [
        PageHeader(
          'Resources',
          eyebrow: '${m.batchName} Hub',
          subtitle: 'Batch materials, previous exams & sections',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Notes
              _ResourceBar(
                title: 'Notes',
                subtitle: 'Batch-wide shared lecture notes & summaries',
                icon: CupertinoIcons.doc_text_fill,
                accentColor: context.colors.ink,
                onTap: () => openPage(
                  context,
                  const _BatchResourceListPage(type: BatchResourceType.notes),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Previous Year Questions
              _ResourceBar(
                title: 'Previous Year Questions',
                subtitle: 'Past midterm and final examination papers',
                icon: CupertinoIcons.question_diamond_fill,
                accentColor: context.colors.amber,
                onTap: () => openPage(
                  context,
                  const _BatchResourceListPage(type: BatchResourceType.pyq),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Your Batch
              _ResourceBar(
                title: 'Your Batch',
                subtitle: 'All sections (A–I), class reps & student counts',
                icon: CupertinoIcons.person_3_fill,
                accentColor: context.colors.sage,
                onTap: () => openPage(
                  context,
                  const _YourBatchSectionsPage(),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Placeholder 1 (Curriculum & Syllabus)
              _ResourceBar(
                title: 'Curriculum & Syllabus',
                subtitle: 'Reserved for departmental course outlines',
                icon: CupertinoIcons.book_fill,
                accentColor: context.colors.faint,
                badgeText: 'Coming Soon',
                onTap: () {
                  feedback(context, 'Curriculum resource will be available in future update.');
                },
              ),
              const SizedBox(height: 12),

              // 5. Placeholder 2 (Batch Academic Drive)
              _ResourceBar(
                title: 'Academic Archive',
                subtitle: 'Reserved for batch cloud library & project files',
                icon: CupertinoIcons.archivebox_fill,
                accentColor: context.colors.faint,
                badgeText: 'Coming Soon',
                onTap: () {
                  feedback(context, 'Academic Archive will be available in future update.');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResourceBar extends StatelessWidget {
  const _ResourceBar({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.badgeText,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.subtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.subtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: c.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.type.bodySmall?.copyWith(color: c.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_right, size: 14, color: c.faint),
          ],
        ),
      ),
    );
  }
}

/// Generic page for Notes and Previous Year Questions
class _BatchResourceListPage extends StatefulWidget {
  const _BatchResourceListPage({required this.type});
  final BatchResourceType type;

  @override
  State<_BatchResourceListPage> createState() => _BatchResourceListPageState();
}

class _BatchResourceListPageState extends State<_BatchResourceListPage> {
  late List<BatchResourceItem> _items;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _items = widget.type == BatchResourceType.notes
          ? ResourcesRepository.instance.getNotes()
          : ResourcesRepository.instance.getPYQs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileBloc>().state.profile;
    final isAdminOrOwner = profile.membership.canManage || profile.membership.isOwner;
    final isNotes = widget.type == BatchResourceType.notes;
    final title = isNotes ? 'Notes' : 'Previous Year Questions';

    final approved = _items.where((i) => i.isApproved).toList();
    final pending = _items.where((i) => !i.isApproved).toList();

    return DetailPage(
      title: title,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.type.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isNotes
                          ? 'Available to all sections in ${profile.membership.batchName}'
                          : 'Past semester question papers across sections',
                      style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => openSheet(
                  context,
                  _UploadResourceSheet(
                    type: widget.type,
                    onUploaded: _refresh,
                  ),
                ),
                icon: const Icon(CupertinoIcons.plus, size: 14),
                label: Text(isNotes ? 'Upload Note' : 'Upload PYQ'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Admin pending approval section
          if (isAdminOrOwner && pending.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.amberBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.clock_fill, color: context.colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Pending Approval (${pending.length})',
                        style: context.type.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in pending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: context.type.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                'Uploaded by: ${item.uploaderName} (${item.uploaderSection})',
                                style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ResourcesRepository.instance.approveResource(
                              item.id,
                              profile.name.isEmpty ? 'Admin' : profile.name,
                            );
                            _refresh();
                            feedback(context, 'Approved "${item.title}". Now publicly available.');
                          },
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                    if (item != pending.last) const Divider(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (approved.isEmpty)
            EmptyState(
              'No approved ${title.toLowerCase()} yet.',
              'Upload academic materials for your batch to share.',
              icon: isNotes ? CupertinoIcons.doc_text : CupertinoIcons.question_diamond,
            )
          else
            for (final item in approved) ...[
              Surface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(CupertinoIcons.person_crop_circle, size: 14, color: context.colors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Uploaded by: ',
                          style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
                        ),
                        InkWell(
                          onTap: () {
                            openPage(
                              context,
                              _StudentUploadsPage(
                                studentName: item.uploaderName,
                                type: widget.type,
                              ),
                            );
                          },
                          child: Text(
                            '${item.uploaderName} (${item.uploaderSection})',
                            style: context.type.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.ink,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Admin view only: shows who approved it
                    if (isAdminOrOwner && item.approvedByAdminName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(CupertinoIcons.checkmark_seal_fill, size: 13, color: context.colors.sage),
                          const SizedBox(width: 6),
                          Text(
                            'Approved by: ${item.approvedByAdminName}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.colors.sage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

/// Page showing all approved notes/pyqs uploaded by a specific student
class _StudentUploadsPage extends StatelessWidget {
  const _StudentUploadsPage({
    required this.studentName,
    required this.type,
  });

  final String studentName;
  final BatchResourceType type;

  @override
  Widget build(BuildContext context) {
    final isNotes = type == BatchResourceType.notes;
    final items = isNotes
        ? ResourcesRepository.instance.getApprovedNotesByStudent(studentName)
        : ResourcesRepository.instance.getApprovedPYQsByStudent(studentName);

    final profile = context.watch<ProfileBloc>().state.profile;
    final isAdminOrOwner = profile.membership.canManage || profile.membership.isOwner;

    return DetailPage(
      title: studentName,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.subtle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    studentName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join(),
                    style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName, style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        'Batch Contributor · ${items.length} approved upload${items.length == 1 ? '' : 's'}',
                        style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isNotes ? 'Approved Notes by $studentName' : 'Approved Questions by $studentName',
            style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(item.description, style: context.type.bodySmall?.copyWith(color: context.colors.secondary)),
                  if (isAdminOrOwner && item.approvedByAdminName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Approved by: ${item.approvedByAdminName}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.sage),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Upload sheet for notes and pyqs
class _UploadResourceSheet extends StatefulWidget {
  const _UploadResourceSheet({
    required this.type,
    required this.onUploaded,
  });

  final BatchResourceType type;
  final VoidCallback onUploaded;

  @override
  State<_UploadResourceSheet> createState() => _UploadResourceSheetState();
}

class _UploadResourceSheetState extends State<_UploadResourceSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a title.');
      return;
    }

    final p = context.read<ProfileBloc>().state.profile;
    final isAdminOrOwner = p.membership.canManage || p.membership.isOwner;

    final item = BatchResourceItem(
      id: 'res-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: _descController.text.trim().isEmpty
          ? 'Uploaded lecture document / question paper.'
          : _descController.text.trim(),
      uploaderName: p.name.isEmpty ? 'Student' : p.name,
      uploaderSection: p.membership.sectionName,
      batchId: p.membership.batchId,
      type: widget.type,
      isApproved: isAdminOrOwner, // Admins/owners auto-approved; students require approval
      approvedByAdminName: isAdminOrOwner ? p.name : null,
      createdAt: DateTime.now(),
    );

    ResourcesRepository.instance.addResource(item);
    widget.onUploaded();
    Navigator.pop(context);
    feedback(
      context,
      isAdminOrOwner
          ? 'Resource published successfully.'
          : 'Resource uploaded! It will be visible once an Admin or Owner approves it.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNotes = widget.type == BatchResourceType.notes;
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
          Text(isNotes ? 'Upload Lecture Note' : 'Upload Previous Year Question', style: context.type.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Materials will be available to all students of your batch after admin approval.',
            style: context.type.bodyMedium?.copyWith(color: context.colors.secondary),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorNotice(_error!),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: isNotes ? 'Note Title *' : 'Question Paper Title *',
              hintText: isNotes ? 'e.g. OS Memory Management' : 'e.g. CSE 211 Midterm Fall 2024',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description / Topics Covered',
              hintText: 'Summary or syllabus topics included...',
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Submit for Approval',
            icon: CupertinoIcons.cloud_upload,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Resource 3: Your Batch (All sections A through I)
class _YourBatchSectionsPage extends StatelessWidget {
  const _YourBatchSectionsPage();

  @override
  Widget build(BuildContext context) {
    final sections = ResourcesRepository.instance.getSections();
    final profile = context.watch<ProfileBloc>().state.profile;

    return DetailPage(
      title: 'Your Batch',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${profile.membership.batchName} Sections',
            style: context.type.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap any section to view CR contacts and student information.',
            style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
          ),
          const SizedBox(height: 18),
          for (final sec in sections) ...[
            Surface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: InkWell(
                onTap: () => _showSectionDetails(context, sec),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.subtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sec.sectionName.replaceAll('Section ', ''),
                        style: context.type.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.ink,
                        ),
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
                            'CR: ${sec.crName} · ${sec.totalStudents} students',
                            style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_right, size: 14, color: context.colors.faint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  void _showSectionDetails(BuildContext context, BatchSectionInfo sec) {
    openSheet(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sec.sectionName, style: context.type.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${sec.department} · Batch 64',
              style: context.type.bodySmall?.copyWith(color: context.colors.secondary),
            ),
            const SizedBox(height: 20),
            Surface(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(CupertinoIcons.person_2_fill, color: context.colors.ink, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Label('Total Students'),
                      Text('${sec.totalStudents} enrolled', style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Class Representative (CR)', style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Surface(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.person_fill, size: 18, color: context.colors.secondary),
                      const SizedBox(width: 10),
                      Text(sec.crName, style: context.type.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 20),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: sec.crPhone));
                      feedback(context, 'Copied CR phone number.');
                    },
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.phone_fill, size: 16, color: context.colors.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(sec.crPhone, style: context.type.bodyMedium),
                        ),
                        Text('Copy', style: TextStyle(fontSize: 12, color: context.colors.secondary)),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: sec.crEmail));
                      feedback(context, 'Copied CR email.');
                    },
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.mail_solid, size: 16, color: context.colors.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(sec.crEmail, style: context.type.bodyMedium),
                        ),
                        Text('Copy', style: TextStyle(fontSize: 12, color: context.colors.secondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
