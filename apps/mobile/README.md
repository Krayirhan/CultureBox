# mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# Local debug build

To test İzle, Oyna, and Oku together, use the provider-enabled build script from the repository root:

```powershell
.\scripts\build-mobile-debug.ps1
```

It reads the ignored root `.env.local`, validates provider-key presence without printing values, and passes the local debug signing SHA-1 needed by Android-restricted Google Books keys. Do not use a bare `flutter build apk` for provider testing; its compiled build will not include the provider keys.
