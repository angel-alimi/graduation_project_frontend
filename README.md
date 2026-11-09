# LifeShare — Flutter app

Arabic-first (RTL) blood donation app with English, Ooredoo fonts, phone + OTP login,
and a clean layer for the Spring Boot backend.

## 1. Open and run (VS Code)

You need Flutter 3.22 or newer (`flutter --version`) and the Flutter + Dart extensions in VS Code.

```bash
cd lifeshare_app

# Creates the android/ ios/ web/ windows/ folders. It does NOT overwrite lib/, pubspec.yaml or assets/.
flutter create --org ps.lifeshare --project-name lifeshare .

flutter pub get
flutter run
```

The app starts in **demo mode** (`USE_MOCK=true`): it uses built-in sample data and accepts any 6-digit code,
so you can try every screen before the backend exists.

In VS Code you can also press **F5** after `flutter pub get`.

## 2. Connect to your Spring Boot backend

1. Run the backend in IntelliJ on port 8080.
2. Allow plain HTTP during development (only needed for `http://`, not `https://`):
   - **Android** — in `android/app/src/main/AndroidManifest.xml`, add to the `<application ...>` tag:
     `android:usesCleartextTraffic="true"`
   - **iOS** — in `ios/Runner/Info.plist`, add:
     ```xml
     <key>NSAppTransportSecurity</key>
     <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
     ```
3. Run the app against the backend:

```bash
# Android emulator (10.0.2.2 = your computer's localhost)
flutter run --dart-define=USE_MOCK=false --dart-define=API_URL=http://10.0.2.2:8080

# iOS simulator, Chrome or desktop
flutter run --dart-define=USE_MOCK=false --dart-define=API_URL=http://localhost:8080

# Real phone on the same Wi-Fi (use your computer's IP)
flutter run --dart-define=USE_MOCK=false --dart-define=API_URL=http://192.168.1.20:8080
```

Every endpoint, JSON field and enum the app expects is in **API_CONTRACT.md**.

To make this permanent in VS Code, add a `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    { "name": "LifeShare (demo data)", "request": "launch", "type": "dart" },
    {
      "name": "LifeShare (Spring Boot)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=USE_MOCK=false", "--dart-define=API_URL=http://10.0.2.2:8080"]
    }
  ]
}
```

## 3. Project structure

```
lib/
  main.dart                  starts the app, loads saved language + session
  app.dart                   MaterialApp: theme, Arabic/English, RTL/LTR
  config/app_config.dart     API URL, demo mode, 56-day cooldown, minimum age
  core/
    strings.dart             every Arabic + English text (add new text here)
    theme.dart               colours, fonts, buttons, inputs
  models/
    enums.dart               BloodType (+ compatibility), Gender, Urgency, statuses
    models.dart              City, Hospital, AppUser, BloodRequest, ... with fromJson/toJson
  data/
    lifeshare_api.dart       the interface every screen uses
    remote_api.dart          real calls to Spring Boot (paths match API_CONTRACT.md)
    mock_api.dart            sample data for demo mode
    api_client.dart          HTTP + JWT header + error handling
  state/app_state.dart       language, token, user, cities/hospitals; context.app / context.tr()
  widgets/                   mascot, bottom bar, inputs (phone, OTP), cards, shared UI
  screens/
    splash_screen.dart       logo while the session loads
    welcome_screen.dart      Get started / Log in
    intro_screen.dart        3 get-started slides
    auth/                    sign-up info → phone → OTP, and login (phone → OTP)
    home_shell.dart          header + 5 tabs + bottom bar
    tabs/                    requests, feed, dashboard, profile, settings
    sheets/                  new request, request details + eligibility, donation date
    notifications_screen.dart
assets/
  fonts/                     Ooredoo Arabic + Ooredoo Latin
  images/                    logo_full.png (splash), logo_drop.png (header)
```

## 4. Common tasks

- **Change text** → `lib/core/strings.dart` (both `ar` and `en`).
- **Change colours** → `lib/core/theme.dart` (`AppColors`).
- **Add an endpoint** → add a method to `lifeshare_api.dart`, then implement it in `remote_api.dart` and `mock_api.dart`.
- **Default language** → `AppState.create()` in `lib/state/app_state.dart` (`'ar'`).

## 5. Not included yet

- Push notifications (Firebase Cloud Messaging). The user table can take an `fcmToken` through `PATCH /api/users/me` when you add it.
- Editing the profile (the button shows "coming soon").
