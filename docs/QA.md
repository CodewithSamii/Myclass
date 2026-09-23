# Quality verification

The project is verified with Flutter's actual rendering and widget-test engine, not HTML representations of the UI. Inter and both icon fonts are explicitly loaded for the captures.

## Automated coverage

- Domain tests: access grants, non-CSE structure, shared-write permissions, UID isolation, shared/private completion separation, editor retry and history, cancellation visibility, dense overlaps, three same-day deadlines, TBA time, calendar suspension, adaptive Home, reminder inheritance, offline write behavior, task grouping, stale search responses, asynchronous schedule initialization and rapid completion taps.
- Full setup journey: preferred name and filtered structure selectors, bad-code recovery, successful section verification, simulated Google save, Home, sign-out and returning sign-in.
- Representative journey: progressive event form, syllabus/instructions, review, failed save with draft retention, successful creation, rescheduling through the date picker and cancellation.
- Personal journey: preserved schedule selection across tabs, preparation completion, multiple reminder offsets and event-linked private note editing.
- Render journeys: all five tabs, details, routine, buses, route stops, faculty, long faculty names, notes, notification preferences, search, introduction, setup, editor and tablet context.
- Responsive states: 390×844 phone, 320×720 phone with 150% text, 1100×900 tablet, light/dark themes, all controlled Home scenarios and offline data.

## Reproducing checks

```sh
flutter analyze
flutter test --reporter expanded
flutter build web --release --no-web-resources-cdn
```

`test/visual_journey_test.dart` and `test/interaction_test.dart` save actual screenshots under `docs/screenshots/`. `docs/GALLERY.html` opens those captures as a local gallery.

## Important limits

The Linux environment has the Flutter SDK and test renderer. It does not have a configured Android SDK or Xcode signing environment. Native keyboard behavior, platform-specific haptics, device performance and signed platform builds still need an iOS/Android device pass. The browser release compiles, but no real Firebase, Google OAuth, notification delivery or live university data is connected.

Notification preferences are functional data; notifications themselves are not sent. Attachment screens render sample content; arbitrary PDF/image rendering and cloud upload are deferred. Section/account changes are represented in the models but are not presented as a completed production transfer flow.
