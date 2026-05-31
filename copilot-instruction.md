# UniSwap Coding Agent Instructions

- Use the Figma PNGs in assets/wireframes as pixel-accurate references; do not render the images at runtime.
- Follow the go_router routes and Riverpod provider names exactly as specified in the plan.
- Keep MVVM with StateNotifier for ViewModels.
- Use the GoRouter refresh notifier pattern (ChangeNotifier + ref.listen) to react to auth changes.
- Update README.md, documentation.md, and copilot-instruction.md after each completed step.
- Avoid adding features outside the current sprint scope.
- VS Code tasks are optional; only add if requested.
- Firebase config is generated in lib/firebase_options.dart; keep initialization using DefaultFirebaseOptions.
- Faculty options should load from Firestore when available; keep local fallback list.
- Sprint 2 screens should follow Figma wireframes and keep bottom nav shell routing.
- Prefer apply_patch for single-file edits and keep changes minimal.
