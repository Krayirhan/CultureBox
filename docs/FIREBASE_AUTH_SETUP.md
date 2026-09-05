# Firebase Auth setup

Sprint 2 adds the Firebase Auth repository boundary. The app must initialize `firebase_core` from environment-specific generated configuration (`google-services.json` / iOS plist supplied outside Git) before constructing `FirebaseAuthRepository`.

Sprint 6 adds `FirebaseBootstrap`. Pass `--dart-define=CULTUREBOX_FIREBASE=true` only in a configured build. Without that flag, local guest development intentionally remains Firebase-free. With the flag and missing platform configuration, initialization fails explicitly; there is no silent production fallback.

For local emulator runs, call `FirebaseBootstrap.useEmulators()` after initialization (Auth `9099`, Firestore `8080`). Never enable emulator endpoints in a production build.

Supported operations: email/password sign-in, registration, password reset, sign-out and auth-state restoration. Guest mode remains local-only and does not require Auth.

Required manual setup (not performed here):

1. Create/select the existing Firebase Spark project.
2. Register Android package `com.krayirhanstudio.culturebox`.
3. Generate platform config files outside source control.
4. Enable Email/Password provider in Firebase Auth.
5. Enable Auth Emulator for local tests.

No Blaze billing, Cloud Functions, Supabase or committed secrets are required.
