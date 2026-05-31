# UniSwap Documentation

## Overview
UniSwap is a Flutter app that follows MVVM with Riverpod, go_router navigation, and Firebase for auth, data, storage, and messaging. UI is built from Flutter widgets using the Figma PNGs in assets/wireframes as pixel-accurate references.

## Architecture
- Presentation: Flutter UI + go_router + theme
- Application: ViewModels (StateNotifier) and feature-scoped providers
- Data: Firebase Auth, Firestore, Storage, Messaging

## Routes
- /, /sign-in, /sign-up, /forgot-password
- /home, /explore, /swap-hub, /inbox, /profile
- /swap-hub/:swapId, /chat/:swapId
- /create-listing, /listing/:listingId, /saved, /settings
- /profile/:userId, /report/:targetType/:targetId

## Provider Map (Sprint 1)
Global providers live in lib/viewmodels/auth_viewmodel.dart for now and will be moved to core modules in Sprint 1 cleanup.

- firebaseAuthProvider
- firebaseFirestoreProvider
- authStateProvider
- authServiceProvider
- firestoreServiceProvider
- signInViewModelProvider
- signUpViewModelProvider
- forgotPasswordViewModelProvider

Faculty list is fetched from the Firestore `faculties` collection with a local fallback.
Campus options are Johor and UTM KL.

## Provider Map (Sprint 2)
- homeViewModelProvider
- exploreViewModelProvider
- createListingViewModelProvider

## Firebase Setup
- Run FlutterFire CLI to generate firebase_options.dart.
- Add platform config files: google-services.json (Android) and GoogleService-Info.plist (iOS).
- Ensure Firestore persistence is enabled for offline support.
- Firebase packages are aligned to firebase_core v3 and compile clean under Flutter 3.19.0.
- FlutterFire configuration generated lib/firebase_options.dart.
- Enable Email/Password in Firebase Auth for sign-up on web.

## Android Build Notes
- compileSdk is set to 36 to satisfy Firebase and image plugins.
- Install SDK platforms 33 and 36 via Android Studio SDK Manager.
- Android SDK command-line tools are not installed in this environment.

## Design System
- Primary: #7F3DFF
- Swap Orange: #FF8A34
- Success Green: #22C55E
- Fonts: Inter (body), Playfair Display (headers)

## Sprint Status
- Sprint 1: Complete (auth screens + providers + email verification)
- Flutter analyze: clean
- VS Code tasks: optional (skipped)
- Sprint 2: In progress (home, explore, create listing, listing detail)
