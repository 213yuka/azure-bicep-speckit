// ============================================================================
// Log Analyticsモジュール
// ============================================================================

// ============================================================================
// パラメーター定義
// ============================================================================

@description('デプロイ先のリージョン')
param location string

@description('環境名')
param environmentName string

@description('プロジェクト名')
param projectName string

@description('リソースタグ')
param tags object

// ============================================================================
// 変数定義 - CAF命名規則
// ============================================================================

var workspaceName = 'log-${projectName}-${environmentName}'

// ============================================================================
// Log Analyticsワークスペース - PerGB2018 / 30日保持
// ============================================================================

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ============================================================================
// 出力定義
// ============================================================================

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
