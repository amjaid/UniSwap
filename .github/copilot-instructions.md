# UniSwap Copilot Instructions

## Project Basics
- Flutter 3.19.0 (Dart 3.3.0)
- MVVM with Riverpod StateNotifier
- go_router for navigation
- Firebase Auth, Firestore, Storage, Messaging

## Workflow
- Prefer small, incremental edits using apply_patch.
- Run flutter analyze after meaningful changes.
- Avoid introducing non-ASCII characters unless already present.

## UI Rules
- Keep screens aligned to Figma wireframe PNGs.
- Prevent RenderFlex overflows on narrow widths.

## Data + Providers
- Prefer feature-scoped providers in viewmodels.
- Firestore collections: users, conversations, conversations/{id}/messages.

## Run
- Start web app: flutter run -d chrome
- Hot restart: press R in the run terminal

## Documentation
- Keep README.md and documentation.md up to date with sprint status and routes.
- If Storage CORS is needed for web uploads, document it in docs/storage-cors-fix.md.
