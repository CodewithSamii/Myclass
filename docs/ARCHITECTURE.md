# Architecture and backend handoff

## Ownership boundaries

Shared academic truth and private preparation are different models, repositories and BLoCs. `AcademicEvent.status` belongs to the section. `PersonalProgress.completed` belongs to one UID. A completion tap can only call `ProgressRepository`; it cannot edit an event.

| Contract | Responsibility | Primary consumer |
| --- | --- | --- |
| AuthRepository | Restore/sign in/sign out a provider identity | AuthBloc |
| AcademicStructureRepository | Filtered structure and access verification | OnboardingBloc |
| ProfileRepository | User identity, memberships, active section and preferences | AuthBloc, ProfileBloc |
| ScheduleRepository | Courses, academic calendar periods and repeating classes | ScheduleBloc |
| EventRepository | Shared events, mutations and update feed | EventsBloc, EventEditorBloc |
| ProgressRepository | UID-scoped completion and reminder overrides | TasksBloc |
| NotesRepository | UID-scoped private notes | NotesBloc |
| BusRepository | Routes, stops and directional departures | CampusBloc |
| FacultyRepository | University faculty directory | CampusBloc |
| SearchRepository | Categorized authorized search results | SearchBloc |

`MockStore` is internal to the local adapters. It is not an application state container or a UI dependency. Adapters expose snapshots as unmodifiable lists and stream changes. Multiple feature BLoCs can observe the same repository without becoming coupled to one another.

## Domain decisions

- Program type, department, program, batch and section have independent identifiers. The selected membership also stores the department identifier. Programs are not inferred from CSE-specific screen logic.
- `UserProfile.memberships` and `activeSectionId` support future multiple memberships and section changes. Profile updates preserve identity. A new active section requires a verification grant in the mock repository.
- `AcademicEvent` has optional start/end times, a separate deadline, optional location, optional attachments, syllabus topics, instructions, creator, timestamps, status and a change history. TBA time is null, not midnight.
- Repeating `ClassSession` data is separate from one-off assessments. `AcademicPeriod` can suspend recurring classes while leaving explicitly scheduled assessments intact.
- `AgendaProjection` combines classes and events and detects real temporal intersections, excluding deadlines, cancelled items and unknown times. `HomeProjection` picks current/next activity and preparation priorities.
- Reminder offsets are integer minutes. `PersonalProgress.reminderOffsets == null` means inherit the user's current category defaults; `[]` means explicitly off. A CR's suggestion is displayed as a suggestion that a student can apply.
- A private note may reference an event and have its own timestamp reminder. Notes do not become section content.
- Shared edits append meaningful before/after history. Routine updates also enter the shared change feed.
- Completion mutations are serialized, so rapid repeated taps have predictable results. Search debounces input and discards responses for superseded queries.

## Async and recovery

The models support loading, loaded, updated, offline, error, permission denied, not found and empty states. Read failures retain usable data. Shared offline writes fail visibly, with drafts retained in the event editor. Campus errors have retry actions. Unknown schedules remain distinct from genuinely quiet days.

The ScheduleBloc deliberately awaits metadata **before** copying the current state. That preserves a routine snapshot that may have arrived while courses were loading. A regression test guards this race.

Home, Schedule and Tasks derive their views from repository streams; they do not independently mutate copies of shared events. Tab state is retained with the workspace IndexedStack and feature BLoC lifetimes. Detail routes stay subscribed, so edits elsewhere refresh their content.

## Connecting Firebase later

1. Implement AuthRepository with Google/Firebase Authentication. Return `AuthIdentity(uid, email)` and let AuthBloc load the profile.
2. Implement academic-structure reads and a trusted access-verification endpoint. Exchange the code for a membership grant; never download a section secret or a password hash to validate it in the client.
3. Implement ProfileRepository with resolved memberships. Authorization must be enforced by trusted backend rules/services. The preview role switch and local mock checks are demonstration tools, not a security boundary.
4. Implement event/schedule streams using the existing contracts. Map Firebase errors to `AppFailure` and feed metadata. Keep Firestore snapshots, document references and timestamp conversions inside the adapters.
5. Implement private progress and notes under the authenticated UID with backend access enforcement.
6. Replace sample attachment metadata/previews with a file-provider abstraction and Firebase Storage-backed URLs. Keep upload mechanics outside the event widgets.
7. Feed notification scheduling from changes to event time/status, per-event overrides, global defaults, notes, membership, and account state. Reconcile schedules by stable event/note ID: cancel outdated instances, then schedule future offsets. Cancellation, personal completion and sign-out must cancel the relevant pending reminders. TBA events cannot schedule time-based alerts until a time exists.
8. Use FCM for shared changes. On receipt, refresh the authoritative repository and reconcile local reminders; a push body is not shared academic truth.
9. Inject `SystemClock` and remove the preview controls from the production composition. Repository adapters should normalize UTC instants to the university's configured timezone and preserve all-day date semantics.

No Firestore collection layout, real push delivery, offline sync engine, encrypted local storage, upload service or production access-code protocol is prescribed by this frontend build.

## Local lifecycle

Only the simulated sign-in flag and profile/preferences persist across application restarts. Event changes, notes and progress intentionally use session memory, as requested for the frontend phase. Sign-out closes feature BLoCs and subscriptions. The mock adapters retain session data if the same local account signs back in before the process exits.
