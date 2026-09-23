# MedTrack Flutter App

A Material 3 Flutter companion app for the Smart Medical Dispenser IoT project (Arduino Uno + servo motors).

## Architecture

```
lib/
├── main.dart                          # Entry point, DI wiring, app shell
├── models/
│   └── models.dart                    # Compartment, DoseEvent, DoseStatus
├── repositories/
│   ├── dose_repository.dart           # Abstract interface (UI depends on this)
│   └── local_dose_repository.dart     # SharedPreferences implementation
├── services/
│   └── notification_service.dart      # Local notifications
├── providers/
│   ├── today_provider.dart            # Home screen state + countdown logic
│   ├── schedule_provider.dart         # Compartment CRUD
│   └── history_provider.dart          # Event log + adherence
├── screens/
│   ├── today_screen.dart              # Home / Today tab
│   ├── schedule_screen.dart           # Schedule tab
│   ├── history_screen.dart            # History tab
│   └── settings_screen.dart          # Settings tab
├── widgets/
│   └── shared_widgets.dart            # StatusPill, CountdownRing, AdherenceCard, DateHeader
└── theme/
    └── app_theme.dart                 # All design tokens + ThemeData
```

## Adding the Hardware Layer Later

The app is built around the `DoseRepository` interface. To add real hardware sync:

1. Create `lib/repositories/hardware_dose_repository.dart` implementing `DoseRepository`
2. In `main.dart`, swap `LocalDoseRepository` for `HardwareDoseRepository` (or make it configurable)
3. No UI files need to change.

## Building

```bash
# Install dependencies
flutter pub get

# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Design Palette

| Token       | Value     | Use                         |
|-------------|-----------|-----------------------------|
| Primary     | #028090   | Teal — actions, AppBar      |
| Success     | #02C39A   | Mint — collected status     |
| Attention   | #FFB347   | Amber — pending status      |
| Error       | #E53935   | Red — missed status         |
| Background  | #F5F9F8   | Off-white                   |
| Text        | #16262B   | Near-black                  |
