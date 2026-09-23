import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models.dart';
import '../../core/clock.dart';
import '../../core/format.dart';
import '../../design_system/tokens.dart';
import '../../shared/widgets/primitives.dart';
import '../../features/profile/bloc/profile_bloc.dart';
import '../../features/events/bloc/events_bloc.dart';
import '../../features/schedule/bloc/schedule_bloc.dart';
import '../demo_controller.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    final demo = context.watch<DemoController>();
    final p = context.watch<ProfileBloc>().state.profile;
    return DetailPage(
      title: 'Product preview',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Try a different day.', style: context.type.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'A controlled preview of real student situations. All changes stay local.',
            style: context.type.bodyLarge?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Badge(
            '${Fmt.fullDate(demo.now)} · ${Fmt.time(demo.now)}',
            icon: CupertinoIcons.clock,
          ),
          const SectionHeader('Your point of view'),
          ChoiceBar<bool>(
            values: const [false, true],
            selected: p.membership.canManage,
            label: (v) => v ? 'Class representative' : 'Student',
            onChanged: (v) {
              final m = p.membership.withRole(
                v ? UserRole.sectionAdmin : UserRole.student,
              );
              context.read<ProfileBloc>().add(
                ProfileSaved(
                  p.copyWith(
                    memberships: p.memberships
                        .map((old) => old.sectionId == m.sectionId ? m : old)
                        .toList(),
                  ),
                ),
              );
            },
          ),
          const SectionHeader('Day scenarios'),
          for (final scenario in DemoScenario.values)
            SettingsRow(
              scenario.label,
              onTap: () {
                demo.scenario(scenario);
                context.read<ScheduleBloc>().add(
                  ScheduleDateSelected(dateOnly(demo.now)),
                );
                feedback(
                  context,
                  'Home and Schedule now show ${scenario.label.toLowerCase()}.',
                );
              },
              trailing: scenario == demo.state.scenario
                  ? Icon(
                      CupertinoIcons.checkmark,
                      size: 18,
                      color: context.colors.sage,
                    )
                  : const SizedBox(),
            ),
          const SectionHeader('Connection & recovery'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Offline mode', style: context.type.bodyLarge),
            subtitle: Text(
              'Keep saved data visible. Block shared edits.',
              style: context.type.bodySmall,
            ),
            value: demo.state.offline,
            onChanged: demo.offline,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Stale schedule', style: context.type.bodyLarge),
            subtitle: Text(
              'Show the last-updated context.',
              style: context.type.bodySmall,
            ),
            value: demo.state.stale,
            onChanged: demo.stale,
          ),
          SettingsRow(
            'Fail the next save',
            subtitle: demo.state.failNextSave
                ? 'Armed · The next write will fail'
                : 'Verify that drafts survive a failed save',
            icon: CupertinoIcons.exclamationmark_circle,
            onTap: () {
              demo.failSave();
              feedback(context, 'Next save will fail once. Retry will work.');
            },
          ),
          SettingsRow(
            'Simulate a refresh error',
            subtitle: 'Saved events remain visible',
            icon: CupertinoIcons.arrow_clockwise,
            onTap: () {
              demo.failLoad();
              context.read<EventsBloc>().add(EventsRefresh());
              feedback(context, 'Home will show a recoverable refresh error.');
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Profile and sign-in persist across launches. Event edits, notes and completion are held in memory for this preview session.',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
