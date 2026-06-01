# UniSwap

UniSwap is a Flutter marketplace app for UTM students. Built with MVVM + Riverpod, go_router navigation, and Firebase Auth/Firestore/Storage/Messaging.

## Status
- Sprint 1: Complete (auth + email verification + wireframe-aligned UI)
- Sprint 2: Complete (home, explore, listing creation, listing detail, profile)
- Sprint 3: In progress (swap hub, swap detail, inbox + chat, unread, typing/presence, notifications)

## Features
- Auth: sign-in, sign-up, email verification, forgot password
- Listings: home + explore, listing detail, create listing
- Profile: username, editable username, profile photo, stats
- Swap Hub: timeline tracking and status actions
- Inbox + Chat: real-time Firestore listeners, unread counts, typing/presence
- Notifications: FCM + local notifications (docs/push-notifications.md)

## Setup
1. Install Flutter 3.19.0 (Dart 3.3.0) and run `flutter doctor`.
2. Run FlutterFire CLI to generate firebase_options.dart.
3. Add Firebase platform config files.
4. Fetch dependencies: `flutter pub get`.
5. Android: install SDK platforms 33 and 36 in Android Studio SDK Manager.
6. Firebase Auth: enable Email/Password provider in the Firebase console.

## Run
- Start the web app in Chrome: `flutter run -d chrome`
- Hot restart while running: press `R` in the Flutter run terminal
- Hot reload while running: press `r` in the Flutter run terminal

## Test Accounts
- Buyer: <email> / <password>
- Seller: <email> / <password>

## Firebase Notes
- Storage CORS fix for web uploads: see docs/storage-cors-fix.md
- Firestore collections used: users, conversations, conversations/{id}/messages

## Design References
- Figma wireframes (PNG) live in assets/wireframes and are used for layout reference only.

## Key Paths
- App theme: lib/config/theme.dart
- Routing: lib/config/routes.dart
- Auth viewmodels: lib/viewmodels/auth_viewmodel.dart
