# Azure IaC Handson Constitution

## Core Principles

### I. Infrastructure as Code (IaC) First
すべてのAzureリソースはBicepコードで定義する。Azure Portalでの手動作成は検証目的のみ許可し、最終的には必ずコード化する。再現性・一貫性を最優先とする。

### II. モジュール化
Bicepモジュールを活用し、リソース定義を再利用可能な単位に分割する。各モジュールは単一責任の原則に従い、独立してデプロイ・テスト可能であること。

### III. 環境分離
dev / staging / prod の環境をパラメータファイルで分離する。環境固有の値はパラメータファイルに集約し、Bicepテンプレート本体には環境依存の値をハードコードしない。

### IV. セキュリティ・バイ・デフォルト
- マネージドIDを優先し、接続文字列やパスワードの直接埋め込みを禁止
- Key Vaultでシークレットを管理
- 最小権限の原則（RBAC）を徹底
- ネットワーク制限（Private Endpoint、NSG等）をデフォルトで適用

### V. 命名規則の統一
Azureリソースの命名は `{リソース種別略称}-{プロジェクト名}-{環境}-{リージョン略称}` の形式に従う。例: `rg-handson-dev-japaneast`, `app-handson-dev-jpe`

## 技術スタック

- **IaCツール**: Azure Bicep
- **デプロイ**: Azure CLI (`az deployment`)
- **CI/CD**: GitHub Actions（将来的に導入）
- **ターゲットリージョン**: Japan East（既定）
- **言語**: Bicep / PowerShell

## 開発ワークフロー

1. SpecKitで仕様を定義（spec → plan → tasks）
2. Bicepモジュールを作成
3. What-If (`az deployment group what-if`) で変更を事前確認
4. デプロイ実行
5. 検証・テスト

## Governance
この Constitution はプロジェクト全体の判断基準となる。変更には理由の文書化が必要。

**Version**: 1.0.0 | **Ratified**: 2026-03-06 | **Last Amended**: 2026-03-06
