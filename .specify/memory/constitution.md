# Azure IaC Handson Constitution

## Core Principles

### I. Infrastructure as Code (IaC) First
すべてのAzureリソースはBicepコードで定義する。Azure Portalでの手動作成は検証目的のみ許可し、最終的には必ずコード化する。再現性・一貫性を最優先とする。

### II. CAF / WAF 準拠
Azure Cloud Adoption Framework (CAF) の命名規則・リソース構成と Azure Well-Architected Framework (WAF) の5つの柱（信頼性、セキュリティ、コスト最適化、オペレーショナルエクセレンス、パフォーマンス効率）に準拠する。

### III. モジュール化
Bicepモジュールを活用し、リソース定義を再利用可能な単位に分割する。各モジュールは単一責任の原則に従い、独立してデプロイ・テスト可能であること。

### IV. 環境分離
dev / staging / prod の環境をパラメータファイルで分離する。環境固有の値はパラメータファイルに集約し、Bicepテンプレート本体には環境依存の値をハードコードしない。

### V. セキュリティ・バイ・デフォルト
- マネージドIDを優先し、接続文字列やパスワードの直接埋め込みを禁止
- Key Vaultでシークレットを管理
- 最小権限の原則（RBAC）を徹底
- ネットワーク制限（Private Endpoint、NSG、WAF）をデフォルトで適用
- Azure の機密情報（サブスクリプションID、テナントID、クライアントID）を公開可能な場所に平文で露出させないこと
- CI/CD ワークフローでは `::add-mask::` + `sed` による二重防御を必須とする
- リポジトリがパブリックであることを前提に、すべてのワークフロー出力を設計すること

### VI. 冗長性と高可用性
- Web サーバーは VMSS + 可用性ゾーン分散で冗長化
- Application Gateway (WAF v2) によるL7負荷分散とWeb攻撃防御
- 単一障害点（SPOF）を排除する設計

### VII. 命名規則の統一
CAF 推奨略称に従う。形式: `{略称}-{プロジェクト名}-{環境}-{リージョン}`

## 技術スタック

- **IaCツール**: Azure Bicep
- **デプロイ**: Azure CLI (`az deployment`)
- **CI/CD**: GitHub Actions (OIDC認証)
- **ターゲットリージョン**: Japan East（既定）
- **言語**: Bicep / PowerShell
- **Web サーバー**: VMSS (Ubuntu 22.04 LTS + nginx)
- **L7 LB/WAF**: Application Gateway v2 (WAF_v2, OWASP 3.2)
- **監視**: Log Analytics + Application Insights

## 開発ワークフロー

1. SpecKitで仕様を定義（spec → plan → tasks）
2. Bicepモジュールを作成
3. What-If (`az deployment sub what-if`) で変更を事前確認
4. PR でバリデーション + What-If（GitHub Actions）
5. main マージで dev 自動デプロイ
6. 手動承認で prod デプロイ

## Governance
この Constitution はプロジェクト全体の判断基準となる。変更には理由の文書化が必要。

**Version**: 2.0.0 | **Ratified**: 2026-03-06 | **Last Amended**: 2026-03-06
