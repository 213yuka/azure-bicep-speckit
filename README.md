# Azure IaC Handson with SpecKit

SpecKit（仕様駆動開発）を活用した Azure Infrastructure as Code (Bicep) のハンズオンプロジェクトです。

## プロジェクト構成

```
handson-speckit/
├── infra/                          # Bicep IaC ファイル
│   ├── main.bicep                  # メインテンプレート（サブスクリプションスコープ）
│   ├── modules/                    # Bicep モジュール
│   │   ├── network.bicep           # VNet / サブネット / NSG
│   │   ├── storage.bicep           # ストレージアカウント + Private Endpoint
│   │   └── keyvault.bicep          # Key Vault + Private Endpoint
│   └── parameters/                 # 環境別パラメータ
│       ├── dev.bicepparam          # 開発環境
│       └── prod.bicepparam         # 本番環境
├── scripts/                        # デプロイスクリプト
│   └── deploy.ps1
├── specs/                          # SpecKit 仕様
│   └── 001-azure-foundation/
│       └── spec.md
├── .specify/                       # SpecKit 設定・テンプレート
├── .github/                        # GitHub Copilot エージェント・プロンプト
└── .gitignore
```

## 前提条件

- Azure CLI (`az`)
- Azure Bicep (Azure CLI に同梱)
- SpecKit CLI (`specify`)
- Python 3.12+
- uv (Python パッケージマネージャ)

## クイックスタート

### 1. Bicep テンプレートの検証

```powershell
# バリデーション
.\scripts\deploy.ps1 -Environment dev -Validate

# What-If 分析（変更の事前確認）
.\scripts\deploy.ps1 -Environment dev -WhatIf
```

### 2. デプロイ

```powershell
# dev環境にデプロイ
.\scripts\deploy.ps1 -Environment dev
```

### 3. SpecKit ワークフロー

```powershell
# 仕様の作成・確認
# VS Code でスラッシュコマンドを使用:
# /speckit.specify  - 仕様作成
# /speckit.plan     - 実装計画
# /speckit.tasks    - タスク生成
# /speckit.implement - 実装開始
```

## 命名規則

| リソース種別 | 形式 | 例 |
|---|---|---|
| Resource Group | `rg-{project}-{env}-{region}` | `rg-handson-dev-japaneast` |
| VNet | `vnet-{project}-{env}-{region}` | `vnet-handson-dev-japaneast` |
| NSG | `nsg-{project}-{env}-{region}` | `nsg-handson-dev-japaneast` |
| Storage | `st{project}{env}{unique}` | `sthandsondevxxxx` |
| Key Vault | `kv-{project}-{env}-{unique}` | `kv-handson-dev-xxxx` |
