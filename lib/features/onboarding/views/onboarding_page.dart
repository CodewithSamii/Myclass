import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models.dart';
import '../../../design_system/tokens.dart';
import '../../../shared/widgets/primitives.dart';
import '../../../shared/widgets/selector.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/views/auth_page.dart';
import '../bloc/onboarding_bloc.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _code = TextEditingController();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Back',
                            onPressed: state.step == 0
                                ? () => context.read<AuthBloc>().add(
                                    AuthReturningRequested(),
                                  )
                                : () => context.read<OnboardingBloc>().add(
                                    SetupBack(),
                                  ),
                            icon: const Icon(
                              CupertinoIcons.arrow_left,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.step + 1} of 3',
                            style: context.type.bodySmall?.copyWith(
                              color: context.colors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: AnimatedContainer(
                                duration: Motion.normal,
                                height: 3,
                                margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                                decoration: BoxDecoration(
                                  color: i <= state.step
                                      ? context.colors.ink
                                      : context.colors.line,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Motion.normal,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        child: SingleChildScrollView(
                          key: ValueKey(state.step),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                          child: _content(context, state),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  Widget _content(BuildContext context, OnboardingState s) {
    final bloc = context.read<OnboardingBloc>();
    final auth = context.watch<AuthBloc>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(
          [
            'Your academic space',
            'A place for your class',
            'One last thing',
          ][s.step],
        ),
        const SizedBox(height: 12),
        Text(
          [
            'Find your class.',
            'This is your space.',
            'Everything’s ready.',
          ][s.step],
          style: context.type.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          [
            'Tell us where you study. We’ll bring the right things into focus.',
            'A private space for your routine, deadlines and academic updates.',
            'Save your academic space and pick up where you left off.',
          ][s.step],
          style: context.type.bodyLarge?.copyWith(
            color: context.colors.secondary,
          ),
        ),
        const SizedBox(height: 28),
        if (s.step == 0) ...[
          FieldLabel(
            'What should we call you?',
            TextFormField(
              initialValue: s.name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              onChanged: (v) => bloc.add(SetupNameChanged(v)),
              decoration: const InputDecoration(hintText: 'Preferred name'),
            ),
          ),
          _choice(
            'Program type',
            s.type,
            () => _select<String>(
              context,
              'Program type',
              Future.value(['Undergraduate', 'Postgraduate']),
              (v) => v,
            ),
          ),
          if (s.type != null)
            _choice(
              'Department',
              s.department?.name,
              () => _select<Department>(
                context,
                'Department',
                bloc.repository.departments(s.type!),
                (v) => v.name,
              ),
            ),
          if (s.department != null)
            _choice(
              'Program',
              s.program?.name,
              () => _select<AcademicProgram>(
                context,
                'Program',
                bloc.repository.programs(s.department!.id, s.type!),
                (v) => v.name,
              ),
            ),
          if (s.program != null)
            _choice(
              'Batch',
              s.batch?.label,
              () => _select<Batch>(
                context,
                'Batch',
                bloc.repository.batches(s.program!.id),
                (v) => v.label,
              ),
            ),
          if (s.batch != null)
            _choice(
              'Section',
              s.section?.label,
              () => _select<Section>(
                context,
                'Section',
                bloc.repository.sections(s.batch!.id),
                (v) => v.label,
              ),
            ),
          const SizedBox(height: 8),
          PrimaryButton(
            'Continue',
            onPressed: s.valid ? () => bloc.add(SetupAdvanced()) : null,
          ),
        ] else ...[
          Surface(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      s.step == 2
                          ? CupertinoIcons.checkmark_shield
                          : CupertinoIcons.person_2,
                      size: 22,
                      color: context.colors.sage,
                    ),
                    const Spacer(),
                    Badge(
                      s.step == 2 ? 'Verified' : 'Your section',
                      color: context.colors.sage,
                      background: context.colors.sageBg,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(s.program!.name, style: context.type.titleLarge),
                const SizedBox(height: 10),
                Text(
                  '${s.batch!.label} · ${s.section!.label}',
                  style: context.type.bodyLarge?.copyWith(
                    color: context.colors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (s.step == 1) ...[
            FieldLabel(
              'Section access code',
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                onSubmitted: (_) => bloc.add(SetupCodeSubmitted(_code.text)),
                decoration: const InputDecoration(
                  hintText: 'Enter your code',
                  prefixIcon: Icon(CupertinoIcons.lock, size: 18),
                ),
              ),
            ),
            if (s.error != null) ...[
              ErrorNotice(s.error!),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              'Join this section',
              busy: s.busy,
              onPressed: () => bloc.add(SetupCodeSubmitted(_code.text)),
            ),
            const SizedBox(height: 14),
            Text(
              'Ask your class representative for your section code.',
              style: context.type.bodyMedium?.copyWith(
                color: context.colors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Surface(
              color: context.colors.subtle,
              border: false,
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    size: 17,
                    color: context.colors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For this preview, use MYCLASS64.',
                      style: context.type.bodyMedium?.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Ready when you are, ${s.name.trim()}.',
              style: context.type.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Continue with Google to save your setup. Your section’s upcoming work will be waiting.',
              style: context.type.bodyLarge?.copyWith(
                color: context.colors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            if (auth.error != null) ...[
              ErrorNotice(auth.error!),
              const SizedBox(height: 16),
            ],
            GoogleButton(
              busy: auth.busy,
              onTap: () => context.read<AuthBloc>().add(
                AuthSetupSaved(s.name, s.membership, s.grant!),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Google sign-in is simulated in this frontend preview.',
              style: context.type.bodySmall?.copyWith(
                color: context.colors.faint,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _choice(String title, String? value, VoidCallback onTap) => FieldLabel(
    title,
    Surface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? 'Choose ${title.toLowerCase()}',
              style: context.type.bodyLarge?.copyWith(
                color: value == null
                    ? context.colors.faint
                    : context.colors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_down,
            size: 14,
            color: context.colors.secondary,
          ),
        ],
      ),
    ),
  );
  Future<void> _select<T extends Object>(
    BuildContext context,
    String title,
    Future<List<T>> options,
    String Function(T) label,
  ) async {
    final bloc = context.read<OnboardingBloc>();
    final chosen = await selectOption<T>(
      context,
      title: title,
      options: options,
      label: label,
    );
    if (chosen != null && !bloc.isClosed) bloc.add(SetupChoiceChanged(chosen));
  }
}
