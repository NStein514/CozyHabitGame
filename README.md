# Cozy Habit Garden

A local-first Flutter habit tracker where everyday care grows a tiny garden.
Designed for iOS and Android with a gentle, pressure-free progression loop.

## What works

- First-run onboarding and a personalized gardener name
- Create and edit habits with an emoji, care category, daily target, and weekdays
- Single or multi-check-in daily goals
- Schedule-aware streaks that skip days when a habit is not due
- Archive, restore, permanently delete, and undo check-ins
- Dew rewards, deterministic garden levels, and collectible purchases
- Persistent on-device state with automatic migration from the original schema
- Save/load recovery messaging instead of crashing on damaged data
- Animated garden, unlockable plants, creatures, and decorations
- Original hand-painted garden environment and transparent plant artwork
- Weekly activity, a 28-day care calendar, and per-habit completion rates
- App settings, a full reset flow, responsive semantics, and tooltips
- One consolidated VS Code Widget Preview playground for the full application
- Preview-only controls to advance dates, simulate a week, earn dew, and test growth

## Project structure

```text
lib/
  garden_app.dart       App startup and onboarding gate
  garden_store.dart     State, persistence, rewards, and mutations
  models.dart           Habit domain logic and data migration
  screens/              Full application screens
  widgets/              Reusable UI components
  theme/                Shared theme and design tokens
  widget_previews.dart  Single interactive full-app @Preview entry point
  debug/                Isolated clock and progression controls for the preview
test/
  models_test.dart
  garden_store_test.dart
  widget_test.dart
```

Generated game artwork lives under `assets/images/garden/` and
`assets/images/plants/`. `tool/prepare_plant_assets.py` reproducibly normalizes
the generated transparent cutouts to consistent 512×512 Flutter assets.

## Run locally

```sh
flutter pub get
flutter run
```

Android builds require Android Studio/the Android SDK and `ANDROID_HOME`. iOS
builds require macOS with Xcode. On Windows, Flutter plugins also require
Developer Mode so symlinks can be created.

## Verify

```sh
flutter analyze
flutter test
```

The current suite contains 13 tests covering scheduling, streaks, multi-check-in
limits, reward reversals, level boundaries, archive/restore, purchases, legacy
migration, habit editing, and primary navigation.
