# Feature Specification: 冗長 Web サーバー基盤 (CAF/WAF 準拠)

**Feature Branch**: `001-web-server-foundation`
**Created**: 2026-03-06
**Status**: Approved
**Input**: Azure 環境で CAF/WAF に準拠した冗長性のある Web サーバーを IaC (Bicep) で構築

## User Scenarios & Testing

### User Story 1 - 冗長 Web サーバーのデプロイ (Priority: P1)

インフラ担当者として、Bicep を使って可用性ゾーンに分散した Web サーバー群（VMSS + nginx）を
Application Gateway (WAF) 経由で公開し、単一障害点のない構成をデプロイしたい。

**Why this priority**: Web サービスの基盤であり、すべての上位機能の前提。

**Independent Test**: `az deployment sub create` 実行後、Application Gateway の公開 IP に HTTP アクセスして nginx のデフォルトページが表示される。

**Acceptance Scenarios**:

1. **Given** Azure サブスクリプションが利用可能, **When** dev パラメータでデプロイ実行, **Then** リソースグループ内に VNet、VMSS、AppGW、KV、Storage、Log Analytics が作成される
2. **Given** VMSS がデプロイ済み, **When** 可用性ゾーンを確認, **Then** インスタンスがゾーン 1/2/3 に分散されている
3. **Given** Application Gateway がデプロイ済み, **When** 公開 IP に HTTP リクエスト, **Then** nginx のレスポンスが返る
4. **Given** WAF が有効, **When** SQLi パターンのリクエストを送信, **Then** WAF がリクエストをブロックする

---

### User Story 2 - ネットワークセキュリティの確保 (Priority: P2)

セキュリティ担当者として、各サブネットが NSG で適切に保護され、PaaS サービスへのアクセスが
Private Endpoint 経由のみになっていることを確認したい。

**Why this priority**: セキュリティは機能と同等に重要。パブリック露出を最小化する。

**Independent Test**: NSG ルール一覧と PE の接続状態を確認し、パブリックアクセスが拒否されていること。

**Acceptance Scenarios**:

1. **Given** VNet がデプロイ済み, **When** NSG を確認, **Then** Web サブネットは AppGW サブネットからの HTTP/HTTPS のみ許可
2. **Given** Storage Account, **When** パブリックアクセスを試行, **Then** アクセスが拒否される（PE 経由のみ）
3. **Given** Key Vault, **When** パブリックアクセスを試行, **Then** アクセスが拒否される（PE 経由のみ）
4. **Given** AppGW サブネット, **When** NSG を確認, **Then** HTTP/HTTPS + GatewayManager のみ許可

---

### User Story 3 - 監視と診断の構成 (Priority: P3)

運用担当者として、Log Analytics に全リソースの診断ログが集約され、
障害時にトラブルシューティングできる状態にしたい。

**Why this priority**: WAF のオペレーショナルエクセレンスの柱。可観測性なしに運用は不可能。

**Independent Test**: Log Analytics ワークスペースにクエリして AppGW と VMSS のログが取得できる。

**Acceptance Scenarios**:

1. **Given** Log Analytics がデプロイ済み, **When** AppGW の診断設定を確認, **Then** ログが Log Analytics に送信されている
2. **Given** VMSS がデプロイ済み, **When** Azure Monitor Agent を確認, **Then** エージェントがインストールされている

---

### Edge Cases

- VMSS スケールイン時にアクティブ接続が切断されるリスク
- AppGW ヘルスプローブ失敗時の全インスタンスダウン検知
- Private DNS Zone の名前解決遅延
- WAF の誤検知によるレジットリクエストのブロック
- SSH キーのローテーション手順

## Requirements

### Functional Requirements

- **FR-001**: VMSS を可用性ゾーン 1/2/3 に分散してデプロイすること
- **FR-002**: Application Gateway v2 (WAF_v2 SKU) で L7 負荷分散を行うこと
- **FR-003**: WAF ポリシーは OWASP 3.2 ルールセット、Prevention モードとすること
- **FR-004**: 4 つのサブネット（AppGW、Web、PE、Management）でネットワークをセグメント化すること
- **FR-005**: Key Vault と Storage へのアクセスは Private Endpoint 経由のみとすること
- **FR-006**: VMSS に nginx を自動インストールし、即座に Web サービスを提供すること
- **FR-007**: Log Analytics ワークスペースに全リソースの診断ログを集約すること
- **FR-008**: VMSS は SSH キー認証のみ対応し、パスワード認証を禁止すること
- **FR-009**: ワークフロー出力で Azure 機密情報を平文で露出させないこと（二重マスク必須）

### Key Entities

- **VMSS**: Web サーバー群。Ubuntu 22.04 LTS + nginx。可用性ゾーン分散
- **Application Gateway**: L7 LB + WAF。公開 IP を持つ唯一のリソース
- **VNet**: 10.0.0.0/16。4 サブネットで用途別セグメンテーション
- **NSG**: サブネットごとのネットワークアクセス制御
- **Key Vault**: TLS 証明書・シークレット管理。RBAC + PE
- **Storage Account**: 診断ログ・ブート診断。PE 経由
- **Log Analytics**: 統合監視・ログ集約

## Success Criteria

### Measurable Outcomes

- **SC-001**: AppGW 公開 IP への HTTP リクエストが 3 秒以内にレスポンスを返す
- **SC-002**: 1 つの可用性ゾーンが停止しても Web サービスが継続する
- **SC-003**: SQLi / XSS パターンのリクエストが WAF でブロックされる
- **SC-004**: パブリックアクセス経由で KV/Storage にアクセスできない
- **SC-005**: AppGW のアクセスログが Log Analytics で検索可能
- **SC-006**: Bicep デプロイが冪等であること（再実行してエラーなし）
- **SC-007**: Azure 機密情報が PR コメント・ログ・Step Summary に平文で含まれない

## Assumptions

- リポジトリは **パブリック**（GitHub.com）
- Azure サブスクリプションに Contributor ロール
- SSH 公開鍵はデプロイ前に準備
- 単一リージョン（Japan East）構成
- TLS 証明書は将来的に Key Vault 統合（現時点は HTTP のみ）

## Out of Scope

- マルチリージョン構成 / Traffic Manager
- Azure Firewall（ハブスポーク構成）
- Azure Bastion（管理アクセス）
- アプリケーションコードのデプロイ（nginx デフォルト）
- TLS 証明書の自動取得（Let's Encrypt 等）
- データベース層（SQL/Cosmos DB）
