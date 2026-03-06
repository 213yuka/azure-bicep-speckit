# Feature Specification: GitHub Actions CI/CD パイプライン

**Feature Branch**: `001-github-actions-deploy`  
**Created**: 2026-03-06  
**Status**: Draft  
**Input**: User description: "GitHub Actions経由でAzure IaC (Bicep) をCI/CDデプロイするパイプラインの構築"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - PRでのBicepバリデーション自動実行 (Priority: P1)

開発者として、プルリクエストを作成したときにBicepテンプレートのバリデーションとWhat-If分析が自動実行され、
変更内容をレビューできるようにしたい。これにより壊れたテンプレートがmainブランチにマージされることを防ぎたい。

**Why this priority**: デプロイ前の品質ゲートとして最も重要。壊れたIaCコードがマージされると全環境に影響するため、最初に実現すべき機能。

**Independent Test**: テスト用PRを作成し、正常なBicepファイルでバリデーション成功、構文エラーのあるBicepファイルでバリデーション失敗を確認できる。

**Acceptance Scenarios**:

1. **Given** `infra/` 配下のBicepファイルが変更されたPR, **When** PRが作成される, **Then** GitHub Actionsワークフローが自動的にトリガーされ、`az bicep build` によるバリデーションが実行される
2. **Given** バリデーションワークフローが実行中, **When** Bicepファイルに構文エラーがある, **Then** ワークフローが失敗し、PRにエラー内容がコメントされる
3. **Given** バリデーションが成功, **When** What-If分析が実行される, **Then** 作成・変更・削除されるリソースの一覧がPRコメントとして投稿される
4. **Given** `infra/` 配下以外のファイルのみが変更されたPR, **When** PRが作成される, **Then** IaCバリデーションワークフローはスキップされる（不要な実行を防止）

---

### User Story 2 - mainマージ時のdev環境自動デプロイ (Priority: P2)

開発者として、PRがmainブランチにマージされたときにdev環境へ自動的にデプロイされるようにしたい。
手動デプロイの手間を省き、常にdev環境が最新のmainブランチと同期されている状態を維持したい。

**Why this priority**: 自動デプロイによりdev環境の鮮度を保ち、手動作業によるミスを排除する。バリデーション（P1）が前提。

**Independent Test**: mainブランチへのマージをトリガーにdev環境のリソースが期待通り更新されることを確認できる。

**Acceptance Scenarios**:

1. **Given** バリデーション済みのPRがmainにマージ, **When** マージイベント発生, **Then** dev環境へのデプロイワークフローが自動実行される
2. **Given** デプロイワークフローが実行中, **When** デプロイが成功, **Then** ワークフローの結果がリポジトリのActionsタブで確認でき、デプロイされたリソース情報が出力される
3. **Given** デプロイワークフローが実行中, **When** デプロイが失敗, **Then** チームに通知され（GitHub Actionsの通知機能）、失敗の詳細がログに記録される
4. **Given** `infra/` 配下以外のファイルのみがマージされた場合, **When** マージイベント発生, **Then** デプロイワークフローはスキップされる

---

### User Story 3 - prod環境への手動承認付きデプロイ (Priority: P3)

リリース担当者として、prod環境へのデプロイは手動承認ステップを経てから実行されるようにしたい。
誤って本番環境に変更が反映されることを防ぎ、適切なレビューとタイミングでリリースしたい。

**Why this priority**: 本番環境の安全性確保。dev自動デプロイ（P2）で動作確認後に、承認プロセスを経て本番反映する流れを構築する。

**Independent Test**: 手動でprodデプロイワークフローをトリガーし、承認待ち状態になること、承認後にデプロイが実行されることを確認。

**Acceptance Scenarios**:

1. **Given** dev環境へのデプロイが成功済み, **When** prodデプロイワークフローを手動トリガー, **Then** GitHub Environments の承認待ち状態になる
2. **Given** 承認待ち状態, **When** 承認者が承認, **Then** prod環境へのデプロイが実行される
3. **Given** 承認待ち状態, **When** 承認者が却下, **Then** デプロイは実行されず、却下理由が記録される
4. **Given** prodデプロイ完了, **When** デプロイ結果を確認, **Then** デプロイされたリソースとバージョン情報が記録される

---

