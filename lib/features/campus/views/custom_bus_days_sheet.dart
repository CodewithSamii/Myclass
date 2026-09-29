import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';

class CustomBusDaysSheet extends StatefulWidget {
  const CustomBusDaysSheet({
    super.key,
    required this.initialDays,
    required this.onSaved,
  });

  final List<int> initialDays;
  final ValueChanged<List<int>> onSaved;

  @override
  State<CustomBusDaysSheet> createState() => _CustomBusDaysSheetState();
}

class _CustomBusDaysSheetState extends State<CustomBusDaysSheet> {
  static const weekDays = [
    (DateTime.saturday, 'Saturday'),
    (DateTime.sunday, 'Sunday'),
    (DateTime.monday, 'Monday'),
    (DateTime.tuesday, 'Tuesday'),
    (DateTime.wednesday, 'Wednesday'),
    (DateTime.thursday, 'Thursday'),
    (DateTime.friday, 'Friday'),
  ];

  late final Set<int> selectedDays;

  @override
  void initState() {
    super.initState();
    selectedDays = Set<int>.from(widget.initialDays);
  }

  void _toggle(int day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Custom Bus Reminder Days',
                  style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose which of the 7 days you want to receive bus reminders:',
            style: context.type.bodySmall?.copyWith(color: c.secondary),
          ),
          const SizedBox(height: 16),
          for (final (dayNumber, dayName) in weekDays) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Surface(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () => _toggle(dayNumber),
                color: selectedDays.contains(dayNumber) ? c.subtle : c.surface,
                child: Row(
                  children: [
                    Icon(
                      selectedDays.contains(dayNumber)
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 20,
                      color: selectedDays.contains(dayNumber) ? c.sage : c.faint,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dayName,
                        style: context.type.bodyMedium?.copyWith(
                          fontWeight: selectedDays.contains(dayNumber)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selectedDays.contains(dayNumber) ? c.ink : c.secondary,
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: selectedDays.contains(dayNumber),
                      onChanged: (_) => _toggle(dayNumber),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            'Save Custom Schedule',
            icon: CupertinoIcons.check_mark,
            onPressed: () {
              widget.onSaved(selectedDays.toList());
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
