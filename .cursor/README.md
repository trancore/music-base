# Cursor 向けエージェント設定

このディレクトリは [Cursor Agent](https://cursor.com/docs) 向けのプロジェクト設定です。リポジトリルートの `AGENTS.md` と `.codex/skills/` と内容を揃えています。

## 構成

| パス | 用途 |
|------|------|
| [rules/project-agents.mdc](rules/project-agents.mdc) | 常時適用するプロジェクト規約（`AGENTS.md` と同等） |
| [skills/](skills/) | コミット・ブランチ・PR・レビューなどのワークフロー |

## Codex との対応

| Codex | Cursor |
|-------|--------|
| `AGENTS.md` | `AGENTS.md` + `.cursor/rules/project-agents.mdc` |
| `.codex/skills/commit-changes/` | `.cursor/skills/commit-changes/` |
| `.codex/skills/create-branch/` | `.cursor/skills/create-branch/` |
| `.codex/skills/create-pull-request/` | `.cursor/skills/create-pull-request/` |
| `.codex/skills/review-changes/` | `.cursor/skills/review-changes/` |

`AGENTS.md` を更新した場合は、`.cursor/rules/project-agents.mdc` も同期してください。
