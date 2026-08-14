---
name: create-pull-request
description: 確認済みのローカルブランチを公開し、変更範囲・検証結果・プロジェクトのテンプレートに沿ったドラフト PR を作成する。ユーザーが PR の作成、公開、更新を依頼したときに使用する。
---

# PR を作成する

## 概要

現在のブランチを安全に push し、リポジトリのデフォルトブランチを対象とするドラフト PR を作成する。`.github/pull_request_template.md` に沿い、マージやレビュー準備完了の判断はユーザーに委ねる。

## 手順

### 1. 前提条件を確認する

- `AGENTS.md` と `.github/pull_request_template.md` を読む。
- 次を並列で実行する:
  - `git status --short --branch`
  - `git diff`
  - リモート追跡状態の確認
  - `git log` と `git diff [base-branch]...HEAD`
- ベースブランチ、リモート、リポジトリ名を特定する。
- 無関係な変更や対象が曖昧な変更を、確認なしに公開しない。
- `gh --version` と `gh auth status` を確認する。認証がない・期限切れの場合は `gh auth login -h github.com` を案内する。

### 2. ブランチを準備する

- `main`、`master`、またはリモートのデフォルトブランチ上にいる場合は、`create-branch` Skill に従い `agent/<short-description>` 形式の作業ブランチを作成する。
- コミットが存在し、作業ツリーに意図しない変更がないことを確認する。
- push 前に関連する検証を実行する。実行できない検証は理由を記載する。
- ユーザーがレビュー準備完了を明示しない限り、ドラフト PR を作成する。

### 3. push する

- `git push -u origin HEAD` で tracking 付き push を行う。
- PR 作成前に、push したブランチとベースブランチの差分を確認する。
- force push、ブランチ削除、マージ、無関係なリモート状態の変更は行わない。

### 4. PR 本文を作成する

- 完全な差分を要約する簡潔なタイトルを付ける（日本語）。
- 技術名・ブランチ名・識別子など必要な固有名詞は原表記のまま残してよい。
- `.github/pull_request_template.md` のセクション順を守る。
- 変更内容、変更理由、利用者・開発者への影響、バグ修正時の原因、実行した検証コマンドを記載する。

### 5. 作成して確認する

```bash
gh pr create --draft --title "..." --body "$(cat <<'EOF'
## 概要
...

EOF
)"
```

- 既存 PR の更新には `gh pr edit <number>` を使用し、重複 PR を作らない。
- ベースブランチが明らかでない場合は `gh repo view --json nameWithOwner,defaultBranchRef` で確認する。
- 作成された PR の URL、番号、タイトル、base/head ブランチ、ドラフト状態を報告する。
- ユーザーが明示的に依頼しない限り、Ready for review への変更、マージ、クローズ、レビューコメントの解決は行わない。
