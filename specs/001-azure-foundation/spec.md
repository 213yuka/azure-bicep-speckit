# Feature Specification: Azure Foundation Infrastructure

**Feature Branch**: `001-azure-foundation`  
**Created**: 2026-03-06  
**Status**: Draft  
**Input**: Azure環境でIaCを試すための基盤インフラストラクチャ構築

## User Scenarios & Testing

### User Story 1 - リソースグループとネットワーク基盤の構築 (Priority: P1)

開発者として、Bicepを使ってAzure上にリソースグループ・VNet・サブネットを一括デプロイし、
アプリケーションをホストするためのネットワーク基盤を確立したい。

**Why this priority**: すべてのAzureリソースの前提となるネットワーク基盤であり、他のリソースが依存する最も基本的な要素。

**Independent Test**: `az deployment sub what-if` でネットワークリソースの作成が確認でき、デプロイ後にVNet/サブネットが存在すること。

**Acceptance Scenarios**:

1. **Given** Azureサブスクリプションが利用可能, **When** `az deployment sub create --location japaneast --template-file infra/main.bicep --parameters infra/parameters/dev.bicepparam` を実行, **Then** リソースグループ `rg-handson-dev-japaneast` が作成される
2. **Given** リソースグループが存在する, **When** デプロイが完了, **Then** VNet `vnet-handson-dev-japaneast` とサブネット `snet-default`, `snet-app` が作成される
3. **Given** VNetが存在する, **When** NSGを確認, **Then** デフォルトで全受信トラフィックを拒否するルールが適用されている

---

### User Story 2 - セキュアなストレージアカウントの構築 (Priority: P2)

開発者として、Private Endpoint経由でのみアクセス可能なストレージアカウントをデプロイし、
データを安全に保管したい。

**Why this priority**: アプリケーションのデータ永続化に必要。ネットワーク基盤の上に構築される。

**Independent Test**: ストレージアカウントがデプロイされ、パブリックアクセスが無効で、Private Endpointが構成されていること。

**Acceptance Scenarios**:

1. **Given** ネットワーク基盤がデプロイ済み, **When** ストレージモジュールがデプロイされる, **Then** ストレージアカウントが作成され、TLS 1.2が強制される
2. **Given** ストレージアカウントが存在する, **When** ネットワーク設定を確認, **Then** `allowBlobPublicAccess` が `false`、`defaultAction` が `Deny`
3. **Given** ストレージアカウント, **When** Private Endpointを確認, **Then** Blob用のPrivate Endpointが存在し、サブネットに接続されている

---

### User Story 3 - Key Vaultによるシークレット管理基盤 (Priority: P3)

開発者として、RBAC認証で保護されたKey VaultをデプロイしPrivate Endpoint経由でのみアクセス可能にしたい。

**Why this priority**: シークレット管理はセキュリティの要。ストレージアカウントのキーやアプリのシークレットを安全に管理する。

**Independent Test**: Key Vaultがデプロイされ、RBAC認証が有効で、Soft DeleteとPurge Protectionが有効であること。

**Acceptance Scenarios**:

1. **Given** ネットワーク基盤がデプロイ済み, **When** Key Vaultモジュールがデプロイされる, **Then** Key Vaultが作成されRBAC認証が有効
2. **Given** Key Vaultが存在する, **When** セキュリティ設定を確認, **Then** `enableSoftDelete: true`, `enablePurgeProtection: true`
3. **Given** Key Vault, **When** ネットワーク設定を確認, **Then** Private Endpointが構成されパブリックアクセスがDeny

---

### Edge Cases

- サブスクリプションのクォータ上限に達した場合のエラーハンドリング
- リソース名の文字数制限（ストレージ24文字、Key Vault 24文字）を超える場合
- 既存リソースがある状態での再デプロイ（冪等性の確認）
- リージョンが利用不可の場合のフォールバック

## Requirements

### Functional
- Bicepによるサブスクリプションスコープのデプロイ
- VNet + 2サブネット（default, app）のモジュール化
- ストレージアカウント + Private Endpoint のモジュール化
- Key Vault + Private Endpoint のモジュール化
- dev / prod 環境パラメータファイルの分離

### Non-Functional
- すべてのリソースにタグ（project, environment, managedBy, createdDate）を付与
- TLS 1.2 以上を強制
- パブリックアクセスはデフォルトで拒否
- デプロイは冪等であること（再実行しても問題なし）

## Out of Scope
- アプリケーションコードのデプロイ
- CI/CD パイプラインの構築（次のスペックで対応）
- DNS Private Zone の構成
- 監視・アラートの設定
