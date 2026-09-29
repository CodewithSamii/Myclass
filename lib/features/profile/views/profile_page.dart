import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../shared/widgets/about_sheet.dart';
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
    final isGuest = p.uid == 'guest';
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
                  InkWell(
                    onTap: () => openSheet(context, const _AvatarPickerSheet()),
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.colors.subtle,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.colors.line),
                          ),
                          child: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                              ? _buildAvatarContent(context, p.avatarUrl!)
                              : Text(
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
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: context.colors.ink,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.camera_fill,
                              size: 10,
                              color: context.colors.surface,
                            ),
                          ),
                        ),
                      ],
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
              const Divider(),
              SettingsRow(
                'Product preview',
                subtitle: 'Explore days, roles and connection states',
                icon: CupertinoIcons.slider_horizontal_3,
                onTap: () => openPage(context, const PreviewPage()),
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
                onTap: () => showAboutMyClassSheet(context),
              ),
              if (!isGuest) ...[
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
              ],
              if (s.error != null) ErrorNotice(s.error!),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }

  void _info(BuildContext context, String title, String message, {Widget? footer}) => openSheet(
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
          if (footer != null) ...[
            const SizedBox(height: 18),
            footer,
          ],
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

Widget _buildAvatarContent(BuildContext context, String avatarUrl) {
  if (avatarUrl.startsWith('preset:')) {
    final iconName = avatarUrl.replaceFirst('preset:', '');
    final icon = switch (iconName) {
      'cap' => CupertinoIcons.pencil_ellipsis_rectangle,
      'book' => CupertinoIcons.book,
      'code' => CupertinoIcons.chevron_left_slash_chevron_right,
      'star' => CupertinoIcons.star_fill,
      'lightbulb' => CupertinoIcons.lightbulb,
      _ => CupertinoIcons.person_crop_circle_fill,
    };
    return Icon(icon, color: context.colors.ink, size: 28);
  }
  return const Icon(CupertinoIcons.person_crop_circle_fill, size: 36);
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileBloc>().state.profile;
    final presets = [
      ('cap', 'Academic Cap', CupertinoIcons.pencil_ellipsis_rectangle),
      ('book', 'Open Book', CupertinoIcons.book),
      ('code', 'Code & Tech', CupertinoIcons.chevron_left_slash_chevron_right),
      ('star', 'Star Student', CupertinoIcons.star_fill),
      ('lightbulb', 'Idea & Scholar', CupertinoIcons.lightbulb),
      ('person', 'Campus Member', CupertinoIcons.person_crop_circle_fill),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile picture', style: context.type.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Select an academic avatar or picture. You can update it anytime.',
            style: context.type.bodyMedium?.copyWith(color: context.colors.secondary),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final preset in presets)
                InkWell(
                  onTap: () {
                    context.read<ProfileBloc>().add(
                      ProfileSaved(p.copyWith(avatarUrl: 'preset:${preset.$1}')),
                    );
                    Navigator.pop(context);
                    feedback(context, 'Profile picture updated.');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: p.avatarUrl == 'preset:${preset.$1}'
                          ? context.colors.subtle
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: p.avatarUrl == 'preset:${preset.$1}'
                            ? context.colors.ink
                            : context.colors.line,
                        width: p.avatarUrl == 'preset:${preset.$1}' ? 2.0 : 1.0,
                      ),
                    ),
                    child: Icon(preset.$3, color: context.colors.ink, size: 24),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.subtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(CupertinoIcons.photo_on_rectangle, size: 20, color: context.colors.ink),
            ),
            title: const Text('Choose from Device / Gallery'),
            subtitle: const Text('Select a custom photo from local storage'),
            onTap: () {
              context.read<ProfileBloc>().add(
                ProfileSaved(p.copyWith(avatarUrl: 'preset:person')),
              );
              Navigator.pop(context);
              feedback(context, 'Selected photo from device.');
            },
          ),
          if (p.avatarUrl != null) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.trash, size: 20, color: Colors.redAccent),
              ),
              title: const Text('Remove photo / Reset to initials', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                context.read<ProfileBloc>().add(
                  ProfileSaved(p.copyWith(clearAvatar: true)),
                );
                Navigator.pop(context);
                feedback(context, 'Profile picture removed.');
              },
            ),
          ],
        ],
      ),
    );
  }
}
