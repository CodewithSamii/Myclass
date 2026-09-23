# MyClass

**Your academic life, in one place.**

A complete, interactive Flutter frontend for a university-wide academic workspace. The product name is MyClass. The interface is phone-first, with a second-column layout on larger tablets, intentional light and dark themes, and realistic local repositories.

## Run the app

Use Flutter 3.35 or later.

```sh
flutter pub get
flutter run
```

Choose an iOS simulator or Android emulator, or use a connected device. Platform scaffolds and MyClass launcher icons are included. Google credentials and Firebase configuration are not required.

For a browser:

```sh
flutter run -d chrome
```

For a release preview:

```sh
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 --directory build/web
```

Open `http://localhost:8080`. A separately packaged browser preview is also provided; it requires Python only, not the Flutter SDK.

## First visit

1. Select **Get started** and enter a preferred name.
2. Choose a program type, department, program, batch and section.
3. Enter **MYCLASS64** as the public preview access code. An incorrect code demonstrates the recovery state.
4. Select **Continue with Google**. Authentication is simulated.

For the fullest fixture set, select **Undergraduate → Computer Science & Engineering → B.Sc. in Computer Science & Engineering → Batch 64 → Section I**. Business, Law and English, including postgraduate programs, also have valid structures and discipline-aware sample content.

The normal starting role is **Student**. To inspect representative tools, go to **Profile → Product preview → Class representative**. Create events from Schedule's add button or Profile. Open an event's overflow menu to edit, reschedule, cancel, restore or delete it. Open a class or Routine to change a repeating class.

## What works

- Concise introduction, three-stage setup, access-code verification, mock Google sign-in, returning sign-in and incomplete-profile routing.
- Context-sensitive Home with current activity, next activity, urgent deadlines, chronological agenda, tomorrow preview and change feed.
- Day / Week / Month schedule, persistent date selection across tabs, workload summaries, class gaps, conflict warnings, private note reminders, and a separate repeating routine.
- Workload filters, grouping by date/course/type and private completion independent of shared event status.
- Event details, expandable syllabus, instructions, attachment previews, personal reminders, linked private notes and visible change history.
- Create/edit/reschedule/cancel/restore/delete shared events with validation, review, authorization checks and failed-save recovery.
- Private quick notes, linked notes, editing, deletion, completion and optional reminder times.
- Four bus routes with directional departures, return trips and estimated stop times. No live tracking.
- Department-aware faculty directory, search, profiles, office information and copying contact details.
- Debounced, categorized global search with stale-result protection.
- Preferred-name editing, appearance, per-category reminder defaults, daily summary preferences, account context and sign-out.
- Preview controls for current class, morning, deadlines only, exam preparation, completed day, weekend, semester break, exam day, busy overlaps, missing routine, offline/stale data and failures.

## What is simulated

The app is deliberately frontend-first. All academic writes and queries go through repository contracts. There are **no Firebase dependencies**.

| Area | Preview behavior |
| --- | --- |
| Google authentication | Local simulated identity. No real Google sign-in request. |
| Profile, theme and notification preferences | Persist on the current device using SharedPreferences. |
| Event/routine edits, notes and completion | Live in memory for the running session. Reset on a full process restart. |
| Access code | Public fixture `AULA64`; adapter returns an opaque mock grant. No section password is part of client-facing models. |
| Notifications | Preferences and scheduling inputs work. Device notification delivery is not connected. |
| Attachments | Interactive local sample previews and mock attachment creation. No file upload/download or cloud storage. |
| Offline mode | Explicit cached-data simulation. Shared writes are blocked; private local changes remain available. |
| People, bus routes and academic dates | Fictional fixtures. Not official university information. |
| Time | A controlled campus-local demo clock beginning Monday, September 21, 2026, 10:48 AM. Change it in Product preview. |

## Architecture

Feature-first Flutter with **flutter_bloc + Equatable**. Writes follow **UI event → feature BLoC → repository → stream/state → UI**. Local form controllers, selection-sheet search, sheet expansion and route/tab selection remain local where appropriate.

```text
lib/
  app.dart                 Dependency providers and authentication routing
  core/                    Repository exports, clock, failures, formatters
  design_system/           Light/dark tokens, typography, geometry, motion
  shared/                  Navigation shell and genuinely reusable components
  features/
    auth/                  Session state and Google-first entry
    onboarding/            Academic structure and verified setup
    home/                  Agenda and priority projections
    schedule/              Day/week/month, class details, routine
    events/                Shared academic data and details
    tasks/                 Private progress, filters and grouping
    notes/                 Private academic notes and reminders
    campus/                Bus and faculty experiences
    search/                Debounced cross-content search
    profile/               Identity, appearance and notification settings
    section_admin/         Progressive event editor and change detection
  demo/                    Replaceable local adapters, fixtures, preview controls
```

Start the backend handoff at `lib/core/dependencies.dart`. Keep the public repository interfaces and immutable domain objects; replace the adapters. The UI never reads mock collections. The reactive clock can use `SystemClock` instead of the demo clock.

See [architecture](docs/ARCHITECTURE.md), [design and motion](docs/DESIGN.md), [QA](docs/QA.md), and the [screen gallery](docs/GALLERY.html).

## Verify

```sh
flutter analyze
flutter test
```

Tests cover shared/private isolation, section access, authorization, concurrency, failed-save recovery, schedule projection, overlaps, unknown times, async initialization, actual onboarding, notes, reminders, event creation/rescheduling, returning login, tab state, themes and responsive rendering. The visual journey tests regenerate `docs/screenshots/` using the actual Flutter renderer.

Native device builds require the normal local Xcode or Android SDK installation. This environment verified Dart analysis, Flutter-rendered tests and a web release; it did not produce a signed iOS app or an Android APK.
