# Product and interaction system

Aula answers the next-obligation question with hierarchy, not dashboard statistics.

## Visual language

Inter is bundled locally, with its OFL license. The type scale uses a small set of weights and sizes. Paper surfaces and graphite text anchor light mode; dark mode uses near-black surfaces, quiet raised planes and a pale focus panel. Semantic sage, amber and muted red distinguish changed, urgent and cancelled states. Subjects do not have arbitrary colors.

Tokens are centralized in `lib/design_system/tokens.dart`: spacing, radii, surfaces, text hierarchy, borders, motion, icons and touch-target baselines. Primary areas use a 24px page inset. Ordinary classes use light timeline rows; assessments use stronger surfaces. Tasks remain flat, efficient rows.

The Aula mark is a geometric, open A, drawn directly in Flutter and provided as SVG and platform launcher assets. Cupertino system icons provide one visual family. No remote image or font service is required.

## Priority and navigation

Home distinguishes the current activity, the next activity, what is due today, tomorrow's first obligation and recent changes. Quiet and assessment-only days have their own behavior. It never fabricates events just to populate a section.

Schedule defaults to a mobile-readable week: weekday workload indicators, a selected-day agenda and the rest of the week at a glance. Day view focuses the agenda. Month view uses subtle assessment indicators. Routine remains a separate repeating-class view. Cancelled entries remain visible and overlaps are labeled with words.

The five destinations preserve meaningful state. Tablet widths add a navigation rail; larger tablets add a compact academic-context column. Forms, long details and directories stay within readable content widths.

## Motion and feedback

- 140ms: immediate selection and completion feedback.
- 240ms: view changes, theme transitions and content expansion.
- 320ms: reserved sheet transition token; native route/sheet transitions retain platform continuity.
- `easeOutCubic`: default custom easing.
- Platform-style page transitions and native modal-sheet gestures preserve expected back navigation.
- Selection haptics accompany date/view choices. Light impact accompanies completion and successful event saves.

Animations explain a state change. No staggered dashboard entrances, decorative looping effects, parallax or gratuitous shared-element transitions are used.

## Accessibility and content resilience

The app uses semantics for navigation, selected dates and completion controls, text labels alongside status colors, and tooltip labels for icon-only actions. Long titles, unknown locations, absent syllabuses and variable attachment counts have explicit rendering paths.

The QA suite checks a 320px phone with 150% text. Body content continues scaling and wrapping. Navigation labels cap their scale at 120% to remain single-line and legible within five destinations; semantic labels remain complete. Timelines expand their time column at larger text scales. Long next-activity titles use a separate line.

## Preview inventory

Profile → Product preview exposes a controlled clock, role selection, offline/stale flags and one-shot failures. These controls are deliberately isolated from the regular student workflow. Campus information and authentication are clearly labeled as simulated where that distinction affects trust.
