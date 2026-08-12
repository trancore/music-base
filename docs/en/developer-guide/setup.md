# Development setup

Prepare the Flutter SDK, Windows or macOS desktop tooling, Android tooling, and Node.js.

```text
flutter pub get
pnpm install
flutter analyze
flutter test
pnpm docs:build
```

Start the documentation development server with `pnpm docs:dev`.
For macOS development, use macOS 14.2 or later. Run `flutter pub get`, then validate the desktop target with `flutter build macos`. App Store signing is outside the current scope; configure a signed Xcode build before distributing the app.
