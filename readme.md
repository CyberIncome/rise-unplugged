# Rise Unplugged

Rise Unplugged is a concept Flutter application that explores sleep wellness patterns with smart alarms, unplug rituals, and sleep debt tracking. This repository contains a fully scaffolded Flutter project with Android and iOS platform directories to ease local development.

## Structure

```
rise_unplugged/
├── android/              # Android application module
├── ios/                  # iOS runner project
├── lib/
│   ├── features/
│   │   ├── alarms/       # Smart alarm dashboards and scheduling
│   │   ├── sleep_debt/   # Sleep debt tracking and charts
│   │   └── unplug_timer/ # Post-alarm unplug flow
│   ├── services/         # Background, health, and notification helpers
│   └── shared/           # Themes, widgets, and utilities
└── test/                 # Placeholder widget tests
```

## Getting Started

1. Install Flutter 3.13 or newer and run `flutter pub get` from the `rise_unplugged/` directory.
2. Update the placeholder Android and iOS launcher assets before publishing.
3. Use `flutter run` targeting Android or iOS simulators to explore the onboarding, alarm dashboard, sleep debt charts, and unplug timer.
4. Optional integrations like AI insights, streaks, and data exports are controlled through feature flags in the Settings screen.

The project is intentionally modular so feature teams can iterate on alarms, sleep debt analytics, or unplug experiences independently.

## Key capabilities

- **Adaptive wake missions** – assign math challenges, mindful breathing sets, or focus tap patterns per alarm to guarantee true wakefulness before the unplug ritual begins.
- **Smart follow-ups and REM windows** – configure gentle nudges, smart wake buffers, and personalized ringtones for each alarm.
- **Sleep debt intelligence** – persist nightly sessions, visualize weekly debt, surface contextual tooltips, and import from health services when available.
- **Calming unplug rituals** – configurable timers with distraction blocking, mission-aware wake verification, and responsive gradients tuned for light or dark themes.

## Why keep Android and iOS folders?

Flutter ships a single Dart codebase that targets every supported platform from the `lib/` directory. The generated `android/` and `ios/` folders are still required because they provide the native host shells, Gradle/Xcode build scripts, and platform configuration files (permissions, notification channels, app metadata). Removing them would prevent `flutter run`, `flutter build`, or the respective app stores from packaging the project. When platform-specific code is unnecessary you can leave these folders untouched, but they must remain under version control so the shared Flutter widgets continue to compile for both Android and iOS from the same source tree.
