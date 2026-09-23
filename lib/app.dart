import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/dependencies.dart';
import 'core/repositories.dart';
import 'core/models.dart';
import 'core/clock_cubit.dart';
import 'design_system/tokens.dart';
import 'demo/demo_controller.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/views/auth_page.dart';
import 'features/onboarding/bloc/onboarding_bloc.dart';
import 'features/onboarding/views/onboarding_page.dart';
import 'features/events/bloc/events_bloc.dart';
import 'features/schedule/bloc/schedule_bloc.dart';
import 'features/tasks/bloc/tasks_bloc.dart';
import 'features/notes/bloc/notes_bloc.dart';
import 'features/profile/bloc/profile_bloc.dart';
import 'features/campus/bloc/campus_bloc.dart';
import 'features/search/bloc/search_bloc.dart';
import 'shared/widgets/primitives.dart';
import 'shared/workspace_shell.dart';

typedef AulaApp = MyClassApp;

class MyClassApp extends StatelessWidget {
  const MyClassApp({super.key, required this.dependencies});
  final AppDependencies dependencies;
  @override
  Widget build(BuildContext context) {
    final d = dependencies;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: d.auth),
        RepositoryProvider<AcademicStructureRepository>.value(
          value: d.structure,
        ),
        RepositoryProvider<EventRepository>.value(value: d.events),
        RepositoryProvider<ScheduleRepository>.value(value: d.schedule),
        RepositoryProvider<ProfileRepository>.value(value: d.profiles),
        RepositoryProvider<ProgressRepository>.value(value: d.progress),
        RepositoryProvider<NotesRepository>.value(value: d.notes),
        RepositoryProvider<BusRepository>.value(value: d.buses),
        RepositoryProvider<FacultyRepository>.value(value: d.faculty),
        RepositoryProvider<SearchRepository>.value(value: d.search),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DemoController>.value(value: d.demo),
          BlocProvider(create: (_) => ClockCubit(d.clock)),
          BlocProvider(
            create: (_) => AuthBloc(d.auth, d.profiles)..add(AuthStarted()),
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, s) {
            if (s.phase == AuthPhase.ready && s.profile != null) {
              return _Workspace(
                key: ValueKey(s.profile!.uid + s.profile!.activeSectionId),
                profile: s.profile!,
                dependencies: d,
              );
            }
            return MaterialApp(
              title: 'MyClass',
              debugShowCheckedModeBanner: false,
              theme: aulaTheme(Brightness.light),
              darkTheme: aulaTheme(Brightness.dark),
              home: s.phase == AuthPhase.loading
                  ? const Scaffold(
                      body: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Skeleton(rows: 5),
                        ),
                      ),
                    )
                  : s.phase == AuthPhase.setup
                  ? BlocProvider(
                      create: (_) => OnboardingBloc(d.structure),
                      child: const OnboardingPage(),
                    )
                  : s.phase == AuthPhase.returning
                  ? const ReturningPage()
                  : const IntroPage(),
            );
          },
        ),
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    super.key,
    required this.profile,
    required this.dependencies,
  });
  final UserProfile profile;
  final AppDependencies dependencies;
  @override
  Widget build(BuildContext context) {
    final d = dependencies;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ProfileBloc(d.profiles, profile),
          lazy: false,
        ),
        BlocProvider(
          create: (_) => EventsBloc(d.events, profile.activeSectionId),
          lazy: false,
        ),
        BlocProvider(
          create: (_) =>
              ScheduleBloc(d.schedule, d.clock, profile.activeSectionId),
          lazy: false,
        ),
        BlocProvider(
          create: (_) => TasksBloc(d.progress, profile.uid),
          lazy: false,
        ),
        BlocProvider(
          create: (_) => NotesBloc(d.notes, profile.uid),
          lazy: false,
        ),
        BlocProvider(
          create: (_) => CampusBloc(
            d.buses,
            d.faculty,
            department: profile.membership.departmentId.isEmpty
                ? null
                : profile.membership.departmentId,
          ),
          lazy: false,
        ),
        BlocProvider(
          create: (_) =>
              SearchBloc(d.search, profile.uid, profile.activeSectionId),
        ),
      ],
      child: BlocBuilder<ProfileBloc, ProfileState>(
        buildWhen: (a, b) => a.profile.appearance != b.profile.appearance,
        builder: (context, s) => MaterialApp(
          title: 'MyClass',
          debugShowCheckedModeBanner: false,
          theme: aulaTheme(Brightness.light),
          darkTheme: aulaTheme(Brightness.dark),
          themeMode: switch (s.profile.appearance) {
            Appearance.system => ThemeMode.system,
            Appearance.light => ThemeMode.light,
            Appearance.dark => ThemeMode.dark,
          },
          themeAnimationDuration: Motion.normal,
          home: const WorkspaceShell(),
        ),
      ),
    );
  }
}
