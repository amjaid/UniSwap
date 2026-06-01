# UniSwap Documentation

## Overview
UniSwap is a Flutter app following MVVM with Riverpod, go_router navigation, and Firebase for auth, data, storage, and messaging. UI is built from Flutter widgets using the Figma PNGs in assets/wireframes as pixel-accurate references.

## Architecture
- Presentation: Flutter UI + go_router + theme
- Application: StateNotifier ViewModels and feature-scoped providers
- Data: Firebase Auth, Firestore, Storage, Messaging

## Routes
- /, /sign-in, /sign-up, /forgot-password
- /home, /explore, /swap-hub, /inbox, /profile
- /swap-hub/:swapId, /chat/:swapId
- /create-listing, /listing/:listingId, /saved, /settings
- /profile/:userId, /report/:targetType/:targetId

## Providers
### Core
- firebaseAuthProvider
- firebaseFirestoreProvider
- firebaseStorageProvider
- authStateProvider
- authServiceProvider
- firestoreServiceProvider
- storageServiceProvider

### Sprint 1
- signInViewModelProvider
- signUpViewModelProvider
- forgotPasswordViewModelProvider

### Sprint 2
- homeViewModelProvider
- exploreViewModelProvider
- createListingViewModelProvider

### Sprint 3
- swapHubViewModelProvider
- swapDetailViewModelProvider (family)
- inboxViewModelProvider
- chatViewModelProvider (family)

## Firestore Data Shape
- users/{userId}
	- full_name, username, email, phone, faculty, campus, photo_url
- conversations/{conversationId}
	- participants: [userId]
	- swap_id
	- role: buying | selling
	- other_user_name
	- other_user_avatar
	- other_user_verified
	- last_message
	- last_timestamp
	- unread_counts: { userId: number }
	- typing: { userId: bool }
	- presence: { userId: bool }
- conversations/{conversationId}/messages/{messageId}
	- sender_id
	- text
	- timestamp

## Firebase Setup
- Run FlutterFire CLI to generate firebase_options.dart.
- Add platform config files: google-services.json (Android) and GoogleService-Info.plist (iOS).
- Ensure Firestore persistence is enabled for offline support.
- Enable Email/Password in Firebase Auth for sign-up on web.

## Storage Notes (Web)
- Web profile photo uploads require CORS configuration.
- See docs/storage-cors-fix.md.

## Notifications
- FCM + local notifications via NotificationService.
- See docs/push-notifications.md for Cloud Functions sample.

## Android Build Notes
- compileSdk is set to 36 to satisfy Firebase and image plugins.
- Install SDK platforms 33 and 36 via Android Studio SDK Manager.

## Design System
- Primary: #7F3DFF
- Swap Orange: #FF8A34
- Success Green: #22C55E
- Fonts: Inter (body), Playfair Display (headers)

## Sprint Status
- Sprint 1: Complete (auth screens + providers + email verification)
- Sprint 2: Complete (home, explore, create listing, listing detail, profile)
- Sprint 3: In progress (swap hub, swap detail, inbox, chat, unread, typing/presence, notifications)
