# Azure IaC Handson with SpecKit

CAF / WAF 準拠の冗長 Web サーバーアーキテクチャを Azure Bicep + SpecKit（仕様駆動開発）で構築するハンズオンプロジェクトです。

---

## アーキテクチャ

> Azure Architecture Icons 使用 ([ガイドライン](https://learn.microsoft.com/en-us/azure/architecture/icons/))

<img src="docs/images/architecture-dev.png" alt="dev 環境アーキテクチャ" width="100%">

### リソース一覧

| リソース | CAF略称 | 用途 | セキュリティ |
|---|---|---|---|
| Application Gateway v2 | `agw` | L7 LB + WAF (OWASP 3.2 Prevention) | Public IP, Autoscale 2-10 |
| VMSS (Ubuntu 22.04 + nginx) | `vmss` | Web サーバー (Zone 1/2/3) | SSH Key, Managed ID |
| VNet (10.0.0.0/16) | `vnet` | 4サブネット分離 | NSG per subnet |
| NSG x4 | `nsg` | サブネットごとのアクセス制御 | DenyAllInbound (Web) |
| Storage Account | `st` | 診断ログ・ブート診断 | TLS 1.2, Public Deny, PE |
| Key Vault | `kv` | TLS証明書・シークレット | RBAC, SoftDelete, PE |
| Log Analytics | `log` | 統合監視・ログ集約 | 30日保持 |
| Private Endpoint x2 | `pep` | Storage Blob / Key Vault | snet-pe 経由 |

---

## WAF 5つの柱への対応

| 柱 | 対応 |
|---|---|
| **信頼性** | VMSS 可用性ゾーン分散 (Zone 1/2/3), AppGW オートスケール |
| **セキュリティ** | WAF (OWASP 3.2), NSG, Private Endpoint, RBAC, SSH Key Only, ID マスク |
| **コスト最適化** | dev: B2s x2, prod: B2ms x3, オートスケール |
| **オペレーショナルエクセレンス** | IaC (Bicep), CI/CD (GitHub Actions), Log Analytics |
| **パフォーマンス効率** | L7 LB, ゾーン分散, VMSS スケールアウト |

---

## セキュリティチェック

| チェック項目 | 結果 |
|---|---|
| WAF OWASP 3.2 Prevention モード | ✅ |
| NSG per subnet | ✅ |
| Web サブネット: AppGW からのみ許可 | ✅ |
| Storage/KV に Private Endpoint | ✅ |
| Key Vault RBAC + SoftDelete + Purge Protection | ✅ |
| Storage TLS 1.2 + Public Deny | ✅ |
| VMSS SSH Key Only (パスワード禁止) | ✅ |
| VMSS System-Assigned Managed Identity | ✅ |
| CI/CD Azure ID 二重マスク | ✅ |
| OIDC 認証 (長期クレデンシャルなし) | ✅ |

---

## CI/CD パイプライン

| ワークフロー | トリガー | 環境 | 動作 |
|---|---|---|---|
| `validate` | PR → main (`infra/**`) | - | Bicep ビルド + What-If → PRコメント |
| `deploy-dev` | main push (`infra/**`) | dev (自動) | dev 環境へ自動デプロイ |
| `deploy-prod` | 手動トリガー | prod (承認必須) | What-If → 承認 → prod デプロイ |

---

## プロジェクト構成

```
handson-speckit/
├── infra/
│   ├── main.bicep                     # メインテンプレート
│   ├── modules/
│   │   ├── network.bicep              # VNet + 4サブネット + NSG x4
│   │   ├── vmss.bicep                 # VMSS (Ubuntu + nginx, Zone 1/2/3)
│   │   ├── appgateway.bicep           # Application Gateway v2 + WAF
│   │   ├── log-analytics.bicep        # Log Analytics ワークスペース
│   │   ├── storage.bicep              # Storage Account + PE
│   │   └── keyvault.bicep             # Key Vault + PE
│   └── parameters/
│       ├── dev.bicepparam             # dev: B2s x2
│       └── prod.bicepparam            # prod: B2ms x3
├── .github/
│   ├── workflows/                     # GitHub Actions CI/CD
│   ├── agents/                        # SpecKit エージェント (日本語)
│   └── prompts/                       # SpecKit プロンプト
├── specs/
│   └── 001-web-server-foundation/     # 冗長 Web サーバー仕様
├── scripts/deploy.ps1                 # ローカルデプロイスクリプト
├── .specify/                          # SpecKit 設定
└── .gitignore
```

---

## クイックスタート

### 前提条件

- Azure CLI + Bicep
- SpecKit CLI (`uv tool install specify-cli --from git+https://github.com/github/spec-kit.git`)

### デプロイ

```powershell
# バリデーション
.\scripts\deploy.ps1 -Environment dev -Validate

# What-If
.\scripts\deploy.ps1 -Environment dev -WhatIf

# デプロイ
.\scripts\deploy.ps1 -Environment dev
```

---

## 命名規則

[CAF Resource Abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) 準拠

| リソース | 形式 | 例 |
|---|---|---|
| Resource Group | `rg-{project}-{env}-{region}` | `rg-handson-dev-japaneast` |
| VNet | `vnet-{project}-{env}-{region}` | `vnet-handson-dev-japaneast` |
| App Gateway | `agw-{project}-{env}` | `agw-handson-dev` |
| VMSS | `vmss-{project}-{env}` | `vmss-handson-dev` |
| Log Analytics | `log-{project}-{env}` | `log-handson-dev` |
| Storage | `st{project}{env}{unique}` | `sthandsondevxxxx` |
| Key Vault | `kv-{project}-{env}-{unique}` | `kv-handson-dev-xxxx` |
| Public IP | `pip-agw-{project}-{env}` | `pip-agw-handson-dev` |
