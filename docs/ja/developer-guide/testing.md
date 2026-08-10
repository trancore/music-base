# テスト

変更内容に応じて、次の検証を実行します。

```text
dart format .
flutter analyze
flutter test
flutter build windows
pnpm docs:build
```

SMB、CDドライブ、MusicBrainz APIを必要とするテストは、ユニットテストと分けて統合テストとして扱います。実行できない外部依存テストは理由を報告します。
