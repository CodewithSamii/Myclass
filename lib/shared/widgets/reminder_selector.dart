import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import '../../core/format.dart';
import '../../design_system/tokens.dart';
import 'primitives.dart';

class ReminderChoice {
  const ReminderChoice(this.offsets, {this.inherit = false});
  final List<int> offsets;
  final bool inherit;
}

class ReminderSelector extends StatefulWidget {
  const ReminderSelector({
    super.key,
    required this.selected,
    this.defaults,
    this.title = 'Reminders',
  });
  final List<int> selected;
  final List<int>? defaults;
  final String title;
  @override
  State<ReminderSelector> createState() => _ReminderSelectorState();
}

class _ReminderSelectorState extends State<ReminderSelector> {
  late final Set<int> offsets = widget.selected.toSet();
  final _custom = TextEditingController();
  int unit = 60;
  String? error;
  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = {
      10080,
      7200,
      4320,
      1440,
      720,
      360,
      180,
      60,
      30,
      15,
      ...offsets,
    }.toList()..sort((a, b) => b.compareTo(a));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: context.type.headlineSmall),
          const SizedBox(height: 10),
          Text(
            'A little notice, when you need it. Choose more than one.',
            style: context.type.bodyMedium?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in values)
                ChoiceChip(
                  label: Text(Fmt.offset(v)),
                  selected: offsets.contains(v),
                  showCheckmark: true,
                  selectedColor: context.colors.sageBg,
                  backgroundColor: context.colors.surface,
                  side: BorderSide(
                    color: offsets.contains(v)
                        ? context.colors.sage
                        : context.colors.line,
                  ),
                  labelStyle: context.type.bodyMedium?.copyWith(
                    color: offsets.contains(v)
                        ? context.colors.sage
                        : context.colors.ink,
                  ),
                  onSelected: (selected) {
                    HapticFeedback.selectionClick();
                    setState(
                      () => selected ? offsets.add(v) : offsets.remove(v),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Label('Custom offset'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _custom,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'Amount'),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: unit,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('minutes')),
                  DropdownMenuItem(value: 60, child: Text('hours')),
                  DropdownMenuItem(value: 1440, child: Text('days')),
                ],
                onChanged: (v) => setState(() => unit = v!),
              ),
              IconButton(
                tooltip: 'Add custom reminder',
                onPressed: () {
                  final value = (int.tryParse(_custom.text) ?? 0) * unit;
                  if (value < 1 || value > 525600) {
                    setState(
                      () => error =
                          'Choose an offset between 1 minute and 365 days.',
                    );
                    return;
                  }
                  setState(() {
                    offsets.add(value);
                    error = null;
                    _custom.clear();
                  });
                },
                icon: const Icon(CupertinoIcons.add_circled, size: 24),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: context.type.bodySmall?.copyWith(
                color: context.colors.red,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            offsets.isEmpty
                ? 'No reminders for this event.'
                : 'You’ll be reminded ${Fmt.offsets(offsets.toList()..sort((a, b) => b.compareTo(a)))} before.',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            'Save reminders',
            icon: CupertinoIcons.checkmark,
            onPressed: () => Navigator.pop(
              context,
              ReminderChoice(offsets.toList()..sort((a, b) => b.compareTo(a))),
            ),
          ),
          if (widget.defaults != null)
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  ReminderChoice(widget.defaults!, inherit: true),
                ),
                child: const Text('Use my default reminders'),
              ),
            ),
        ],
      ),
    );
  }
}