### Edge Cases

- ワークフロー実行中にAzureの認証トークンが期限切れになった場合の再認証処理
- 並行して複数のPRがマージされた場合のデプロイの直列化（競合防止）
- Bicepモジュールの依存関係が壊れている場合（モジュール参照先が存在しない等）
- Azureサブスクリプションのクォータ上限到達時のデプロイ失敗ハンドリング
- ネットワーク障害等でデプロイが中断された場合のリトライ戦略
- `::add-mask::` のシークレット値が空の場合にマスクが効かない可能性への対処
- Azure CLIのエラーメッセージにサブスクリプションIDが含まれる場合の追加マスク処理

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: PRの作成・更新時に `infra/` 配下の変更を検知し、Bicepバリデーションワークフローを自動実行すること
- **FR-002**: バリデーションワークフローは `az bicep build` による構文チェックと `az deployment sub what-if` による変更分析を含むこと
- **FR-003**: What-If の結果をPRコメントとして自動投稿すること
- **FR-004**: mainブランチへのマージ時、`infra/` 配下に変更がある場合のみdev環境へ自動デプロイすること
- **FR-005**: prod環境へのデプロイはGitHub Environments の承認機能を使用し、手動承認を必須とすること
- **FR-006**: AzureへのアクセスにはOIDC（OpenID Connect）フェデレーションを使用し、長期クレデンシャルを保存しないこと
- **FR-007**: 各環境のデプロイは環境別パラメータファイル（`infra/parameters/{env}.bicepparam`）を使用すること
- **FR-008**: デプロイの結果（成功/失敗、作成されたリソース）をワークフローのサマリーとして出力すること
- **FR-009**: ワークフローの全出力（ログ、PRコメント、Step Summary）においてAzureの機密情報（サブスクリプションID、テナントID、クライアントID）を平文で露出させないこと。`::add-mask::` によるランタイムマスクと `sed` 等によるテキスト置換の二重防御を必須とする
- **FR-010**: リポジトリがパブリックであることを前提に、外部閲覧者がAzureリソースを特定できる情報をCI/CD成果物に含めないこと

### Key Entities

- **Workflow（ワークフロー）**: GitHub Actionsの定義ファイル。トリガー条件、ジョブ、ステップを含む
- **Environment（環境）**: GitHub Environmentsで定義。dev（自動）、prod（承認付き）の2環境
- **Azure Service Principal（サービスプリンシパル）**: OIDC フェデレーションで認証。各環境に対応するRBACロールを持つ
- **Deployment（デプロイメント）**: Azureサブスクリプションスコープのデプロイ。環境ごとに固有のデプロイ名を持つ

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: PRの作成からバリデーション結果のコメント投稿まで5分以内に完了する
- **SC-002**: Bicep構文エラーのあるPRは100%検出され、マージがブロックされる
- **SC-003**: mainマージから dev 環境へのデプロイ完了まで10分以内に完了する
- **SC-004**: prod デプロイは承認なしには実行されない（承認バイパス率 0%）
- **SC-005**: デプロイの成功率が95%以上（インフラ起因の一時障害を除く）
- **SC-006**: 長期クレデンシャル（シークレットキー、パスワード）がリポジトリに保存されない
- **SC-007**: ワークフロー実行後のPRコメント・Step Summary・ログにAzureサブスクリプションID・テナントID・クライアントIDが平文で含まれない（マスク率100%）

## Assumptions

- GitHubリポジトリはGitHub.com上にホストされており、**パブリックリポジトリ**である（外部から閲覧可能）
- Azure サブスクリプションにはContributor以上のロールでアクセス可能
- OIDC フェデレーションはAzure Entra ID（旧Azure AD）で構成可能
- GitHub Actions の無料枠（パブリックリポジトリ）またはGitHub Teamプラン以上を利用
- チームメンバーは2名以上で、prod承認者は開発者本人以外を想定

## Out of Scope

- GitHub Actions以外のCI/CDツール（Azure DevOps、Jenkins等）への対応
- アプリケーションコードのビルド・デプロイパイプライン
- テスト環境（staging）のデプロイ自動化（将来的に追加可能）
- コスト管理アラートやBudget設定の自動化
- Infraの変更と無関係なワークフロー（linting、コードレビュー自動化等）
