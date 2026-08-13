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

Android実機で起動する場合は、端末の開発者向けオプションとUSBデバッグを有効にして接続し、`flutter devices`で認識を確認します。Zedでは `Run Music Base (Android: physical device)` Taskを実行すると、接続済みのAndroid実機を選択して起動します。

## デスクトップ配布物

WindowsとmacOSの配布物は、`v`で始まるGitタグを`main`へpushしたときにGitHub Actionsで生成され、GitHub Releaseへ添付されます。

- Windows: `MusicBase-Setup.exe`。インストール時にスタートメニューとデスクトップのショートカット作成を個別に選択できます。
- macOS: `MusicBase.dmg`。DMG内のアプリをApplicationsへコピーして使用します。現在はテスト配布向けのため、署名・Notarizationは未対応です。

Android実機はReleaseからインストールせず、USBデバッグを有効にした端末を接続して、Zedの `Run Music Base (Android: physical device)` Taskからローカルインストール・起動します。
