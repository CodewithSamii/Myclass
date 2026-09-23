import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../demo/views/preview_page.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../notes/views/notes_page.dart';
import '../../section_admin/views/event_editor_page.dart';
import '../../schedule/views/routine_page.dart';
import '../bloc/profile_bloc.dart';
import 'notification_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ProfileBloc>().state;
    final p = s.profile;
    final m = p.membership;
    return ListView(
      key: const PageStorageKey('profile'),
      padding: EdgeInsets.zero,
      children: [
        const PageHeader('Your space', eyebrow: 'Settle in'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.subtle,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      p.name.trim().isEmpty
                          ? 'S'
                          : p.name
                                .trim()
                                .split(' ')
                                .take(2)
                                .map((s) => s[0])
                                .join()
                                .toUpperCase(),
                      style: context.type.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: context.type.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          p.email,
                          style: context.type.bodySmall?.copyWith(
                            color: context.colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit preferred name',
                    onPressed: () => openSheet(context, const _NameEditor()),
                    icon: const Icon(CupertinoIcons.pencil, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Label(
                      m.canManage
                          ? 'Section representative'
                          : 'Your academic space',
                    ),
                    const SizedBox(height: 14),
                    Text(m.programName, style: context.type.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      m.label,
                      style: context.type.bodyMedium?.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.lock,
                          size: 13,
                          color: context.colors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Private section · Verified access',
                            style: context.type.bodySmall?.copyWith(
                              color: context.colors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (m.canManage) ...[
                const SectionHeader('For your section'),
                SettingsRow(
                  'Add an academic event',
                  subtitle: 'An assignment, viva, exam or update',
                  icon: CupertinoIcons.add_circled,
                  onTap: () => openPage(context, const EventEditorPage()),
                ),
                const Divider(),
                SettingsRow(
                  'Manage class routine',
                  icon: CupertinoIcons.rectangle_grid_2x2,
                  onTap: () => openPage(context, const RoutinePage()),
                ),
              ],
              const SectionHeader('Make it comfortable'),
              const Label('Appearance'),
              const SizedBox(height: 12),
              ChoiceBar<Appearance>(
                values: Appearance.values,
                selected: p.appearance,
                label: (v) => switch (v) {
                  Appearance.system => 'System',
                  Appearance.light => 'Light',
                  Appearance.dark => 'Dark',
                },
                onChanged: (v) => context.read<ProfileBloc>().add(
                  ProfileSaved(p.copyWith(appearance: v)),
                ),
              ),
              const SizedBox(height: 20),
              SettingsRow(
                'Notifications',
                subtitle: 'Defaults, updates and daily summary',
                icon: CupertinoIcons.bell,
                onTap: () => openPage(context, const NotificationPage()),
              ),
              const Divider(),
              SettingsRow(
                'Personal notes',
                subtitle: 'Your private academic memory',
                icon: CupertinoIcons.square_pencil,
                onTap: () => openPage(context, const NotesPage()),
              ),
              const SectionHeader('Account'),
              SettingsRow(
                'Academic membership',
                subtitle: m.label,
                icon: CupertinoIcons.person_2,
                onTap: () => _info(
                  context,
                  'Academic membership',
                  '${m.programName}\n${m.label}\n\nYour account can support more than one membership. Section changes will use a new verified access code when the backend is connected.',
                ),
              ),
              const Divider(),
              SettingsRow(
                'Privacy',
                icon: CupertinoIcons.lock_shield,
                onTap: () => _info(
                  context,
                  'Your private space',
                  'Personal notes, reminder choices and preparation progress belong only to you. Shared events belong to the section.\n\nThis preview uses local data. Google authentication and cloud services are not connected.',
                ),
              ),
              const Divider(),
              SettingsRow(
                'About MyClass',
                icon: CupertinoIcons.info_circle,
                onTap: () => _info(
                  context,
                  'A little more clarity.',
                  'MyClass brings your academic day into focus.\n\nFrontend preview 1.0\nBuilt with Flutter. Campus data and people are illustrative.\n\nFor access problems, contact your class representative.',
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () async {
                  final bloc = context.read<AuthBloc>();
                  if (await confirmAction(
                    context,
                    title: 'Sign out?',
                    message:
                        'Your profile preferences are saved on this device. Local session edits remain available until the app closes.',
                    confirm: 'Sign out',
                  )) {
                    if (!bloc.isClosed) bloc.add(AuthLoggedOut());
                  }
                },
                icon: const Icon(CupertinoIcons.square_arrow_right, size: 17),
                label: const Text('Sign out'),
              ),
              if (s.error != null) ErrorNotice(s.error!),
              const SizedBox(height: 24),
              const Divider(),
              SettingsRow(
                'Product preview',
                subtitle: 'Explore days, roles and connection states',
                icon: CupertinoIcons.slider_horizontal_3,
                onTap: () => openPage(context, const PreviewPage()),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }

  void _info(BuildContext context, String title, String message) => openSheet(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.type.headlineSmall),
          const SizedBox(height: 18),
          Text(
            message,
            style: context.type.bodyLarge?.copyWith(
              height: 1.65,
              color: context.colors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            'Got it',
            icon: CupertinoIcons.checkmark,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

class _NameEditor extends StatefulWidget {
  const _NameEditor();
  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  late final controller = TextEditingController(
    text: context.read<ProfileBloc>().state.profile.name,
  );
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ProfileBloc, ProfileState>(
    listenWhen: (a, b) => a.saving && !b.saving,
    listener: (c, s) {
      if (s.error == null) Navigator.pop(context);
    },
    builder: (c, s) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What should we call you?', style: context.type.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Preferred name',
              errorText: error,
            ),
          ),
          if (s.error != null) ...[
            const SizedBox(height: 16),
            ErrorNotice(s.error!),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            'Save name',
            busy: s.saving,
            icon: CupertinoIcons.checkmark,
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty || name.length > 50) {
                setState(
                  () => error = 'Use a name between 1 and 50 characters.',
                );
                return;
              }
              context.read<ProfileBloc>().add(
                ProfileSaved(s.profile.copyWith(name: name)),
              );
            },
          ),
        ],
      ),
    ),
  );
}
