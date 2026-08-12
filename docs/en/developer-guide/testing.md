# Testing

Run the checks relevant to each change:

```text
dart format .
flutter analyze
flutter test
flutter build windows
flutter build macos
pnpm docs:build
```

Tests requiring SMB, a CD drive, or the MusicBrainz API should be separated from unit tests and treated as integration tests. Report why any external-dependency test could not be run.
