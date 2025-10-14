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

## Step-by-step setup

The guide below assumes you are starting from scratch on macOS, Windows, or Linux. Follow each step in order—everything happens inside the `rise_unplugged/` directory unless otherwise noted.

### 1. Install required tools

1. [Install Git](https://git-scm.com/downloads) so you can clone the repository.
2. [Install Flutter 3.13 or newer](https://docs.flutter.dev/get-started/install). During installation Flutter will also download the matching Dart SDK.
3. Add Flutter to your shell `PATH`:
   - macOS/Linux: `export PATH="/path/to/flutter/bin:$PATH"` (add to `~/.zshrc` or `~/.bashrc` for persistence).
   - Windows: Open **Start → "Edit the system environment variables"** → **Environment Variables** and append `C:\path\to\flutter\bin` to the `Path` entry under *System variables*.
4. Install a code editor/IDE with Flutter support (Android Studio, IntelliJ IDEA, or VS Code with the Flutter extension).
5. Install platform toolchains if you plan to run on:
   - **Android**: Android Studio (SDK + Emulator) and enable USB debugging for physical devices.
   - **iOS** (macOS only): Xcode with the iOS Simulator and an Apple Developer account for device provisioning.

### 2. Clone the project

```bash
git clone https://github.com/<your-org-or-user>/rise-unplugged.git
cd rise-unplugged/rise_unplugged
```

### 3. Validate your Flutter environment

Run the following command inside the `rise_unplugged/` directory:

```bash
flutter doctor
```

Resolve any issues the tool reports (e.g., missing Android licenses or iOS signing). Continue when everything shows a green checkmark or an actionable message you understand.

### 4. Fetch dependencies and generate platform files

```bash
flutter pub get
```

This downloads every Dart/Flutter package used by the app and updates generated metadata.

### 5. Configure local assets (optional but recommended)

Replace the default launcher icons and splash assets found under `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/` before publishing. You can use [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) to automate this if desired.

### 6. Run the application

1. Connect a device or start an emulator/simulator.
2. From the `rise_unplugged/` directory run:

   ```bash
   flutter run
   ```

3. Select your target device from the prompted list. The app launches with onboarding, smart alarms, sleep debt analytics, and the unplug timer experience ready to explore.

### 7. Execute automated checks

Run these commands before committing or publishing changes:

```bash
flutter analyze
flutter test
```

Both should complete without errors. The analyze step enforces lint rules; the tests verify alarm mission serialization and other flows.

### 8. Explore feature flags and sample data

The Settings screen exposes optional enhancements (AI insights, streaks, exports). Toggle them on to experience feature-flagged functionality. When running on a clean install the project seeds example alarms and unplug preferences so you can see the full experience immediately.
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
