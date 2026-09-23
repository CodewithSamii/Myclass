import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../core/format.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../shared/widgets/reminder_selector.dart';
import '../bloc/profile_bloc.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileBloc>().state;
    final p = state.profile;
    final r = p.reminders;
    final bloc = context.read<ProfileBloc>();
    return DetailPage(
      title: 'Notifications',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Enough notice.\nLess noise.',
            style: context.type.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Set your defaults once. Adjust individual events whenever you need.',
            style: context.type.bodyLarge?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SectionHeader('Before it happens'),
          _row(
            context,
            'Classes',
            r.classOffsets,
            (v) => r.copyWith(classOffsets: v),
          ),
          _row(
            context,
            'Assignments & submissions',
            r.assignmentOffsets,
            (v) => r.copyWith(assignmentOffsets: v),
          ),
          _row(
            context,
            'Viva',
            r.vivaOffsets,
            (v) => r.copyWith(vivaOffsets: v),
          ),
          _row(
            context,
            'Presentations',
            r.presentationOffsets,
            (v) => r.copyWith(presentationOffsets: v),
          ),
          _row(
            context,
            'Exams & lab exams',
            r.examOffsets,
            (v) => r.copyWith(examOffsets: v),
          ),
          const SectionHeader('When plans change'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Academic updates', style: context.type.titleMedium),
            subtitle: Text(
              'Schedule changes, cancellations and new events.',
              style: context.type.bodyMedium?.copyWith(
                color: context.colors.secondary,
              ),
            ),
            value: r.scheduleChanges,
            onChanged: (v) => bloc.add(
              ProfileSaved(
                p.copyWith(reminders: r.copyWith(scheduleChanges: v)),
              ),
            ),
          ),
          const SectionHeader('A look ahead'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Tomorrow’s summary', style: context.type.titleMedium),
            subtitle: Text(
              'One useful overview. You choose whether to receive it.',
              style: context.type.bodyMedium?.copyWith(
                color: context.colors.secondary,
              ),
            ),
            value: r.dailySummary,
            onChanged: (v) => bloc.add(
              ProfileSaved(p.copyWith(reminders: r.copyWith(dailySummary: v))),
            ),
          ),
          if (r.dailySummary)
            SettingsRow(
              'Delivery time',
              subtitle: Fmt.minute(r.summaryMinute),
              icon: CupertinoIcons.clock,
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: r.summaryMinute ~/ 60,
                    minute: r.summaryMinute % 60,
                  ),
                );
                if (t != null && !bloc.isClosed) {
                  bloc.add(
                    ProfileSaved(
                      bloc.state.profile.copyWith(
                        reminders: bloc.state.profile.reminders.copyWith(
                          summaryMinute: t.hour * 60 + t.minute,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            ErrorNotice(state.error!),
          ],
          const SizedBox(height: 28),
          Surface(
            color: context.colors.subtle,
            border: false,
            child: Text(
              'Reminder preferences work in this preview. Device notification delivery will be connected later.',
              style: context.type.bodySmall?.copyWith(
                color: context.colors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String title,
    List<int> offsets,
    ReminderPreference Function(List<int>) update,
  ) => SettingsRow(
    title,
    subtitle: offsets.isEmpty ? 'Off' : '${Fmt.offsets(offsets)} before',
    icon: CupertinoIcons.bell,
    onTap: () async {
      final bloc = context.read<ProfileBloc>();
      final choice = await openSheet<ReminderChoice>(
        context,
        ReminderSelector(selected: offsets, title: title),
      );
      if (choice != null && !bloc.isClosed) {
        bloc.add(
          ProfileSaved(
            bloc.state.profile.copyWith(reminders: update(choice.offsets)),
          ),
        );
      }
    },
  );
}
