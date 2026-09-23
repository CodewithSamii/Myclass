import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../schedule/bloc/schedule_bloc.dart';

class SetSlotsPage extends StatefulWidget {
  const SetSlotsPage({super.key});

  @override
  State<SetSlotsPage> createState() => _SetSlotsPageState();
}

class _SetSlotsPageState extends State<SetSlotsPage> {
  late List<TimeSlot> slots;
  bool isDirty = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<ScheduleBloc>().state.timeSlots;
    if (current.isNotEmpty) {
      slots = List.from(current);
    } else {
      slots = [
        const TimeSlot(id: 'ts1', label: '10:00–11:00', startMinute: 600, endMinute: 660, orderIndex: 0),
        const TimeSlot(id: 'ts2', label: '11:00–12:00', startMinute: 660, endMinute: 720, orderIndex: 1),
        const TimeSlot(id: 'ts3', label: '12:00–1:00', startMinute: 720, endMinute: 780, orderIndex: 2),
        const TimeSlot(id: 'ts4', label: '1:00–2:00', startMinute: 780, endMinute: 840, orderIndex: 3),
      ];
    }
  }

  void _addSlot() {
    final lastEnd = slots.isNotEmpty ? slots.last.endMinute : 600;
    final nextStart = lastEnd;
    final nextEnd = nextStart + 60;
    final id = 'ts-${DateTime.now().millisecondsSinceEpoch}';
    final label = '${TimeSlot.formatMin(nextStart)}–${TimeSlot.formatMin(nextEnd)}';

    setState(() {
      slots.add(
        TimeSlot(
          id: id,
          label: label,
          startMinute: nextStart,
          endMinute: nextEnd,
          orderIndex: slots.length,
        ),
      );
      isDirty = true;
    });
  }

  void _editSlot(int index) async {
    final slot = slots[index];
    final labelController = TextEditingController(text: slot.label);
    final startMinController = TextEditingController(text: slot.startMinute.toString());
    final endMinController = TextEditingController(text: slot.endMinute.toString());

    final updated = await showDialog<TimeSlot>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Time Slot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Slot Label (e.g. 10:00–11:00)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Start Minute from Midnight (e.g. 600)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'End Minute from Midnight (e.g. 660)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final start = int.tryParse(startMinController.text) ?? slot.startMinute;
                final end = int.tryParse(endMinController.text) ?? slot.endMinute;
                final label = labelController.text.trim().isEmpty
                    ? '${TimeSlot.formatMin(start)}–${TimeSlot.formatMin(end)}'
                    : labelController.text.trim();
                Navigator.of(ctx).pop(
                  slot.copyWith(label: label, startMinute: start, endMinute: end),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );


    if (updated != null) {
      setState(() {
        slots[index] = updated;
        isDirty = true;
      });
    }
  }

  void _deleteSlot(int index) {
    setState(() {
      slots.removeAt(index);
      isDirty = true;
    });
  }

  void _saveSlots() {
    context.read<ScheduleBloc>().add(TimeSlotsSaveRequested(slots));
    setState(() => isDirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time slots saved successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Universal Slots'),
        actions: [
          if (isDirty)
            TextButton(
              onPressed: _saveSlots,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Surface(
            color: c.subtle,
            border: false,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(CupertinoIcons.clock_fill, color: c.sage, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Define the available time periods for classes (e.g. 10:00–11:00, 11:00–12:00). These slots are shared across all 7 days of the routine.',
                    style: context.type.bodyMedium?.copyWith(color: c.secondary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Periods (${slots.length})', style: context.type.titleMedium),
              TextButton.icon(
                onPressed: _addSlot,
                icon: const Icon(CupertinoIcons.add, size: 18),
                label: const Text('Add Period'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Text(
                'No time slots configured yet. Tap "Add Period" above.',
                style: context.type.bodyMedium?.copyWith(color: c.secondary),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slots.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = slots.removeAt(oldIndex);
                  slots.insert(newIndex, item);
                  isDirty = true;
                });
              },
              itemBuilder: (ctx, i) {
                final slot = slots[i];
                return Container(
                  key: ValueKey(slot.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Surface(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c.subtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: context.type.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.display, style: context.type.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                '${slot.startMinute}m to ${slot.endMinute}m from midnight',
                                style: context.type.bodySmall?.copyWith(color: c.faint),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.pencil, size: 18),
                          onPressed: () => _editSlot(i),
                          tooltip: 'Edit Slot',
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                          onPressed: () => _deleteSlot(i),
                          tooltip: 'Delete Slot',
                        ),
                        const Icon(CupertinoIcons.bars, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: isDirty ? _saveSlots : null,
            child: const Text('Save Universal Slots'),
          ),
        ],
      ),
    );
  }
}
