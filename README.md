※ このアプリケーションは、バイブコーディングによって作成されています。

# Music Base

Windowsを先行対象とするFlutter製ミュージックプレイヤーです。
音源をローカルディレクトリまたはネットワーク上のSMB共有で管理し、WindowsでCDから取り込んだ音楽をAndroidからも再生できる構成を目指します。

> 現在は仕様整理とドキュメント基盤の初期段階です。アプリ本体の実装はこれから開始します。

## 主な方針

- Windows版を先行して開発する
- Android版はWindows版の安定後に追加する
- 音源の正本はユーザーが選択したローカルディレクトリまたはSMB共有に置く
- 音源参照先はローカルディレクトリまたはSMB共有から選択できるようにする
- 音源参照先はユーザーが変更・保存できるようにする
- WindowsではCDリッピングを提供する
- リッピング形式はFLACまたはMP3から選択できるようにする
- MusicBrainz APIからアルバム情報を取得する
- テーマ変更、ビジュアライザ、スペクトルアナライザを提供する

## 想定している機能

### Windows

- ローカルディレクトリの登録とスキャン
- SMB共有の登録・接続テスト・再接続
- 音源ライブラリのスキャンと検索
- 曲、アルバム、アーティストの表示
- 再生、キュー、シャッフル、リピート、プレイリスト
- CDのFLAC／MP3リッピング
- MusicBrainzによるアルバム情報取得
- タグとアルバムアートの保存
- テーマ変更
- ビジュアライザとリアルタイムスペクトルアナライザ

### Android

- ローカルディレクトリとSMB共有の参照
- Windowsで取り込んだ音源の再生
- ライブラリ検索とプレイリスト
- テーマ変更
- ビジュアライザとスペクトルアナライザ
- バックグラウンド再生とメディア操作

CDリッピングはWindows専用機能です。

## 音源ライブラリ

音源参照先は、ローカルディレクトリまたは管理者が用意したSMB共有から選択します。具体的なパスは利用環境によって異なります。

```text
ローカルディレクトリの例：`D:\Music`
SMB共有の例：`\\<server>\<share>\[subfolder]`
```

設定画面から、別のローカルディレクトリまたはSMBホスト、共有名、サブフォルダへ変更できるようにします。
認証が必要な共有ではユーザー名とパスワードを使用します。認証情報はソースコードやログへ保存しません。

音源ファイルは選択した参照先を正本とし、アプリ内のデータベースにはライブラリ情報をキャッシュします。

## ドキュメント

VitePressで日本語・英語のドキュメントを管理しています。

- [日本語ドキュメント](./docs/ja/)
- [English documentation](./docs/en/)

ドキュメントサイトのローカル開発にはNode.jsとpnpmを使用します。Node.jsのバージョンはmiseで固定しています。

```bash
pnpm install
pnpm docs:dev
```

本番ビルドとプレビューは次のコマンドで実行します。

```bash
pnpm docs:build
pnpm docs:preview
```

ドキュメントは`main`ブランチへのpush時にGitHub Pagesへデプロイします。

## 開発環境

### 必要なツール

- Flutter SDK
- Windowsデスクトップ開発環境
- Android開発環境（Android対応時）
- Node.js 24.19.0
- mise
- pnpm

Node.jsはプロジェクトルートの`mise.toml`で指定しています。

```bash
mise install
mise current
node -v
```

### Flutterの検証コマンド

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build windows
```

Android対応後は、必要に応じて次も実行します。

```bash
flutter build apk
```

## リポジトリ構成

```text
.
├── AGENTS.md                 # Codex向けのプロジェクトルール
├── docs/                     # VitePressドキュメント
│   ├── .vitepress/           # VitePress設定
│   ├── ja/                   # 日本語ドキュメント
│   └── en/                   # 英語ドキュメント
├── .github/workflows/        # GitHub Actions
├── mise.toml                 # Node.jsバージョン
└── package.json              # ドキュメント用Node.js設定
```

Flutterアプリのディレクトリ構成は、実装開始時にアーキテクチャ方針に合わせて追加します。

## 開発ルール

詳細な開発ルールは[AGENTS.md](./AGENTS.md)を参照してください。

特に次の方針を重視します。

- UI、状態管理、ドメインロジック、データアクセス、プラットフォーム固有処理を分離する
- Windows固有のCD処理をAndroidと共有するコードへ混在させない
- SMB、音楽再生、MusicBrainz、タグ処理、CDリッピング、音声解析をサービスとして分離する
- ユーザー向け挙動の変更時は、日本語と英語のドキュメントを更新する
- 外部APIや依存パッケージは、公式ドキュメントと対応OSを確認してから利用する

## ライセンス

ライセンスは未定です。
