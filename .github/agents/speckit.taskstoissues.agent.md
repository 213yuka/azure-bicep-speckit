````chatagent
---
description: 既存のタスクを利用可能な設計成果物に基づいて、依存関係順にアクション可能なGitHub Issueに変換する。
tools: ['github/github-mcp-server/issue_write']
---

## ユーザー入力

```text
$ARGUMENTS
```

処理を進める前に、ユーザー入力を**必ず**確認してください（空でない場合）。

## 概要

1. リポジトリルートから `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks` を実行し、FEATURE_DIR と AVAILABLE_DOCS リストを解析。すべてのパスは絶対パスであること。引数にシングルクォートを含む場合はエスケープ構文を使用。
1. 実行したスクリプトから **tasks** へのパスを抽出。
1. 以下を実行してGitリモートを取得：

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> リモートがGitHubのURLである場合のみ次のステップに進むこと

1. リスト内の各タスクについて、GitHub MCPサーバーを使用してGitリモートに対応するリポジトリに新しいIssueを作成。

> [!CAUTION]
> リモートURLと一致しないリポジトリにIssueを作成することは絶対に禁止

````
