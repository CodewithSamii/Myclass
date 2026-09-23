import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/repositories.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';

class OwnerApprovalsPage extends StatefulWidget {
  const OwnerApprovalsPage({super.key});

  @override
  State<OwnerApprovalsPage> createState() => _OwnerApprovalsPageState();
}

class _OwnerApprovalsPageState extends State<OwnerApprovalsPage> {
  List<Section> pendingList = [];
  bool loading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => loading = true);
    try {
      final repo = context.read<AcademicStructureRepository>();
      final list = await repo.pendingSections();
      setState(() => pendingList = list);
    } catch (e) {
      setState(() => message = 'Failed to load requests: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _approve(Section section) async {
    try {
      final repo = context.read<AcademicStructureRepository>();
      await repo.approveSection(section.id);
      setState(() {
        pendingList.removeWhere((s) => s.id == section.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved "${section.label}"! It is now live for students.'),
            backgroundColor: context.colors.sage,
          ),
        );
      }
    } catch (e) {
      setState(() => message = 'Failed to approve: $e');
    }
  }

  Future<void> _reject(Section section) async {
    try {
      final repo = context.read<AcademicStructureRepository>();
      await repo.rejectSection(section.id);
      setState(() {
        pendingList.removeWhere((s) => s.id == section.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom request rejected.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => message = 'Failed to reject: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Approvals'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _loadPending,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Surface(
                  color: c.amberBg,
                  border: false,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_shield_fill, color: c.amber, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'As MyClass Owner, verify that the batch and section exist before approving.',
                          style: context.type.bodyMedium?.copyWith(color: c.amber, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (message != null) ...[
                  ErrorNotice(message!),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Pending Classroom Requests (${pendingList.length})',
                  style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (pendingList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(CupertinoIcons.tray, size: 42, color: c.faint),
                        const SizedBox(height: 12),
                        Text(
                          'No pending classroom requests.',
                          style: context.type.titleSmall?.copyWith(color: c.secondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'New classrooms submitted by students/admins will appear here for verification.',
                          textAlign: TextAlign.center,
                          style: context.type.bodySmall?.copyWith(color: c.faint),
                        ),
                      ],
                    ),
                  )
                else
                  for (final s in pendingList)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Surface(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.label,
                                    style: context.type.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: c.amberBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Pending Approval',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: c.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${s.departmentName ?? "Department"} · ${s.batchName ?? "Batch"}',
                              style: context.type.bodyMedium?.copyWith(color: c.secondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Requested by: ${s.creatorName ?? "Class Representative"}',
                              style: context.type.bodySmall?.copyWith(color: c.faint),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _reject(s),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                  ),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: () => _approve(s),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: c.sage,
                                  ),
                                  child: const Text('Approve Classroom'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}
