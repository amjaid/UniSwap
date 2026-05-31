# UniSwap

A Flutter marketplace app for UTM students. Built with MVVM + Riverpod, go_router navigation, and Firebase.

## Status
- Sprint 1: Complete (auth + email verification + wireframe-aligned UI)
- Sprint 2: In progress (home, explore, listing creation)
- Dependencies installed and analyzer clean
- VS Code tasks: skipped (optional)
- Sprint 1 UI: sign-in/sign-up updated to match wireframes
- Firebase setup: flutterfire configured (lib/firebase_options.dart)
- Android: compileSdk set to 36; SDK 33/36 required for build
- Forgot password + splash screen styled; faculty list loads from Firestore when available
- Campus options: Johor, UTM KL; faculty fallback list includes MJIIT and other faculties
- Profile page: stats, tabs, saved/report actions, logout

## Setup
1. Install Flutter 3.19.0 (Dart 3.3.0) and run `flutter doctor`.
2. Run FlutterFire CLI to generate firebase_options.dart.
3. Add Firebase platform config files.
4. Fetch dependencies: `flutter pub get`.
5. Android: install SDK platforms 33 and 36 in Android Studio SDK Manager.
6. Firebase Auth: enable Email/Password provider in the Firebase console.

## Design References
- Figma wireframes (PNG) live in assets/wireframes and are used for layout reference only.

## Key Paths
- App theme: lib/config/theme.dart
- Routing: lib/config/routes.dart
- Auth viewmodels: lib/viewmodels/auth_viewmodel.dart
