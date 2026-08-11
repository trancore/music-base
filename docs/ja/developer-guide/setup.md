# 開発環境

Flutter SDK、WindowsまたはmacOSのデスクトップ開発環境、Android開発環境、Node.jsを準備します。

```text
flutter pub get
pnpm install
flutter analyze
flutter test
pnpm docs:build
```

ドキュメントの開発サーバーは `pnpm docs:dev` で起動できます。
macOS開発ではmacOS 14.2以降を使用します。`flutter pub get`の後、`flutter build macos`でデスクトップターゲットを検証できます。App Store向け署名は今回の範囲外のため、配布前にXcodeで署名済みビルドを設定してください。
